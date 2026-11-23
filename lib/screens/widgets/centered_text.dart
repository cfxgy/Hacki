import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart';

class CenteredText extends StatelessWidget {
  const CenteredText({
    required this.text,
    super.key,
    this.color = Palette.grey,
  });

  const CenteredText.hidden({Key? key}) : this(key: key, text: 'hidden');

  const CenteredText.deleted({Key? key}) : this(key: key, text: 'deleted');

  const CenteredText.dead({Key? key}) : this(key: key, text: 'dead');

  const CenteredText.blocked({Key? key}) : this(key: key, text: 'blocked');

  const CenteredText.empty({Key? key}) : this(key: key, text: 'empty');

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final String displayText = switch (text) {
      'hidden' => L10n.current.hidden,
      'deleted' => L10n.current.deleted,
      'dead' => L10n.current.dead,
      'blocked' => L10n.current.blocked,
      'empty' => L10n.current.empty,
      _ => text,
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Dimens.pt12),
        child: Text(displayText, style: TextStyle(color: color)),
      ),
    );
  }
}
