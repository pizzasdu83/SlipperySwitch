//
//  DNSSwitchLike.h
//  Protocole commun aux switchs custom (DayNightSwitch, JoyConSwitch)
//

#import <UIKit/UIKit.h>

@protocol DNSSwitchLike <NSObject>

/// Appelé quand la valeur change (BOOL on, BOOL shouldNotifyChanged)
@property (nonatomic, copy, nullable) void (^changeAction)(BOOL, BOOL);

/// État du switch
@property (nonatomic, assign, getter=isOn) BOOL on;

- (void)blockChangeActionAnimated:(BOOL)animated;
- (void)unblockChangeAction;
- (void)dns_disableAnimations;

@end
