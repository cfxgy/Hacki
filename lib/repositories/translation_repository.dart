import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hacki/models/translation/translation_models.dart';
import 'package:hacki/repositories/preference_repository.dart';
import 'package:hacki/services/translation/azure_translation_provider.dart';
import 'package:hacki/services/translation/openai_translation_provider.dart';
import 'package:hacki/services/translation/translation_cache.dart';

class TranslationRepository {
  TranslationRepository({
    required PreferenceRepository preferenceRepository,
    FlutterSecureStorage? secureStorage,
    TranslationCache? cache,
    Dio? dio,
  }) : _preferenceRepository = preferenceRepository,
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _cache = cache ?? TranslationCache(),
       _dio = dio ?? Dio();

  static const String _settingsKey = 'translationSettings';
  static const String _azureKeyStorageKey = 'translation.azure.apiKey';
  static const String _openAiKeyStorageKey = 'translation.openai.apiKey';
  static const String _azureAckKey = 'translation.dataSharing.azure';
  static const String _openAiAckKey = 'translation.dataSharing.openAi';
  static const String _showOriginalKey = 'translation.showOriginal';

  final PreferenceRepository _preferenceRepository;
  final FlutterSecureStorage _secureStorage;
  final TranslationCache _cache;
  final Dio _dio;

  Future<TranslationSettings> loadSettings() async {
    final String? raw = await _preferenceRepository.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return const TranslationSettings();
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return TranslationSettings.fromJson(decoded);
      }
    } catch (_) {
      // Corrupt settings fall back to defaults; no secret is involved.
    }
    return const TranslationSettings();
  }

  Future<void> saveSettings(TranslationSettings settings) {
    _preferenceRepository.setString(_settingsKey, jsonEncode(settings));
    return Future<void>.value();
  }

  Future<bool> hasAzureKey() async =>
      await _readKey(_azureKeyStorageKey) != null;

  Future<bool> hasOpenAiKey() async =>
      await _readKey(_openAiKeyStorageKey) != null;

  Future<void> saveAzureKey(String key) async {
    final String trimmed = key.trim();
    if (trimmed.isEmpty) return;
    await _secureStorage.write(key: _azureKeyStorageKey, value: trimmed);
  }

  Future<void> saveOpenAiKey(String key) async {
    final String trimmed = key.trim();
    if (trimmed.isEmpty) return;
    await _secureStorage.write(key: _openAiKeyStorageKey, value: trimmed);
  }

  Future<void> clearAzureKey() =>
      _secureStorage.delete(key: _azureKeyStorageKey);

  Future<void> clearOpenAiKey() =>
      _secureStorage.delete(key: _openAiKeyStorageKey);

  Future<bool> isDataSharingAcknowledged(
    TranslationProviderType provider,
  ) async {
    final String key = _ackKey(provider);
    return await _preferenceRepository.getBool(key) ?? false;
  }

  Future<void> acknowledgeDataSharing(TranslationProviderType provider) {
    _preferenceRepository.setBool(_ackKey(provider), true);
    return Future<void>.value();
  }

  Future<Map<String, bool>> loadShowOriginalPreferences() async {
    final String? raw = await _preferenceRepository.getString(_showOriginalKey);
    if (raw == null || raw.isEmpty) return <String, bool>{};
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, bool>{};
      return decoded.map<String, bool>(
        (String key, dynamic value) =>
            MapEntry<String, bool>(key, value == true),
      );
    } catch (_) {
      return <String, bool>{};
    }
  }

  Future<void> saveShowOriginalPreferences(Map<String, bool> preferences) {
    _preferenceRepository.setString(_showOriginalKey, jsonEncode(preferences));
    return Future<void>.value();
  }

  Future<TranslationResult> translate({
    required TranslationProviderType providerType,
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool bypassCache = false,
  }) async {
    final TranslationSettings settings = await loadSettings();
    if (!settings.isEnabled(providerType)) {
      throw const TranslationException(
        TranslationErrorType.invalidConfiguration,
      );
    }

    final TranslationProvider? provider = await _createProvider(
      type: providerType,
      settings: settings,
    );
    if (provider == null) {
      throw const TranslationException(
        TranslationErrorType.invalidConfiguration,
      );
    }

    final String cacheKey = _cacheKey(
      provider: provider,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      text: text,
    );
    if (!bypassCache) {
      final String? cached = _cache.get(cacheKey);
      if (cached != null) {
        return TranslationResult(
          text: cached,
          provider: providerType,
          model: providerType == TranslationProviderType.openAi
              ? settings.openAi.model.trim()
              : '',
          fromCache: true,
        );
      }
    }

    final TranslationResult result = await provider.translate(
      TranslationRequest(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      ),
    );
    _cache.put(cacheKey, result.text);
    return result;
  }

  Future<TranslationResult> testAzure({
    required String region,
    String? apiKey,
  }) async {
    final TranslationSettings settings = await loadSettings();
    final String? key = await _resolveKey(
      override: apiKey,
      storageKey: _azureKeyStorageKey,
    );
    if (key == null) {
      throw const TranslationException(
        TranslationErrorType.invalidConfiguration,
      );
    }
    return AzureTranslationProvider(
      apiKey: key,
      region: region,
      defaultSourceLanguage: settings.sourceLanguage,
      defaultTargetLanguage: settings.targetLanguage,
      dio: _dio,
    ).testConnection();
  }

  Future<TranslationResult> testOpenAi({
    required String baseUrl,
    required String model,
    String? apiKey,
  }) async {
    final TranslationSettings settings = await loadSettings();
    final String? key = await _resolveKey(
      override: apiKey,
      storageKey: _openAiKeyStorageKey,
    );
    if (key == null) {
      throw const TranslationException(
        TranslationErrorType.invalidConfiguration,
      );
    }
    return OpenAiTranslationProvider(
      apiKey: key,
      baseUrl: baseUrl,
      model: model,
      defaultSourceLanguage: settings.sourceLanguage,
      defaultTargetLanguage: settings.targetLanguage,
      dio: _dio,
    ).testConnection();
  }

  Future<TranslationProvider?> _createProvider({
    required TranslationProviderType type,
    required TranslationSettings settings,
  }) async {
    switch (type) {
      case TranslationProviderType.azure:
        if (!settings.azure.isConfigured) return null;
        final String? key = await _readKey(_azureKeyStorageKey);
        if (key == null) return null;
        return AzureTranslationProvider(
          apiKey: key,
          region: settings.azure.region,
          defaultSourceLanguage: settings.sourceLanguage,
          defaultTargetLanguage: settings.targetLanguage,
          dio: _dio,
        );
      case TranslationProviderType.openAi:
        if (!settings.openAi.isConfigured) return null;
        final String? key = await _readKey(_openAiKeyStorageKey);
        if (key == null) return null;
        return OpenAiTranslationProvider(
          apiKey: key,
          baseUrl: settings.openAi.baseUrl,
          model: settings.openAi.model,
          defaultSourceLanguage: settings.sourceLanguage,
          defaultTargetLanguage: settings.targetLanguage,
          dio: _dio,
        );
    }
  }

  String _cacheKey({
    required TranslationProvider provider,
    required String sourceLanguage,
    required String targetLanguage,
    required String text,
  }) => jsonEncode(<String>[
    provider.type.name,
    provider.configurationFingerprint,
    sourceLanguage,
    targetLanguage,
    text,
  ]);

  Future<String?> _resolveKey({
    required String? override,
    required String storageKey,
  }) async {
    final String trimmed = override?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return _readKey(storageKey);
  }

  Future<String?> _readKey(String key) async {
    try {
      final String? value = await _secureStorage.read(key: key);
      if (value == null || value.trim().isEmpty) return null;
      return value;
    } catch (_) {
      return null;
    }
  }

  String _ackKey(TranslationProviderType provider) => switch (provider) {
    TranslationProviderType.azure => _azureAckKey,
    TranslationProviderType.openAi => _openAiAckKey,
  };
}
