//
//  JoyConSwitch.h
//  Mode "Nintendo Switch" : Joy-Con couchés, le plein vient se clipser sur le creux
//

#import <UIKit/UIKit.h>

#import "DNSSwitchLike.h"

@interface JoyConSwitch : UIView <DNSSwitchLike>

/// Appelé quand la valeur change (BOOL on, BOOL shouldNotifyChanged)
@property (nonatomic, copy, nullable) void (^changeAction)(BOOL, BOOL);

/// OFF = Joy-Con séparés (plein à gauche), ON = Joy-Con plein clipsé sur le creux (à droite)
@property (nonatomic, assign, getter=isOn) BOOL on;

- (void)blockChangeActionAnimated:(BOOL)animated;
- (void)unblockChangeAction;

- (void)dns_disableAnimations;

@end

/// Variante "Joy-Con 2" : Joy-Con debout, les deux se rejoignent au milieu quand le switch est activé
@interface JoyCon2Switch : JoyConSwitch

@end
