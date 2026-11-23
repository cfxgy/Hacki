import 'package:hacki/l10n/l10n.dart';

enum StoryType {
  top('topstories', ''),
  best('beststories', 'best'),
  latest('newstories', 'newest'),
  ask('askstories', 'ask'),
  show('showstories', 'show');

  const StoryType(this.apiPathParam, this.webPathParam);

  /// The path param used in the official Hacker News API.
  /// e.g. https://hacker-news.firebaseio.com/v0/{apiPathParam}.json
  final String apiPathParam;

  /// The path param used in the HN web.
  /// e.g. https://news.ycombinator.com/{webPathParam}
  final String webPathParam;

  String get label => switch (this) {
    StoryType.top => L10n.current.storyTypeTop,
    StoryType.best => L10n.current.storyTypeBest,
    StoryType.latest => L10n.current.storyTypeLatest,
    StoryType.ask => L10n.current.storyTypeAsk,
    StoryType.show => L10n.current.storyTypeShow,
  };

  static int convertToSettingsValue(List<StoryType> tabs) {
    return int.parse(
      tabs
          .map((StoryType e) => e.index.toString())
          .reduce((String value, String element) => '$value$element'),
    );
  }
}
