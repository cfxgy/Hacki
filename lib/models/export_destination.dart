import 'package:hacki/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart' show IconData, Icons;

enum ExportDestination {
  qrCode(icon: Icons.qr_code),
  clipBoard(icon: Icons.copy);

  const ExportDestination({required this.icon});

  final IconData icon;

  String get label => switch (this) {
    ExportDestination.qrCode => L10n.current.exportQrCode,
    ExportDestination.clipBoard => L10n.current.exportClipboard,
  };
}
