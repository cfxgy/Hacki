import 'package:hacki/l10n/l10n.dart';

enum ImportSource {
  qrCode,
  file;

  String get uiLabel => switch (this) {
    ImportSource.qrCode => L10n.current.importQrCode,
    ImportSource.file => L10n.current.importFile,
  };
}
