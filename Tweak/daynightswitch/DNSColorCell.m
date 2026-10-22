//
//  DNSColorCell.m
//  Cellule de réglages avec un sélecteur de couleur (UIColorWell).
//  La valeur est stockée sous forme de texte "#RRGGBB".
//
//  Utilisation dans Root.plist :
//    cell      = PSStaticTextCell
//    cellClass = DNSColorCell
//    defaults, key, default (ex. "#34C759"), label
//

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <UIKit/UIKit.h>

@interface DNSColorCell : PSTableCell
@end

@implementation DNSColorCell {
    UIColorWell *_colorWell;
}

/// "#RRGGBB" → UIColor (gris si la valeur est invalide)
static UIColor *DNSCellColorFromHex(id value) {
    if (![value isKindOfClass:[NSString class]]) {
        return [UIColor grayColor];
    }

    NSString *s = value;
    if ([s hasPrefix:@"#"]) {
        s = [s substringFromIndex:1];
    }

    char *end = NULL;
    unsigned long rgb = strtoul(s.UTF8String, &end, 16);
    if (s.length != 6 || !end || *end != '\0') {
        return [UIColor grayColor];
    }

    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                           green:((rgb >> 8) & 0xFF) / 255.0
                            blue:(rgb & 0xFF) / 255.0
                           alpha:1];
}

/// UIColor → "#RRGGBB"
static NSString *DNSCellHexFromColor(UIColor *color) {
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [color getRed:&r green:&g blue:&b alpha:&a];

    return [NSString stringWithFormat:@"#%02X%02X%02X", (int)lround(r * 255), (int)lround(g * 255), (int)lround(b * 255)];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
                    specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if (self) {
        _colorWell = [[UIColorWell alloc] initWithFrame:CGRectMake(0, 0, 34, 34)];
        _colorWell.supportsAlpha = NO;
        [_colorWell addTarget:self action:@selector(colorDidChange:) forControlEvents:UIControlEventValueChanged];

        self.accessoryView = _colorWell;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        [self loadColorFromSpecifier:specifier];
    }
    return self;
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
    [super refreshCellContentsWithSpecifier:specifier];
    [self loadColorFromSpecifier:specifier];
}

- (void)loadColorFromSpecifier:(PSSpecifier *)specifier {
    PSListController *controller = (PSListController *)specifier.target;
    if (![controller respondsToSelector:@selector(readPreferenceValue:)]) {
        return;
    }

    _colorWell.selectedColor = DNSCellColorFromHex([controller readPreferenceValue:specifier]);
}

- (void)colorDidChange:(UIColorWell *)sender {
    PSSpecifier *specifier = self.specifier;
    PSListController *controller = (PSListController *)specifier.target;
    if (!sender.selectedColor || ![controller respondsToSelector:@selector(setPreferenceValue:specifier:)]) {
        return;
    }

    [controller setPreferenceValue:DNSCellHexFromColor(sender.selectedColor) specifier:specifier];
}

@end
