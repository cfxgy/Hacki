import 'dart:math';

import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeViewScreen extends StatelessWidget {
  const QrCodeViewScreen({required this.data, super.key});

  final String data;

  static const String routeName = 'qr-code-view';

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        elevation: Dimens.zero,
        backgroundColor: Palette.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: QrImageView(
              data: data,
              padding: const EdgeInsets.symmetric(horizontal: Dimens.pt24),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              size: min(600, screenWidth),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.pt24),
            child: Text(L10n.current.qrImportHint, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
