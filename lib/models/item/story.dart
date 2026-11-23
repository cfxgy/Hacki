import 'package:hacki/config/constants.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/models/item/item.dart';

class Story extends Item {
  const Story({
    required super.descendants,
    required super.id,
    required super.score,
    required super.time,
    required super.by,
    required super.title,
    required super.type,
    required super.url,
    required super.text,
    required super.kids,
    required super.parts,
    required super.hidden,
  }) : super(dead: false, deleted: false, parent: 0);

  Story.empty() : super.empty();

  Story.placeholder()
    : super(
        id: 0,
        score: 0,
        descendants: 0,
        time: 1171872000,
        by: 'Y Combinator',
        title: 'Hacker News Guidelines',
        url: Constants.guidelineLink,
        kids: <int>[],
        dead: false,
        parts: <int>[],
        deleted: false,
        parent: 0,
        text: '',
        type: '',
        hidden: false,
      );

  Story.fromJson(super.json) : super.fromJson();

  Story copyWith({bool? hidden}) {
    return Story(
      descendants: descendants,
      id: id,
      score: score,
      time: time,
      by: by,
      title: title,
      type: type,
      url: url,
      text: text,
      kids: kids,
      parts: parts,
      hidden: hidden ?? this.hidden,
    );
  }

  String get metadata => L10n.current.storyMetadata(
    L10n.current.pointsCount(score),
    L10n.current.commentsCount(descendants),
    by.isNotEmpty ? by : '',
    shortTimeAgo,
  );

  String get metadataWithShortTimeAgoString => metadata;

  String get screenReaderLabel => L10n.current.storyScreenReader(
    title,
    readableUrl,
    by,
    timeAgo,
    L10n.current.pointsCount(score),
    L10n.current.commentsCount(descendants),
  );

  String get simpleMetadata => L10n.current.storySimpleMetadata(
    L10n.current.pointsCount(score),
    L10n.current.commentsCount(descendants),
    timeAgo,
  );

  String get readableUrl {
    final Uri url = Uri.parse(this.url);
    final String authority = url.authority.replaceFirst('www.', '');
    return authority;
  }

  @override
  String toString() => 'Story $id';
}
