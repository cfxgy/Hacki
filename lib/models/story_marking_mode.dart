import 'package:hacki/l10n/l10n.dart';

/// Used for determining when to mark a story as read.
enum StoryMarkingMode {
  // Mark a story as read after user scrolls past it.
  scrollPast,
  // Mark a story as read after user taps on it.
  tap,
  // Mark a story as read after user scrolls past or taps on it, whichever
  // happens the first.
  scrollPastOrTap,
  swipeGestureOnly;

  String get label => switch (this) {
    StoryMarkingMode.scrollPast => L10n.current.storyMarkingScrollPast,
    StoryMarkingMode.tap => L10n.current.storyMarkingTap,
    StoryMarkingMode.scrollPastOrTap =>
      L10n.current.storyMarkingScrollPastOrTap,
    StoryMarkingMode.swipeGestureOnly => L10n.current.storyMarkingSwipeOnly,
  };

  bool get shouldDetectScrollingPast =>
      this == StoryMarkingMode.scrollPast ||
      this == StoryMarkingMode.scrollPastOrTap;

  bool get shouldDetectTapping =>
      this == StoryMarkingMode.tap || this == StoryMarkingMode.scrollPastOrTap;
}
