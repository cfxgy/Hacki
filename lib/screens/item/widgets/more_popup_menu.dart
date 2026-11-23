import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/models/models.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/item_menu_sheet.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

class MorePopupMenu extends StatelessWidget {
  const MorePopupMenu({
    required this.item,
    required this.isBlocked,
    required this.onLoginTapped,
    this.onSearchInThreadTapped,
    this.onReplyTapped,
    this.onViewInSeparateThreadTapped,
    super.key,
  });

  final Item item;
  final bool isBlocked;
  final VoidCallback onLoginTapped;
  final VoidCallback? onSearchInThreadTapped;
  final VoidCallback? onReplyTapped;
  final VoidCallback? onViewInSeparateThreadTapped;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VoteCubit>(
      create: (BuildContext context) =>
          VoteCubit(item: item, authBloc: context.read<AuthBloc>()),
      child: BlocConsumer<VoteCubit, VoteState>(
        listenWhen: (VoteState previous, VoteState current) {
          return previous.status != current.status;
        },
        listener: (BuildContext context, VoteState voteState) {
          if (voteState.status == VoteStatus.submitted) {
            context.showSnackBar(content: SnackBarMessages.voteSubmitted);
          } else if (voteState.status == VoteStatus.canceled) {
            context.showSnackBar(content: SnackBarMessages.voteCanceled);
          } else if (voteState.status == VoteStatus.failure) {
            context.showErrorSnackBar();
          } else if (voteState.status ==
              VoteStatus.failureKarmaBelowThreshold) {
            context.showSnackBar(content: SnackBarMessages.karmalyBroke);
          } else if (voteState.status == VoteStatus.failureNotLoggedIn) {
            context.showSnackBar(
              content: SnackBarMessages.notLoggedInNoVoting,
              persist: false,
              action: onLoginTapped,
              label: L10n.current.login,
            );
          } else if (voteState.status == VoteStatus.failureBeHumble) {
            context.showSnackBar(
              content: SnackBarMessages.noVotingOnYourOwnComment,
            );
          }

          context.pop(MenuAction.upvote);
        },
        builder: (BuildContext context, VoteState voteState) {
          final bool upvoted = voteState.vote == Vote.up;
          final bool downvoted = voteState.vote == Vote.down;
          return BlocBuilder<PreferenceCubit, PreferenceState>(
            builder: (BuildContext context, PreferenceState preferenceState) {
              final Map<ItemMenuAction, Widget>
              actions = <ItemMenuAction, Widget>{
                ItemMenuAction.viewProfile: BlocProvider<UserCubit>(
                  create: (BuildContext context) =>
                      UserCubit()..init(userId: item.by),
                  child: BlocBuilder<UserCubit, UserState>(
                    builder: (BuildContext context, UserState state) {
                      return Semantics(
                        excludeSemantics: state.status == Status.inProgress,
                        child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              AnimatedCrossFade(
                                alignment: Alignment.center,
                                duration: AppDurations.ms300,
                                crossFadeState: state.status.isLoading
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                firstChild: const Icon(
                                  Icons.account_circle_outlined,
                                ),
                                secondChild: const Icon(Icons.account_circle),
                              ),
                            ],
                          ),
                          title: Text(item.by),
                          subtitle: Text(state.user.description),
                          onTap: () {
                            context.pop();
                            final double fontSize = context
                                .read<PreferenceCubit>()
                                .state
                                .fontSize
                                .fontSize;
                            showDialog<void>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                semanticLabel: L10n.current.aboutUser(
                                  state.user.id,
                                ),
                                title: Text(
                                  L10n.current.aboutUser(state.user.id),
                                ),
                                content: state.user.about.isEmpty
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text(
                                            L10n.current.empty,
                                            style: const TextStyle(
                                              color: Palette.grey,
                                            ),
                                          ),
                                        ],
                                      )
                                    : SelectableLinkify(
                                        text: HtmlUtils.parseHtml(
                                          state.user.about,
                                        ),
                                        style: TextStyle(fontSize: fontSize),
                                        linkStyle: TextStyle(
                                          fontSize: fontSize,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        onOpen: (LinkableElement link) =>
                                            LinkUtils.launch(link.url, context),
                                        semanticsLabel: state.user.about,
                                      ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      context.pop();
                                      onSearchUserTapped(context);
                                    },
                                    child: Text(L10n.current.search),
                                  ),
                                  TextButton(
                                    onPressed: context.pop,
                                    child: Text(L10n.current.okay),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                ItemMenuAction.searchOnHackerNews: ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(L10n.current.searchOnHn),
                  onTap: () {
                    context.pop();
                    onSearchUserTapped(context);
                  },
                ),
                if (onSearchInThreadTapped != null)
                  ItemMenuAction.searchInThread: ListTile(
                    leading: const Icon(Icons.manage_search),
                    title: Text(L10n.current.searchInThread),
                    onTap: onSearchInThreadTapped,
                  ),
                if (onReplyTapped != null)
                  ItemMenuAction.reply: ListTile(
                    leading: const Icon(Icons.message),
                    title: Text(L10n.current.reply),
                    onTap: () {
                      context.pop();
                      onReplyTapped?.call();
                    },
                  ),
                ItemMenuAction.upvote: ListTile(
                  leading: Icon(
                    upvoted
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_up_off_alt_outlined,
                    color: upvoted
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    upvoted ? L10n.current.upvoted : L10n.current.upvote,
                    style: upvoted
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  subtitle: item is Story ? Text(item.score.toString()) : null,
                  onTap: context.read<VoteCubit>().upvote,
                ),
                ItemMenuAction.downvote: ListTile(
                  leading: Icon(
                    downvoted
                        ? Icons.thumb_down_rounded
                        : Icons.thumb_down_off_alt_outlined,
                    color: downvoted
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    downvoted ? L10n.current.downvoted : L10n.current.downvote,
                    style: downvoted
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  onTap: context.read<VoteCubit>().downvote,
                ),
                ItemMenuAction.favorite: BlocBuilder<FavCubit, FavState>(
                  builder: (BuildContext context, FavState state) {
                    final bool isFav = state.favIds.contains(item.id);
                    return ListTile(
                      leading: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        isFav ? L10n.current.unfavorite : L10n.current.favorite,
                      ),
                      onTap: () => context.pop(MenuAction.fav),
                    );
                  },
                ),
                ItemMenuAction.share: ListTile(
                  leading: const Icon(FeatherIcons.share),
                  title: Text(L10n.current.share),
                  onTap: () => context.pop(MenuAction.share),
                ),
                ItemMenuAction.flag: ListTile(
                  leading: const Icon(Icons.local_police),
                  title: Text(L10n.current.flag),
                  onTap: () => context.pop(MenuAction.flag),
                ),
                ItemMenuAction.block: ListTile(
                  leading: Icon(
                    isBlocked ? Icons.visibility : Icons.visibility_off,
                  ),
                  title: Text(
                    isBlocked ? L10n.current.unblock : L10n.current.block,
                  ),
                  onTap: () => context.pop(MenuAction.block),
                ),
                if (onViewInSeparateThreadTapped != null && item is Comment)
                  ItemMenuAction.viewInSeparateThread: ListTile(
                    leading: const Icon(Icons.list),
                    title: Text(L10n.current.viewInSeparateThread),
                    onTap: () {
                      context.pop();
                      onViewInSeparateThreadTapped?.call();
                    },
                  ),
                ItemMenuAction.viewInBrowser: ListTile(
                  leading: const Icon(Icons.open_in_browser),
                  title: Text(L10n.current.viewInBrowser),
                  onTap: () {
                    context.pop();
                    final String url =
                        '${Constants.hackerNewsItemLinkPrefix}${item.id}';
                    LinkUtils.launch(
                      url,
                      context,
                      shouldUseHackiForHnLink: false,
                    );
                  },
                ),
              };
              return ItemMenuSheet(
                enabledActions: preferenceState.enabledItemMenuActions,
                actions: actions,
                onCancel: () => context.pop(MenuAction.cancel),
              );
            },
          );
        },
      ),
    );
  }

  void onSearchUserTapped(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.7,
          builder: (BuildContext context, ScrollController scrollController) {
            return BlocProvider<SearchCubit>(
              create: (_) =>
                  SearchCubit()..addFilter(PostedByFilter(author: item.by)),
              child: SearchScreen(
                isInBottomSheet: true,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }
}
