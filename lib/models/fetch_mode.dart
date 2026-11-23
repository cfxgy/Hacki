import 'package:hacki/l10n/l10n.dart';

enum FetchMode {
  lazy,
  eager;

  String get description => switch (this) {
    FetchMode.lazy => L10n.current.fetchModeLazy,
    FetchMode.eager => L10n.current.fetchModeEager,
  };

  @override
  String toString() => description;
}
