import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/styles/styles.dart';

enum FontSize {
  small(TextDimens.pt15),
  regular(TextDimens.pt16),
  large(TextDimens.pt17),
  xlarge(TextDimens.pt18),
  xxlarge(TextDimens.pt19);

  const FontSize(this.fontSize);

  final double fontSize;

  String get description => switch (this) {
    FontSize.small => L10n.current.fontSizeSmall,
    FontSize.regular => L10n.current.fontSizeRegular,
    FontSize.large => L10n.current.fontSizeLarge,
    FontSize.xlarge => L10n.current.fontSizeXLarge,
    FontSize.xxlarge => L10n.current.fontSizeXXLarge,
  };
}
