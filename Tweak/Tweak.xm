#import "DayNightSwitch.h"
#import "JoyConSwitch.h"
#import "DNSSwitchLike.h"

#import <roothide.h>

@interface PSSwitchTableCell : UITableViewCell
- (SEL)cellAction;
@end

@interface PSSpecifier : NSObject
@end

// MARK: Settings
static BOOL enabled = NO;
static BOOL global = NO;
// 0 = jour/nuit (défaut), 1 = joycon, 2 = joycon2
static NSInteger switchMode = 0;

static Class SwitchClassForMode(void) {
    switch (switchMode) {
        case 1:
            return [JoyConSwitch class];
        case 2:
            return [JoyCon2Switch class];
        default:
            return [DayNightSwitch class];
    }
}

static void loadPrefs(void) {

    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithUTF8String:jbroot("/var/mobile/Library/Preferences/de.finngaida.daynightswitch.plist")]];

    enabled = [settings objectForKey:@"enabled"] ? [[settings objectForKey:@"enabled"] boolValue] : YES;
    global = [settings objectForKey:@"global"] ? [[settings objectForKey:@"global"] boolValue] : NO;

    // "daynight" (défaut), "joycon" ou "joycon2" (modes Nintendo Switch)
    NSString *mode = [settings objectForKey:@"mode"];
    if ([mode isKindOfClass:[NSString class]] && [mode isEqualToString:@"joycon"]) {
        switchMode = 1;
    } else if ([mode isKindOfClass:[NSString class]] && [mode isEqualToString:@"joycon2"]) {
        switchMode = 2;
    } else {
        switchMode = 0;
    }
}

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("de.finngaida.daynightswitch/settingschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPrefs();
}

@interface UISwitch (DayNightSwitch)
// UIView * (et non un type précis) car le switch peut être un DayNightSwitch ou un JoyConSwitch
@property (nonatomic, strong) UIView *dns_dayNightSwitch;
@property (nonatomic, strong) NSNumber *dns_bypass;
- (UIImpactFeedbackGenerator *)_impactFeedbackGenerator;
- (void)dns_setup;
- (void)dns_addSwitchWithOn:(BOOL)on;
- (void)dns_hideNativeVisuals;
@end

%hook UISwitch

%property (nonatomic, strong) UIView *dns_dayNightSwitch;
%property (nonatomic, strong) NSNumber *dns_bypass;

- (void)layoutSubviews {
    %orig;
    [self dns_setup];
    [self dns_hideNativeVisuals];
}

%new
- (void)dns_setup {
    if (!enabled) {
        return;
    }

    CGSize size = self.bounds.size;
    if (size.width < 1 || size.height < 1) {
        return;
    }

    // Déjà en place : on ne refait que si la taille du UISwitch ou le mode ont changé
    UIView<DNSSwitchLike> *current = (UIView<DNSSwitchLike> *)self.dns_dayNightSwitch;
    if (current) {
        Class wanted = SwitchClassForMode();
        if (!CGSizeEqualToSize(current.bounds.size, size) || ![current isMemberOfClass:wanted]) {
            BOOL wasOn = current.on;
            [current removeFromSuperview];
            self.dns_dayNightSwitch = nil;
            [self dns_addSwitchWithOn:wasOn];
        }
        return;
    }

    if (global) {
        [self dns_addSwitchWithOn:self.on];
        return;
    }

    static NSString *bundleId = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundleId = [[NSBundle mainBundle] bundleIdentifier];
    });

    if ([bundleId isEqual:@"com.apple.Preferences"]) {
        PSSwitchTableCell *cell = (PSSwitchTableCell *)self.superview;
        if ([cell respondsToSelector:@selector(specifier)] && [cell respondsToSelector:@selector(control)]) {
            id spec = [cell performSelector:@selector(specifier)];
            if ([spec respondsToSelector:@selector(identifier)]) {
                NSString *identifier = [spec performSelector:@selector(identifier)];
                if ([identifier isEqual:@"DND_TOP_LEVEL"] && [cell performSelector:@selector(control)] == self) {
                    [self dns_addSwitchWithOn:self.on];
                }
            }
        }
    }
}

%new
- (void)dns_addSwitchWithOn:(BOOL)on {
    // Même taille que le UISwitch natif (51x31 sur l'ancien, plus grand sur iOS 26)
    CGRect frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);

    Class switchClass = SwitchClassForMode();
    UIView<DNSSwitchLike> *sub = [[switchClass alloc] initWithFrame:frame];

    sub.on = on;

    __weak __typeof(self) weakSelf = self;
    sub.changeAction = ^(BOOL newOn, BOOL shouldNotifyChanged) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        strongSelf.dns_bypass = @YES;
        BOOL isOn = strongSelf.on;
        strongSelf.on = newOn;
        strongSelf.dns_bypass = nil;

        if (isOn != newOn) {
            [[strongSelf _impactFeedbackGenerator] impactOccurred];
        }

        if (shouldNotifyChanged) {
            [strongSelf sendActionsForControlEvents:UIControlEventValueChanged];
        }
    };

    self.dns_dayNightSwitch = sub;

    [self addSubview:sub];
    [self bringSubviewToFront:sub];
}

%new
- (void)dns_hideNativeVisuals {
    UIView *sub = self.dns_dayNightSwitch;
    if (!sub) {
        return;
    }

    for (UIView *v in self.subviews) {
        if (v == sub) {
            continue;
        }
        v.hidden = YES;
        v.alpha = 0;
    }

    for (CALayer *l in self.layer.sublayers) {
        if (l == sub.layer) {
            continue;
        }
        l.hidden = YES;
    }
}

- (void)setOn:(BOOL)arg1 animated:(BOOL)arg2 notifyingVisualElement:(BOOL)arg3 {
    %orig;
    [self dns_hideNativeVisuals];

    if ([self.dns_bypass boolValue]) {
        return;
    }

    UIView<DNSSwitchLike> *sub = (UIView<DNSSwitchLike> *)self.dns_dayNightSwitch;
    [sub blockChangeActionAnimated:arg2];
    [sub setOn:arg1];
    [sub unblockChangeAction];
}

%end

static UIView *FindViewOfClass(UIView *view, Class cls) {
    if ([view isKindOfClass:cls]) {
        return view;
    }
    for (UIView *subview in view.subviews) {
        UIView *foundView = FindViewOfClass(subview, cls);
        if (foundView) {
            return foundView;
        }
    }
    return nil;
}

@interface MTAAlarmTableViewCell : UITableViewCell
@end

%hook MTAAlarmTableViewCell

- (void)layoutSubviews {
    %orig;

    UIView *theView = FindViewOfClass(self.contentView, [DayNightSwitch class]);
    if (!theView) {
        theView = FindViewOfClass(self.contentView, [JoyConSwitch class]);
    }
    if ([theView respondsToSelector:@selector(dns_disableAnimations)]) {
        [(UIView<DNSSwitchLike> *)theView dns_disableAnimations];
    }
}

%end
