import 'package:hacki/l10n/l10n.dart';

enum HackerNewsDataSource {
  api,
  web;

  String get description => switch (this) {
    HackerNewsDataSource.api => L10n.current.dataSourceApi,
    HackerNewsDataSource.web => L10n.current.dataSourceWeb,
  };
}
