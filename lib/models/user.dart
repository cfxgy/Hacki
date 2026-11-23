import 'package:equatable/equatable.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:intl/intl.dart';

class User extends Equatable {
  const User({
    required this.about,
    required this.created,
    required this.delay,
    required this.id,
    required this.karma,
  });

  const User.empty() : about = '', created = 0, delay = 0, id = '', karma = 0;

  const User.emptyWithId(this.id)
    : about = '',
      created = 0,
      delay = 0,
      karma = 0;

  User.fromJson(Map<String, dynamic> json)
    : about = json['about'] as String? ?? '',
      created = json['created'] as int? ?? 0,
      delay = json['delay'] as int? ?? 0,
      id = json['id'] as String? ?? '',
      karma = json['karma'] as int? ?? 0;

  final String about;
  final int created;
  final int delay;
  final String id;
  final int karma;

  String get description {
    final DateFormat formatter = DateFormat.yMMMd(L10n.current.localeName);
    final String date = formatter.format(
      DateTime.fromMillisecondsSinceEpoch(created * 1000),
    );
    return L10n.current.userKarmaCreated(L10n.formatNumber(karma), date);
  }

  @override
  String toString() {
    return 'User $about, $created, $delay, $id, $karma';
  }

  @override
  List<Object?> get props => <Object?>[about, created, delay, id, karma];
}
