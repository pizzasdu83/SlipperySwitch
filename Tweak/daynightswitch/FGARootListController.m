#import "FGARootListController.h"

#import <Preferences/PSSpecifier.h>

#import <roothide.h>
#import <spawn.h>

// Préfixes des trois parties réglables : piste activée, piste désactivée, bouton
static NSArray<NSString *> *GradientPrefixes(void) {
    return @[ @"on", @"off", @"knob" ];
}

@implementation FGARootListController {
    /// Les menus d'angle, gardés ici pour pouvoir les remettre quand on repasse en "linéaire"
    NSMutableDictionary<NSString *, PSSpecifier *> *_angleSpecifiers;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSArray *loaded = [self loadSpecifiersFromPlistName:@"Root" target:self];

        _angleSpecifiers = [NSMutableDictionary dictionary];
        NSMutableArray *visible = [loaded mutableCopy];

        for (NSString *prefix in GradientPrefixes()) {
            NSString *angleID = [prefix stringByAppendingString:@"GradientAngle"];
            NSString *typeID = [prefix stringByAppendingString:@"GradientType"];

            PSSpecifier *angle = nil;
            PSSpecifier *type = nil;
            for (PSSpecifier *specifier in loaded) {
                if ([specifier.identifier isEqualToString:angleID]) {
                    angle = specifier;
                } else if ([specifier.identifier isEqualToString:typeID]) {
                    type = specifier;
                }
            }

            if (!angle || !type) {
                continue;
            }

            _angleSpecifiers[angleID] = angle;

            // au chargement : pas de menu d'angle si le dégradé est déjà en mode radial
            if ([[self readPreferenceValue:type] isEqual:@"radial"]) {
                [visible removeObject:angle];
            }
        }

        _specifiers = visible;
    }

    return _specifiers;
}

/// Quand on change le type de dégradé : cache le menu d'angle en radial, le remet en linéaire
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];

    NSString *key = [specifier propertyForKey:@"key"];
    if (![key hasSuffix:@"GradientType"]) {
        return;
    }

    NSString *prefix = [key substringToIndex:key.length - @"GradientType".length];
    NSString *angleID = [prefix stringByAppendingString:@"GradientAngle"];

    PSSpecifier *shownAngle = [self specifierForID:angleID];
    BOOL radial = [value isEqual:@"radial"];

    if (radial && shownAngle) {
        [self removeSpecifier:shownAngle animated:YES];
    } else if (!radial && !shownAngle && _angleSpecifiers[angleID]) {
        [self insertSpecifier:_angleSpecifiers[angleID] afterSpecifierID:key animated:YES];
    }
}

- (void)respring {
    pid_t pid;
    const char *args[] = {"killall", "-9", "SpringBoard", "backboardd", NULL};
    posix_spawn(&pid, jbroot("/usr/bin/killall"), NULL, NULL, (char *const *)args, NULL);
}

- (void)mysource {
    [self openURL:[NSURL URLWithString:@"https://github.com/pizzasdu83/DayNightSwitchGlass"]];
}

- (void)asource {
    [self openURL:[NSURL URLWithString:@"https://github.com/owngoal-dev/DayNightSwitch"]];
}

- (void)thesource {
    [self openURL:[NSURL URLWithString:@"https://github.com/finngaida/DayNightSwitch"]];
}

- (void)support {
    [self openURL:[NSURL URLWithString:@"https://pizzasdu83.github.io/smtrepo/"]];
}

- (void)openURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
        NSString *key = [specifier propertyForKey:@"cell"];
        if ([key isEqualToString:@"PSButtonCell"]) {
            UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
            NSNumber *isDestructiveValue = [specifier propertyForKey:@"isDestructive"];
            BOOL isDestructive = [isDestructiveValue boolValue];
            cell.textLabel.textColor = isDestructive ? [UIColor systemRedColor] : [UIColor systemBlueColor];
            cell.textLabel.highlightedTextColor = isDestructive ? [UIColor systemRedColor] : [UIColor systemBlueColor];
            return cell;
        }
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

@end
