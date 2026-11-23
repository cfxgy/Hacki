import 'package:go_router/go_router.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart';

class PostedByFilterChip extends StatelessWidget {
  const PostedByFilterChip({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final PostedByFilter? filter;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      onSelected: (_) async {
        final String? username = await onChipTapped(context);
        if (username == filter?.author) {
          return;
        }
        onChanged(username);
      },
      selected: filter != null,
      label: L10n.current.postedByFilter(filter?.author ?? ''),
    );
  }

  Future<String?> onChipTapped(BuildContext context) async {
    final TextEditingController usernameController = TextEditingController();

    if (filter?.author != null) {
      usernameController.text = filter!.author;
    }

    final String? username = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimens.pt18),
              child: TextField(
                controller: usernameController,
                cursorColor: Theme.of(context).colorScheme.primary,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: L10n.current.usernameHint,
                ),
              ),
            ),
            const SizedBox(height: Dimens.pt16),
            Padding(
              padding: const EdgeInsets.only(right: Dimens.pt12),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => context.pop(filter?.author),
                    child: Text(L10n.current.cancel),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(L10n.current.clear),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final String text = usernameController.text.trim();
                      context.pop(text.isEmpty ? null : text);
                    },
                    child: Text(L10n.current.confirm),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    return username;
  }
}
