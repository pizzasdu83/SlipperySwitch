//
//  JoyConSwitch.m
//  Mode "Nintendo Switch" : le Joy-Con droit vient se clipser sur le gauche
//
//  Les formes viennent des SVG gauche.svg / droite.svg (logo Switch),
//  converties en UIBezierPath normalisés (0..1) pour être redimensionnés
//  à la taille réelle du UISwitch.
//

#import "JoyConSwitch.h"

// MARK: Réglages visuels (modifiables)

/// Fond de la piste (blanc par défaut)
static UIColor *JCTrackColor(void) {
    return [UIColor whiteColor];
}

/// Fine bordure pour que la piste blanche reste visible sur un fond clair
static UIColor *JCBorderColor(void) {
    return [UIColor colorWithWhite:0.82 alpha:1];
}

/// Rouge Nintendo (#e60012)
static UIColor *JCJoyConColor(void) {
    return [UIColor colorWithRed:0.902 green:0.0 blue:0.071 alpha:1];
}

// MARK: Proportions du logo (déduites des SVG)

/// largeur / hauteur de chaque Joy-Con
static const CGFloat kJCLeftAspect = 0.48439;
static const CGFloat kJCRightAspect = 0.41617;

/// écart entre les deux Joy-Con une fois "clipsés", en fraction de leur hauteur
static const CGFloat kJCGapRatio = 0.09941;

// MARK: Formes

static UIBezierPath *JCLeftPath(void) {
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(0.44202, 0.00316)];
    [p addCurveToPoint:CGPointMake(0.01872, 0.19163) controlPoint1:CGPointMake(0.23636, 0.02097) controlPoint2:CGPointMake(0.07088, 0.09471)];
    [p addCurveToPoint:CGPointMake(0.00076, 0.51867) controlPoint1:CGPointMake(-0.00009, 0.22664) controlPoint2:CGPointMake(-0.00138, 0.24714)];
    [p addCurveToPoint:CGPointMake(0.01102, 0.79309) controlPoint1:CGPointMake(0.00205, 0.76803) controlPoint2:CGPointMake(0.00247, 0.77383)];
    [p addCurveToPoint:CGPointMake(0.42705, 0.99523) controlPoint1:CGPointMake(0.05849, 0.89686) controlPoint2:CGPointMake(0.21070, 0.97080)];
    [p addCurveToPoint:CGPointMake(0.72251, 0.99958) controlPoint1:CGPointMake(0.45527, 0.99834) controlPoint2:CGPointMake(0.49119, 0.99896)];
    [p addCurveToPoint:CGPointMake(0.99316, 0.99710) controlPoint1:CGPointMake(0.96195, 1.00041) controlPoint2:CGPointMake(0.98675, 1.00021)];
    [p addCurveToPoint:CGPointMake(1.00000, 0.50086) controlPoint1:CGPointMake(0.99957, 0.99399) controlPoint2:CGPointMake(1.00000, 0.95402)];
    [p addCurveToPoint:CGPointMake(0.99572, 0.00378) controlPoint1:CGPointMake(1.00000, 0.16492) controlPoint2:CGPointMake(0.99872, 0.00668)];
    [p addCurveToPoint:CGPointMake(0.73362, 0.00005) controlPoint1:CGPointMake(0.99145, 0.00005) controlPoint2:CGPointMake(0.98418, -0.00015)];
    [p addCurveToPoint:CGPointMake(0.44202, 0.00316) controlPoint1:CGPointMake(0.53010, 0.00026) controlPoint2:CGPointMake(0.46895, 0.00088)];
    [p closePath];
    [p moveToPoint:CGPointMake(0.82897, 0.50023)];
    [p addLineToPoint:CGPointMake(0.82897, 0.91985)];
    [p addLineToPoint:CGPointMake(0.65495, 0.91881)];
    [p addCurveToPoint:CGPointMake(0.44544, 0.91363) controlPoint1:CGPointMake(0.49461, 0.91798) controlPoint2:CGPointMake(0.47751, 0.91757)];
    [p addCurveToPoint:CGPointMake(0.17692, 0.77818) controlPoint1:CGPointMake(0.30776, 0.89644) controlPoint2:CGPointMake(0.20557, 0.84508)];
    [p addCurveToPoint:CGPointMake(0.17650, 0.22146) controlPoint1:CGPointMake(0.16752, 0.75726) controlPoint2:CGPointMake(0.16752, 0.24196)];
    [p addCurveToPoint:CGPointMake(0.39798, 0.09326) controlPoint1:CGPointMake(0.20215, 0.16326) controlPoint2:CGPointMake(0.28553, 0.11500)];
    [p addCurveToPoint:CGPointMake(0.66350, 0.08083) controlPoint1:CGPointMake(0.45442, 0.08228) controlPoint2:CGPointMake(0.48050, 0.08104)];
    [p addLineToPoint:CGPointMake(0.82897, 0.08062)];
    [p addLineToPoint:CGPointMake(0.82897, 0.50023)];
    [p closePath];
    [p moveToPoint:CGPointMake(0.47879, 0.20717)];
    [p addCurveToPoint:CGPointMake(0.38900, 0.22892) controlPoint1:CGPointMake(0.45185, 0.20965) controlPoint2:CGPointMake(0.41080, 0.21960)];
    [p addCurveToPoint:CGPointMake(0.32529, 0.30596) controlPoint1:CGPointMake(0.34410, 0.24776) controlPoint2:CGPointMake(0.32187, 0.27448)];
    [p addCurveToPoint:CGPointMake(0.34282, 0.33993) controlPoint1:CGPointMake(0.32700, 0.32232) controlPoint2:CGPointMake(0.32914, 0.32667)];
    [p addCurveToPoint:CGPointMake(0.43475, 0.38466) controlPoint1:CGPointMake(0.36292, 0.36002) controlPoint2:CGPointMake(0.39327, 0.37472)];
    [p addCurveToPoint:CGPointMake(0.50786, 0.39295) controlPoint1:CGPointMake(0.46340, 0.39150) controlPoint2:CGPointMake(0.47067, 0.39233)];
    [p addCurveToPoint:CGPointMake(0.57628, 0.38922) controlPoint1:CGPointMake(0.54164, 0.39357) controlPoint2:CGPointMake(0.55361, 0.39295)];
    [p addCurveToPoint:CGPointMake(0.70925, 0.28566) controlPoint1:CGPointMake(0.66906, 0.37410) controlPoint2:CGPointMake(0.72507, 0.33040)];
    [p addCurveToPoint:CGPointMake(0.47879, 0.20717) controlPoint1:CGPointMake(0.69087, 0.23244) controlPoint2:CGPointMake(0.58654, 0.19681)];
    [p closePath];
    return p;
}

static UIBezierPath *JCRightPath(void) {
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(0.00348, 0.00145)];
    [p addCurveToPoint:CGPointMake(0.00000, 0.50023) controlPoint1:CGPointMake(0.00149, 0.00207) controlPoint2:CGPointMake(0.00000, 0.22651)];
    [p addCurveToPoint:CGPointMake(0.00796, 0.99880) controlPoint1:CGPointMake(0.00000, 0.95180) controlPoint2:CGPointMake(0.00050, 0.99756)];
    [p addCurveToPoint:CGPointMake(0.45522, 0.99797) controlPoint1:CGPointMake(0.02139, 1.00087) controlPoint2:CGPointMake(0.40746, 1.00004)];
    [p addCurveToPoint:CGPointMake(0.93234, 0.86132) controlPoint1:CGPointMake(0.65721, 0.98845) controlPoint2:CGPointMake(0.83532, 0.93731)];
    [p addCurveToPoint:CGPointMake(0.96965, 0.82509) controlPoint1:CGPointMake(0.94477, 0.85159) controlPoint2:CGPointMake(0.96119, 0.83523)];
    [p addCurveToPoint:CGPointMake(1.00000, 0.49899) controlPoint1:CGPointMake(1.00099, 0.78616) controlPoint2:CGPointMake(1.00000, 0.79651)];
    [p addCurveToPoint:CGPointMake(0.99204, 0.21098) controlPoint1:CGPointMake(1.00000, 0.26150) controlPoint2:CGPointMake(0.99900, 0.22610)];
    [p addCurveToPoint:CGPointMake(0.48557, 0.00311) controlPoint1:CGPointMake(0.94278, 0.10311) controlPoint2:CGPointMake(0.74527, 0.02174)];
    [p addCurveToPoint:CGPointMake(0.22388, 0.00000) controlPoint1:CGPointMake(0.45074, 0.00062) controlPoint2:CGPointMake(0.39701, 0.00000)];
    [p addCurveToPoint:CGPointMake(0.00348, 0.00145) controlPoint1:CGPointMake(0.10448, 0.00000) controlPoint2:CGPointMake(0.00498, 0.00062)];
    [p closePath];
    [p moveToPoint:CGPointMake(0.53482, 0.45240)];
    [p addCurveToPoint:CGPointMake(0.70199, 0.51700) controlPoint1:CGPointMake(0.61244, 0.46089) controlPoint2:CGPointMake(0.67612, 0.48553)];
    [p addCurveToPoint:CGPointMake(0.70149, 0.58284) controlPoint1:CGPointMake(0.71841, 0.53646) controlPoint2:CGPointMake(0.71791, 0.56503)];
    [p addCurveToPoint:CGPointMake(0.53482, 0.64703) controlPoint1:CGPointMake(0.67114, 0.61555) controlPoint2:CGPointMake(0.61144, 0.63854)];
    [p addCurveToPoint:CGPointMake(0.24179, 0.57787) controlPoint1:CGPointMake(0.41045, 0.66048) controlPoint2:CGPointMake(0.27811, 0.62922)];
    [p addCurveToPoint:CGPointMake(0.24378, 0.51948) controlPoint1:CGPointMake(0.23085, 0.56214) controlPoint2:CGPointMake(0.23134, 0.53563)];
    [p addCurveToPoint:CGPointMake(0.53482, 0.45240) controlPoint1:CGPointMake(0.28109, 0.46876) controlPoint2:CGPointMake(0.41045, 0.43894)];
    [p closePath];
    return p;
}

// MARK: Vue portant une forme

@interface JCShapeView : UIView
@property(nonatomic, readonly) CAShapeLayer *shapeLayer;
@end

@implementation JCShapeView

+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (CAShapeLayer *)shapeLayer {
    return (CAShapeLayer *)self.layer;
}

@end

// MARK: JoyConSwitch

@interface JoyConSwitch ()

@property(nonatomic, strong) JCShapeView *leftJoyCon;
@property(nonatomic, strong) JCShapeView *rightJoyCon;

@property(nonatomic, assign, getter=isMoved) BOOL moved;

/// Empêche le tap de interférer avec le drag
@property(nonatomic, assign, getter=isDragging) BOOL dragging;

@property(nonatomic, assign, getter=isOnBeforeDrag) BOOL onBeforeDrag;

@end

@implementation JoyConSwitch {
    BOOL _shouldSkipChangeAction;
    BOOL _shouldAnimate;
    BOOL _shouldAnimateImportant;
}

@synthesize changeAction = _changeAction;
@synthesize on = _on;

// MARK: Géométrie

/// Marge verticale entre la piste et les Joy-Con
- (CGFloat)jcMargin {
    return self.bounds.size.height * 0.12;
}

/// Marge horizontale (on tient compte des extrémités arrondies de la piste)
- (CGFloat)jcInset {
    return self.bounds.size.height * 0.20;
}

/// Hauteur des Joy-Con
- (CGFloat)jcHeight {
    return self.bounds.size.height - [self jcMargin] * 2;
}

/// Le Joy-Con gauche ne bouge jamais
- (CGRect)leftFrame {
    CGFloat jh = [self jcHeight];
    return CGRectMake([self jcInset], [self jcMargin], jh * kJCLeftAspect, jh);
}

/// Le Joy-Con droit : collé à droite quand OFF, collé au gauche quand ON
- (CGRect)rightFrameForOn:(BOOL)on {
    CGFloat jh = [self jcHeight];
    CGFloat rw = jh * kJCRightAspect;

    CGFloat xOff = self.bounds.size.width - [self jcInset] - rw;
    CGFloat xOn = CGRectGetMaxX([self leftFrame]) + jh * kJCGapRatio;

    return CGRectMake(on ? MIN(xOn, xOff) : xOff, [self jcMargin], rw, jh);
}

// MARK: Initializers

- (JCShapeView *)makeJoyConWithFrame:(CGRect)frame path:(UIBezierPath *)path {
    // le chemin est normalisé (0..1) : on l'adapte à la taille réelle
    [path applyTransform:CGAffineTransformMakeScale(frame.size.width, frame.size.height)];

    JCShapeView *v = [[JCShapeView alloc] initWithFrame:frame];
    v.backgroundColor = [UIColor clearColor];
    v.userInteractionEnabled = NO;
    v.shapeLayer.path = path.CGPath;
    v.shapeLayer.fillRule = kCAFillRuleEvenOdd;
    v.shapeLayer.fillColor = JCJoyConColor().CGColor;
    return v;
}

- (void)commonInit {
    _shouldAnimateImportant = YES;

    self.moved = NO;
    self.dragging = NO;

    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = self.bounds.size.height / 2;
    self.layer.borderWidth = 1;
    self.layer.borderColor = JCBorderColor().CGColor;
    self.backgroundColor = JCTrackColor();

    self.leftJoyCon = [self makeJoyConWithFrame:[self leftFrame] path:JCLeftPath()];
    self.rightJoyCon = [self makeJoyConWithFrame:[self rightFrameForOn:NO] path:JCRightPath()];

    [self addSubview:self.leftJoyCon];
    [self addSubview:self.rightJoyCon];

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
    CGRect target = [self rightFrameForOn:on];

    if (shouldAnimate) {
        // petit effet de "clic" : le Joy-Con rebondit légèrement en arrivant
        [UIView animateWithDuration:0.45
                              delay:0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.6
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.rightJoyCon.frame = target;
                         }
                         completion:nil];
    } else {
        self.rightJoyCon.frame = target;
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
