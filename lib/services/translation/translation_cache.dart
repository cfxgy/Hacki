import 'dart:collection';

/// Small in-memory LRU cache for translated text.
///
/// The key includes the provider fingerprint, source/target languages, and the
/// original text so results from different providers or models never mix.
class TranslationCache {
  static const int maxEntries = 300;

  final LinkedHashMap<String, String> _entries =
      LinkedHashMap<String, String>();

  String? get(String key) {
    final String? value = _entries.remove(key);
    if (value != null) {
      _entries[key] = value;
    }
    return value;
  }

  void put(String key, String value) {
    _entries
      ..remove(key)
      ..[key] = value;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}
