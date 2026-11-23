import 'dart:convert';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart' show IconData, Icons;

/// Names are persisted, so keep them stable when changing labels or icons.
enum ItemMenuAction {
  viewProfile(icon: Icons.account_circle),
  searchOnHackerNews(icon: Icons.search),
  searchInThread(icon: Icons.manage_search),
  reply(icon: Icons.message),
  upvote(icon: Icons.thumb_up_off_alt_outlined),
  downvote(icon: Icons.thumb_down_off_alt_outlined),
  favorite(icon: Icons.favorite_border),
  share(icon: FeatherIcons.share),
  flag(icon: Icons.local_police),
  block(icon: Icons.visibility_off),
  viewInSeparateThread(icon: Icons.list),
  viewInBrowser(icon: Icons.open_in_browser);

  const ItemMenuAction({required this.icon});

  final IconData icon;

  String get description => switch (this) {
    ItemMenuAction.viewProfile => L10n.current.slideActionViewProfile,
    ItemMenuAction.searchOnHackerNews => L10n.current.searchOnHn,
    ItemMenuAction.searchInThread => L10n.current.searchInThread,
    ItemMenuAction.reply => L10n.current.reply,
    ItemMenuAction.upvote => L10n.current.upvote,
    ItemMenuAction.downvote => L10n.current.downvote,
    ItemMenuAction.favorite => L10n.current.favorite,
    ItemMenuAction.share => L10n.current.share,
    ItemMenuAction.flag => L10n.current.flag,
    ItemMenuAction.block => L10n.current.block,
    ItemMenuAction.viewInSeparateThread => L10n.current.viewInSeparateThread,
    ItemMenuAction.viewInBrowser => L10n.current.viewInBrowser,
  };
}

/// Keeps hidden actions in the order so enabling one restores its position.
class ItemMenuConfiguration {
  ItemMenuConfiguration({
    Iterable<ItemMenuAction> order = ItemMenuAction.values,
    Iterable<ItemMenuAction> disabled = const <ItemMenuAction>[],
  }) : order = List<ItemMenuAction>.unmodifiable(<ItemMenuAction>{
         ...order,
         ...ItemMenuAction.values,
       }),
       disabled = Set<ItemMenuAction>.unmodifiable(disabled);

  factory ItemMenuConfiguration.fromString(String value) {
    try {
      final Object? decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        return ItemMenuConfiguration();
      }

      Iterable<ItemMenuAction> readActions(Object? names) {
        if (names is! List<dynamic>) return const <ItemMenuAction>[];

        return names.expand((dynamic name) {
          return ItemMenuAction.values.where(
            (ItemMenuAction action) => action.name == name,
          );
        });
      }

      return ItemMenuConfiguration(
        order: readActions(decoded['order']),
        disabled: readActions(decoded['disabled']),
      );
    } on FormatException {
      return ItemMenuConfiguration();
    }
  }

  final List<ItemMenuAction> order;
  final Set<ItemMenuAction> disabled;

  List<ItemMenuAction> get enabledActions => order
      .where((ItemMenuAction action) => !disabled.contains(action))
      .toList(growable: false);

  ItemMenuConfiguration withOrder(Iterable<ItemMenuAction> order) =>
      ItemMenuConfiguration(order: order, disabled: disabled);

  ItemMenuConfiguration withEnabled(
    ItemMenuAction action, {
    required bool enabled,
  }) {
    final Set<ItemMenuAction> updated = <ItemMenuAction>{...disabled};
    if (enabled) {
      updated.remove(action);
    } else {
      updated.add(action);
    }
    return ItemMenuConfiguration(order: order, disabled: updated);
  }

  String encode() => jsonEncode(<String, List<String>>{
    'order': order.map((ItemMenuAction action) => action.name).toList(),
    'disabled': disabled.map((ItemMenuAction action) => action.name).toList(),
  });
}
