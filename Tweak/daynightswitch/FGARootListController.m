#import "FGARootListController.h"

#import <Preferences/PSSpecifier.h>

#import <roothide.h>
#import <spawn.h>

@implementation FGARootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }

    return _specifiers;
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
