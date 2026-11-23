import 'package:hacki/l10n/l10n.dart';

enum CommentsOrder {
  natural,
  newestFirst,
  oldestFirst;

  String get description => switch (this) {
    CommentsOrder.natural => L10n.current.commentsOrderNatural,
    CommentsOrder.newestFirst => L10n.current.commentsOrderNewestFirst,
    CommentsOrder.oldestFirst => L10n.current.commentsOrderOldestFirst,
  };

  @override
  String toString() => description;
}
