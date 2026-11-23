import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/dialog_proxy.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class OfflineListTile extends StatelessWidget {
  const OfflineListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoriesBloc, StoriesState>(
      listenWhen: (StoriesState previous, StoriesState current) =>
          previous.downloadStatus != current.downloadStatus,
      listener: (BuildContext context, StoriesState state) {
        if (state.downloadStatus == StoriesDownloadStatus.failure ||
            state.downloadStatus == StoriesDownloadStatus.finished) {
          WakelockPlus.disable();
        }
      },
      buildWhen: (StoriesState previous, StoriesState current) =>
          previous.downloadStatus != current.downloadStatus ||
          previous.storiesDownloaded != current.storiesDownloaded ||
          previous.storiesToBeDownloaded != current.storiesToBeDownloaded ||
          previous.downloadTimestamp != current.downloadTimestamp,
      builder: (BuildContext context, StoriesState state) {
        final bool downloading =
            state.downloadStatus == StoriesDownloadStatus.downloading;
        final bool downloaded =
            state.downloadStatus == StoriesDownloadStatus.finished;

        final Widget trailingWidget = () {
          if (downloading) {
            return const SizedBox(
              height: Dimens.pt24,
              width: Dimens.pt24,
              child: CustomCircularProgressIndicator(),
            );
          } else if (downloaded) {
            return Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            );
          }
          return Icon(
            Icons.download,
            color: Theme.of(context).colorScheme.primary,
          );
        }();

        return ListTile(
          title: Text(() {
            if (downloading) {
              return L10n.current.downloadingStories(
                '${state.storiesDownloaded}',
                '${state.storiesToBeDownloaded}',
              );
            } else if (state.storiesDownloaded != 0) {
              return L10n.current.storiesDownloaded(
                '${state.storiesDownloaded}',
              );
            }
            return L10n.current.downloadStories;
          }()),
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(L10n.current.downloadStoriesDescription),
              if (state.downloadStatus != StoriesDownloadStatus.downloading &&
                  state.downloadTimestamp != null)
                Text(
                  L10n.current.lastDownloadedAt('${state.downloadDateTime}'),
                  style: TextStyle(
                    fontSize: TextDimens.pt12,
                    color: Theme.of(context).colorScheme.onSurface
                        .withAlpha(160),
                  ),
                ),
            ],
          ),
          trailing: trailingWidget,
          isThreeLine: true,
          onTap: () {
            if (state.downloadStatus == StoriesDownloadStatus.downloading) {
              DialogProxy.showAbortDownloadDialog(context);
            } else {
              context.read<StoriesBloc>().add(ClearMaxOfflineStoriesCount());
              Connectivity().checkConnectivity().then((
                List<ConnectivityResult> res,
              ) {
                if (!res.contains(ConnectivityResult.none) && context.mounted) {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBoxes.pt12,
                            Text(L10n.current.howManyStories),
                            for (final MaxOfflineStoriesCount count
                                in MaxOfflineStoriesCount.values)
                              ListTile(
                                title: Text(count.label),
                                onTap: () {
                                  HapticFeedbackUtils.selection();

                                  context.pop();
                                  final StoriesBloc storiesBloc =
                                      context.read<StoriesBloc>()..add(
                                        UpdateMaxOfflineStoriesCount(
                                          count: count,
                                        ),
                                      );
                                  showConfirmationDialog(context, storiesBloc);
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }
              });
            }
          },
        );
      },
    );
  }

  void showConfirmationDialog(BuildContext context, StoriesBloc storiesBloc) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(L10n.current.downloadWebPages),
        content: Text(L10n.current.willTakeLonger),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.pop(),
            child: Text(L10n.current.cancel),
          ),
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(L10n.current.no),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(L10n.current.yes),
          ),
        ],
      ),
    ).then((bool? includeWebPage) {
      if (includeWebPage != null) {
        WakelockPlus.enable();

        storiesBloc.add(StoriesDownload(includingWebPage: includeWebPage));
      }
    });
  }
}
