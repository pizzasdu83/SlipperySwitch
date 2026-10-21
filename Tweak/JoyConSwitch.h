//
//  JoyConSwitch.h
//  Mode "Nintendo Switch" : le Joy-Con droit vient se clipser sur le gauche
//

#import <UIKit/UIKit.h>

#import "DNSSwitchLike.h"

@interface JoyConSwitch : UIView <DNSSwitchLike>

/// Appelé quand la valeur change (BOOL on, BOOL shouldNotifyChanged)
@property (nonatomic, copy, nullable) void (^changeAction)(BOOL, BOOL);

/// OFF = Joy-Con séparés, ON = Joy-Con droit collé au gauche
@property (nonatomic, assign, getter=isOn) BOOL on;

- (void)blockChangeActionAnimated:(BOOL)animated;
- (void)unblockChangeAction;

- (void)dns_disableAnimations;

@end
