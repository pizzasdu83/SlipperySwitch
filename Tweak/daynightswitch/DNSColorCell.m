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
    /// Code hexadécimal affiché à gauche du sélecteur
    UILabel *_hexLabel;
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

        // Le code hex est affiché par nous (le texte de valeur des Réglages est caché, voir layoutSubviews)
        _hexLabel = [[UILabel alloc] init];
        _hexLabel.textAlignment = NSTextAlignmentRight;
        _hexLabel.textColor = [UIColor secondaryLabelColor];
        _hexLabel.font = [UIFont monospacedSystemFontOfSize:15 weight:UIFontWeightRegular];
        _hexLabel.adjustsFontSizeToFitWidth = YES;
        _hexLabel.minimumScaleFactor = 0.7;
        [self.contentView addSubview:_hexLabel];

        // Le sélecteur est placé dans le contentView (et non en accessoryView) :
        // les Réglages réinitialisent l'accessoryView quand ils recyclent la cellule
        [self.contentView addSubview:_colorWell];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        [self loadColorFromSpecifier:specifier];
    }
    return self;
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
    [super refreshCellContentsWithSpecifier:specifier];
    [self loadColorFromSpecifier:specifier];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!_colorWell) {
        return;
    }

    // s'assure que le sélecteur est toujours là (cellule recyclée) et le place à droite
    if (_colorWell.superview != self.contentView) {
        [self.contentView addSubview:_colorWell];
    }

    CGFloat size = 34;
    CGRect bounds = self.contentView.bounds;
    _colorWell.frame = CGRectMake(CGRectGetMaxX(bounds) - size - 20, (CGRectGetHeight(bounds) - size) / 2, size, size);

    // code hex juste à gauche du sélecteur
    CGFloat hexWidth = 90;
    _hexLabel.frame = CGRectMake(CGRectGetMinX(_colorWell.frame) - 10 - hexWidth, 0, hexWidth, CGRectGetHeight(bounds));

    // cache le texte de valeur ajouté par les Réglages (il passait sous le sélecteur et était coupé)
    NSMutableArray<UIView *> *candidates = [NSMutableArray arrayWithArray:self.contentView.subviews];
    [candidates addObjectsFromArray:self.subviews];
    for (UIView *view in candidates) {
        if ([view isKindOfClass:[UILabel class]] && view != self.textLabel && view != _hexLabel) {
            view.hidden = YES;
        }
    }

    [self.contentView bringSubviewToFront:_hexLabel];
    [self.contentView bringSubviewToFront:_colorWell];
}

- (void)loadColorFromSpecifier:(PSSpecifier *)specifier {
    PSListController *controller = (PSListController *)specifier.target;
    if (![controller respondsToSelector:@selector(readPreferenceValue:)]) {
        return;
    }

    UIColor *color = DNSCellColorFromHex([controller readPreferenceValue:specifier]);
    _colorWell.selectedColor = color;
    _hexLabel.text = DNSCellHexFromColor(color);
}

- (void)colorDidChange:(UIColorWell *)sender {
    PSSpecifier *specifier = self.specifier;
    PSListController *controller = (PSListController *)specifier.target;
    if (!sender.selectedColor || ![controller respondsToSelector:@selector(setPreferenceValue:specifier:)]) {
        return;
    }

    NSString *hex = DNSCellHexFromColor(sender.selectedColor);
    _hexLabel.text = hex;
    [controller setPreferenceValue:hex specifier:specifier];
}

@end
