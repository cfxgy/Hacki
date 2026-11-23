import 'package:hacki/l10n/l10n.dart';

enum DiscoverableFeature {
  addStoryToFavList(featureId: 'add_story_to_fav_list'),
  settingsShortcutOnItemScreen(featureId: 'settings_shortcut_on_item_screen'),
  login(featureId: 'log_in'),
  pinToTop(featureId: 'pin_to_top'),
  jumpUpButton(featureId: 'jump_up_button_with_long_press'),
  jumpDownButton(featureId: 'jump_down_button_with_long_press'),
  searchInThread(featureId: 'search_in_thread');

  const DiscoverableFeature({required this.featureId});

  /// Feature ids for feature discovery.
  final String featureId;

  String get title => switch (this) {
    DiscoverableFeature.addStoryToFavList => L10n.current.featureFavTitle,
    DiscoverableFeature.settingsShortcutOnItemScreen =>
      L10n.current.featureSettingsTitle,
    DiscoverableFeature.login => L10n.current.featureLoginTitle,
    DiscoverableFeature.pinToTop => L10n.current.featurePinTitle,
    DiscoverableFeature.jumpUpButton ||
    DiscoverableFeature.jumpDownButton => L10n.current.featureShortcutTitle,
    DiscoverableFeature.searchInThread => L10n.current.featureSearchTitle,
  };

  String get description => switch (this) {
    DiscoverableFeature.addStoryToFavList => L10n.current.featureFavBody,
    DiscoverableFeature.settingsShortcutOnItemScreen =>
      L10n.current.featureSettingsBody,
    DiscoverableFeature.login => L10n.current.featureLoginBody,
    DiscoverableFeature.pinToTop => L10n.current.featurePinBody,
    DiscoverableFeature.jumpUpButton => L10n.current.featureJumpUpBody,
    DiscoverableFeature.jumpDownButton => L10n.current.featureJumpDownBody,
    DiscoverableFeature.searchInThread => L10n.current.featureSearchBody,
  };
}
