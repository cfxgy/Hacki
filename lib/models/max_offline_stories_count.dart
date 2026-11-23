import 'package:hacki/l10n/l10n.dart';

enum MaxOfflineStoriesCount {
  ten(20),
  fifty(50),
  hundred(100),
  twoHundred(200),
  all(null);

  const MaxOfflineStoriesCount(this.count);

  final int? count;

  String get label => count?.toString() ?? L10n.current.maxStoriesAll;
}
