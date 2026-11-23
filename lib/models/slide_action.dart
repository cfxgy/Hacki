import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart' show IconData, Icons;

enum SlideAction {
  upvote(icon: Icons.thumb_up),
  downvote(icon: Icons.thumb_down),
  timeMachine(icon: Icons.av_timer),
  goToParent(icon: Icons.arrow_upward),
  viewProfile(icon: Icons.account_circle),
  searchOnHackerNews(icon: Icons.search),
  searchInThread(icon: Icons.manage_search),
  favorite(icon: Icons.favorite),
  share(icon: FeatherIcons.share),
  viewInBrowser(icon: Icons.open_in_browser),
  reply(icon: Icons.message),
  viewInSeparateThread(icon: Icons.list),
  goToRoot(icon: Icons.vertical_align_top);

  const SlideAction({required this.icon});

  /// The order in which actions are offered to the user, following the
  /// "more" bottom sheet. Preferences store [index], so the declaration
  /// order above must stay append-only.
  static const List<SlideAction> displayOrder = <SlideAction>[
    viewProfile,
    searchOnHackerNews,
    searchInThread,
    reply,
    upvote,
    downvote,
    favorite,
    share,
    viewInSeparateThread,
    viewInBrowser,
    timeMachine,
    goToParent,
    goToRoot,
  ];

  final IconData icon;

  String get description => switch (this) {
    SlideAction.upvote => L10n.current.upvote,
    SlideAction.downvote => L10n.current.downvote,
    SlideAction.timeMachine => L10n.current.slideActionTimeMachine,
    SlideAction.goToParent => L10n.current.slideActionGoToParent,
    SlideAction.viewProfile => L10n.current.slideActionViewProfile,
    SlideAction.searchOnHackerNews => L10n.current.searchOnHn,
    SlideAction.searchInThread => L10n.current.searchInThread,
    SlideAction.favorite => L10n.current.favorite,
    SlideAction.share => L10n.current.share,
    SlideAction.viewInBrowser => L10n.current.viewInBrowser,
    SlideAction.reply => L10n.current.reply,
    SlideAction.viewInSeparateThread => L10n.current.viewInSeparateThread,
    SlideAction.goToRoot => L10n.current.slideActionGoToRoot,
  };

  @override
  String toString() => description;
}
