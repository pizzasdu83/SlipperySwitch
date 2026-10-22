//
//  SimpleSwitch.h
//  Mode "Simple" : piste activée / désactivée et bouton, chacun avec sa couleur
//  (unie ou dégradé) configurable dans les réglages
//

#import <UIKit/UIKit.h>

#import "DNSSwitchLike.h"

@interface SimpleSwitch : UIView <DNSSwitchLike>

/// Appelé quand la valeur change (BOOL on, BOOL shouldNotifyChanged)
@property (nonatomic, copy, nullable) void (^changeAction)(BOOL, BOOL);

/// État du switch
@property (nonatomic, assign, getter=isOn) BOOL on;

/// Relit les couleurs depuis le dictionnaire de préférences (nil = couleurs par défaut)
+ (void)applyPrefs:(nullable NSDictionary *)prefs;

- (void)blockChangeActionAnimated:(BOOL)animated;
- (void)unblockChangeAction;

- (void)dns_disableAnimations;

@end
