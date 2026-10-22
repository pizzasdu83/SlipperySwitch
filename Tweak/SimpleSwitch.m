//
//  SimpleSwitch.m
//  Mode "Simple" : piste activée / désactivée et bouton, chacun avec sa couleur
//  (unie ou dégradé) configurable dans les réglages
//
//  Clés de préférences (couleurs au format "#RRGGBB") :
//    onColor1   onColor2   onGradient   onGradientType   onGradientAngle     → piste activée
//    offColor1  offColor2  offGradient  offGradientType  offGradientAngle    → piste désactivée
//    knobColor1 knobColor2 knobGradient knobGradientType knobGradientAngle   → bouton
//  Type de dégradé : "linear" (défaut) ou "radial" (couleur 1 au centre, couleur 2 sur les bords).
//  Angle (dégradé linéaire) en degrés : 0 = de gauche à droite, 90 = de haut en bas,
//  180 = de droite à gauche, 270 = de bas en haut.
//

#import "SimpleSwitch.h"

// MARK: Couleurs

@interface DNSFill : NSObject
@property(nonatomic, strong) UIColor *color1;
@property(nonatomic, strong) UIColor *color2;
@property(nonatomic, assign) BOOL gradient;
@property(nonatomic, assign) BOOL radial;
@property(nonatomic, assign) CGFloat angle;
@end

@implementation DNSFill
@end

static DNSFill *sOnFill = nil;
static DNSFill *sOffFill = nil;
static DNSFill *sKnobFill = nil;

/// "#RRGGBB" (ou "RRGGBB") → UIColor ; retombe sur `fallback` si la valeur est invalide
static UIColor *DNSColorFromHex(id value, NSString *fallback) {
    NSString *hex = [value isKindOfClass:[NSString class]] ? value : fallback;

    for (int attempt = 0; attempt < 2; attempt++) {
        NSString *s = [hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([s hasPrefix:@"#"]) {
            s = [s substringFromIndex:1];
        }

        char *end = NULL;
        unsigned long rgb = strtoul(s.UTF8String, &end, 16);
        if (s.length == 6 && end && *end == '\0') {
            return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                                   green:((rgb >> 8) & 0xFF) / 255.0
                                    blue:(rgb & 0xFF) / 255.0
                                   alpha:1];
        }

        hex = fallback;
    }

    return [UIColor grayColor];
}

static DNSFill *DNSMakeFill(NSDictionary *prefs, NSString *prefix, NSString *default1, NSString *default2,
                            CGFloat defaultAngle) {
    DNSFill *fill = [[DNSFill alloc] init];
    fill.color1 = DNSColorFromHex([prefs objectForKey:[prefix stringByAppendingString:@"Color1"]], default1);
    fill.color2 = DNSColorFromHex([prefs objectForKey:[prefix stringByAppendingString:@"Color2"]], default2);

    id gradient = [prefs objectForKey:[prefix stringByAppendingString:@"Gradient"]];
    fill.gradient = [gradient respondsToSelector:@selector(boolValue)] && [gradient boolValue];

    id type = [prefs objectForKey:[prefix stringByAppendingString:@"GradientType"]];
    fill.radial = [type isKindOfClass:[NSString class]] && [type isEqualToString:@"radial"];

    id angle = [prefs objectForKey:[prefix stringByAppendingString:@"GradientAngle"]];
    fill.angle = [angle respondsToSelector:@selector(doubleValue)] ? [angle doubleValue] : defaultAngle;
    return fill;
}

// MARK: Vue avec fond uni ou dégradé

@interface DNSGradientView : UIView
@property(nonatomic, readonly) CAGradientLayer *gradientLayer;
- (void)applyFill:(DNSFill *)fill;
@end

@implementation DNSGradientView {
    DNSFill *_fill;
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (CAGradientLayer *)gradientLayer {
    return (CAGradientLayer *)self.layer;
}

- (void)applyFill:(DNSFill *)fill {
    _fill = fill;
    [self refreshGradient];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self refreshGradient];
}

- (void)refreshGradient {
    DNSFill *fill = _fill;
    if (!fill) {
        return;
    }

    CAGradientLayer *layer = self.gradientLayer;

    // couleur unie = dégradé avec deux fois la même couleur
    UIColor *second = fill.gradient ? fill.color2 : fill.color1;
    layer.colors = @[ (__bridge id)fill.color1.CGColor, (__bridge id)second.CGColor ];

    if (fill.gradient && fill.radial) {
        // radial : couleur 1 au centre, couleur 2 sur les bords
        layer.type = kCAGradientLayerRadial;
        layer.startPoint = CGPointMake(0.5, 0.5);
        layer.endPoint = CGPointMake(1, 1);
        return;
    }

    layer.type = kCAGradientLayerAxial;

    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    if (!fill.gradient || w < 1 || h < 1) {
        layer.startPoint = CGPointMake(0, 0.5);
        layer.endPoint = CGPointMake(1, 0.5);
        return;
    }

    // dégradé linéaire d'angle donné : la ligne du dégradé passe par le centre et sa longueur
    // est calculée pour que les coins reçoivent exactement la première / dernière couleur
    CGFloat radians = fill.angle * M_PI / 180.0;
    CGFloat dx = cos(radians);
    CGFloat dy = sin(radians);
    CGFloat length = fabs(w * dx) + fabs(h * dy);

    CGFloat cx = w / 2;
    CGFloat cy = h / 2;
    layer.startPoint = CGPointMake((cx - dx * length / 2) / w, (cy - dy * length / 2) / h);
    layer.endPoint = CGPointMake((cx + dx * length / 2) / w, (cy + dy * length / 2) / h);
}

@end

// MARK: SimpleSwitch

@interface SimpleSwitch ()

@property(nonatomic, strong) DNSGradientView *offView;
@property(nonatomic, strong) DNSGradientView *onView;
@property(nonatomic, strong) UIView *knobContainer;
@property(nonatomic, strong) DNSGradientView *knobView;

@property(nonatomic, assign, getter=isMoved) BOOL moved;

/// Empêche le tap de interférer avec le drag
@property(nonatomic, assign, getter=isDragging) BOOL dragging;

@property(nonatomic, assign, getter=isOnBeforeDrag) BOOL onBeforeDrag;

@end

@implementation SimpleSwitch {
    BOOL _shouldSkipChangeAction;
    BOOL _shouldAnimate;
    BOOL _shouldAnimateImportant;
}

@synthesize changeAction = _changeAction;
@synthesize on = _on;

+ (void)applyPrefs:(NSDictionary *)prefs {
    sOnFill = DNSMakeFill(prefs, @"on", @"#34C759", @"#00C7BE", 0);
    sOffFill = DNSMakeFill(prefs, @"off", @"#E9E9EA", @"#C7C7CC", 0);
    sKnobFill = DNSMakeFill(prefs, @"knob", @"#FFFFFF", @"#E5E5EA", 90);
}

// MARK: Géométrie

- (CGFloat)knobPadding {
    return self.bounds.size.height * 0.09;
}

- (CGFloat)knobDiameter {
    return self.bounds.size.height - [self knobPadding] * 2;
}

- (CGRect)knobFrameForOn:(BOOL)on {
    CGFloat pad = [self knobPadding];
    CGFloat d = [self knobDiameter];
    CGFloat x = on ? self.bounds.size.width - pad - d : pad;
    return CGRectMake(x, pad, d, d);
}

// MARK: Initializers

- (void)commonInit {
    if (!sOnFill || !sOffFill || !sKnobFill) {
        [SimpleSwitch applyPrefs:nil];
    }

    _shouldAnimateImportant = YES;

    self.moved = NO;
    self.dragging = NO;

    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = self.bounds.size.height / 2;

    // piste désactivée (toujours dessous) et piste activée (en fondu par-dessus)
    self.offView = [[DNSGradientView alloc] initWithFrame:self.bounds];
    self.offView.userInteractionEnabled = NO;
    [self.offView applyFill:sOffFill];
    [self addSubview:self.offView];

    self.onView = [[DNSGradientView alloc] initWithFrame:self.bounds];
    self.onView.userInteractionEnabled = NO;
    self.onView.alpha = 0;
    [self.onView applyFill:sOnFill];
    [self addSubview:self.onView];

    // bouton : un conteneur (pour l'ombre) qui porte une vue ronde avec la couleur / le dégradé
    CGFloat d = [self knobDiameter];

    self.knobContainer = [[UIView alloc] initWithFrame:[self knobFrameForOn:NO]];
    self.knobContainer.userInteractionEnabled = NO;
    self.knobContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.knobContainer.layer.shadowOpacity = 0.25;
    self.knobContainer.layer.shadowRadius = 1.5;
    self.knobContainer.layer.shadowOffset = CGSizeMake(0, 1);
    self.knobContainer.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, d, d)].CGPath;

    self.knobView = [[DNSGradientView alloc] initWithFrame:CGRectMake(0, 0, d, d)];
    self.knobView.userInteractionEnabled = NO;
    self.knobView.layer.cornerRadius = d / 2;
    self.knobView.layer.masksToBounds = YES;
    [self.knobView applyFill:sKnobFill];

    [self.knobContainer addSubview:self.knobView];
    [self addSubview:self.knobContainer];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(tapGestureOccurred:)];
    [self addGestureRecognizer:tapGesture];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(panGestureOccurred:)];
    [self addGestureRecognizer:panGesture];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self commonInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self commonInit];
    return self;
}

// MARK: Gestes

- (void)panGestureOccurred:(UIPanGestureRecognizer *)sender {
    CGPoint touchLocation = [sender locationInView:self];

    if (sender.state == UIGestureRecognizerStateBegan) {
        self.onBeforeDrag = self.isOn;
        self.dragging = YES;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        self.moved = YES;

        if (touchLocation.x > self.frame.size.width / 2 && !self.isOn) {
            self.on = YES;
        } else if (touchLocation.x < self.frame.size.width / 2 && self.isOn) {
            self.on = NO;
        }
    } else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled ||
               sender.state == UIGestureRecognizerStateFailed) {

        self.dragging = NO;
        self.moved = NO;

        if (self.isOn != self.isOnBeforeDrag && self.changeAction) {
            self.changeAction(self.isOn, YES);
        }
    }
}

- (void)tapGestureOccurred:(UITapGestureRecognizer *)sender {
    if (self.isDragging) {
        return;
    }

    self.dragging = YES;
    self.on = !self.isOn;
    self.dragging = NO;
}

// MARK: État

- (void)setOn:(BOOL)on {
    if (_on == on) {
        return;
    }

    _on = on;

    [self _setOn:on];
}

- (void)_setOn:(BOOL)on {
    // call the action closure
    if (self.changeAction && !_shouldSkipChangeAction) {
        self.changeAction(on, !self.isMoved);
    }

    BOOL shouldAnimate = (_shouldAnimate || self.isDragging) && _shouldAnimateImportant;
    CGRect knobTarget = [self knobFrameForOn:on];
    CGFloat onAlpha = on ? 1 : 0;

    if (shouldAnimate) {
        [UIView animateWithDuration:0.35
                              delay:0
             usingSpringWithDamping:0.8
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.knobContainer.frame = knobTarget;
                             self.onView.alpha = onAlpha;
                         }
                         completion:nil];
    } else {
        self.knobContainer.frame = knobTarget;
        self.onView.alpha = onAlpha;
    }
}

- (void)blockChangeActionAnimated:(BOOL)animated {
    _shouldSkipChangeAction = YES;
    _shouldAnimate = animated && _shouldAnimateImportant;
}

- (void)unblockChangeAction {
    _shouldSkipChangeAction = NO;
}

- (void)dns_disableAnimations {
    _shouldAnimateImportant = NO;
}

@end
