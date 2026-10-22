#import "FGARootListController.h"

#import <Preferences/PSSpecifier.h>

#import <roothide.h>
#import <spawn.h>

// Préfixes des trois parties réglables : piste activée, piste désactivée, bouton
static NSArray<NSString *> *GradientPrefixes(void) {
    return @[ @"on", @"off", @"knob" ];
}

/// "onColor1" → "on", "knobGradientAngle" → "knob"... (nil si ce n'est pas un réglage de couleur)
static NSString *PrefixForKey(NSString *key) {
    for (NSString *prefix in GradientPrefixes()) {
        if ([key hasPrefix:[prefix stringByAppendingString:@"Gradient"]] ||
            [key hasPrefix:[prefix stringByAppendingString:@"Color"]]) {
            return prefix;
        }
    }
    return nil;
}

@implementation FGARootListController {
    /// Tous les réglages du plist, dans l'ordre (la liste affichée en est un sous-ensemble)
    NSArray<PSSpecifier *> *_allSpecifiers;
    /// Les mêmes, retrouvables par leur clé de préférence
    NSMutableDictionary<NSString *, PSSpecifier *> *_specifiersByKey;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        if (!_allSpecifiers) {
            _allSpecifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];

            _specifiersByKey = [NSMutableDictionary dictionary];
            for (PSSpecifier *specifier in _allSpecifiers) {
                NSString *key = [specifier propertyForKey:@"key"];
                if (key) {
                    _specifiersByKey[key] = specifier;
                }
            }
        }

        _specifiers = [self visibleSpecifiers];
    }

    return _specifiers;
}

/// Valeur actuelle d'une préférence (ou sa valeur par défaut)
- (id)currentValueForKey:(NSString *)key {
    PSSpecifier *specifier = _specifiersByKey[key];
    return specifier ? [self readPreferenceValue:specifier] : nil;
}

/// Les réglages à afficher selon l'état actuel :
/// - les réglages de couleur : seulement en mode "Simple"
/// - "Color 2" et le type de dégradé : seulement si "Gradient" est activé
/// - le menu d'angle : seulement si "Gradient" est activé et que le type est "Linear"
- (NSMutableArray *)visibleSpecifiers {
    BOOL simple = [[self currentValueForKey:@"mode"] isEqual:@"simple"];

    NSMutableArray *visible = [NSMutableArray array];

    for (NSUInteger i = 0; i < _allSpecifiers.count; i++) {
        PSSpecifier *specifier = _allSpecifiers[i];
        NSString *key = [specifier propertyForKey:@"key"];

        // le titre de groupe (sans clé) appartient à la partie dont le premier réglage suit
        NSString *prefix = key ? PrefixForKey(key) : nil;
        if (!key && i + 1 < _allSpecifiers.count) {
            NSString *nextKey = [_allSpecifiers[i + 1] propertyForKey:@"key"];
            prefix = nextKey ? PrefixForKey(nextKey) : nil;
        }

        // pas un réglage de couleur : toujours affiché
        if (!prefix) {
            [visible addObject:specifier];
            continue;
        }

        if (!simple) {
            continue;
        }

        // le titre de groupe, "Gradient" et "Color" : toujours affichés en mode Simple
        if (!key || [key isEqualToString:[prefix stringByAppendingString:@"Gradient"]] ||
            [key isEqualToString:[prefix stringByAppendingString:@"Color1"]]) {
            [visible addObject:specifier];
            continue;
        }

        BOOL gradient = [[self currentValueForKey:[prefix stringByAppendingString:@"Gradient"]] boolValue];
        if (!gradient) {
            continue;
        }

        if ([key isEqualToString:[prefix stringByAppendingString:@"GradientAngle"]]) {
            BOOL radial = [[self currentValueForKey:[prefix stringByAppendingString:@"GradientType"]] isEqual:@"radial"];
            if (radial) {
                continue;
            }
        }

        [visible addObject:specifier];
    }

    return visible;
}

/// Recalcule ce qui est affiché
- (void)refreshVisibleSpecifiers {
    _specifiers = [self visibleSpecifiers];
    [self reloadSpecifiers];
}

/// Quand le style, un interrupteur "Gradient" ou un type de dégradé change : met à jour la liste
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];

    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) {
        return;
    }

    if ([key isEqualToString:@"mode"] || [key hasSuffix:@"GradientType"] ||
        ([key hasSuffix:@"Gradient"] && PrefixForKey(key))) {
        // un tour de boucle plus tard, pour ne pas recharger la liste en plein clic sur le contrôle
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshVisibleSpecifiers];
        });
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
