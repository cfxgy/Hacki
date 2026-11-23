import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';
import 'package:material_ui/material_ui.dart';

class EnterOfflineModeListTile extends StatelessWidget {
  const EnterOfflineModeListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoriesBloc, StoriesState>(
      buildWhen: (StoriesState previous, StoriesState current) =>
          previous.isOfflineReading != current.isOfflineReading,
      builder: (BuildContext context, StoriesState state) {
        return SwitchListTile(
          value: state.isOfflineReading,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          title: Text(L10n.current.offlineMode),
          onChanged: (bool value) {
            HapticFeedbackUtils.light();
            context.read<StoriesBloc>().add(
              value ? StoriesEnterOfflineMode() : StoriesExitOfflineMode(),
            );
            if (value) {
              context.showSnackBar(content: L10n.current.offlineActivated);
            } else {
              context.showSnackBar(content: L10n.current.offlineDeactivated);
            }
          },
        );
      },
    );
  }
}
