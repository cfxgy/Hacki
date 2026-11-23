import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/translation/translation_state.dart';
import 'package:hacki/models/translation/translation_models.dart';
import 'package:hacki/repositories/translation_repository.dart';

class TranslationCubit extends Cubit<TranslationState> {
  TranslationCubit({required TranslationRepository repository})
    : _repository = repository,
      super(const TranslationState());

  static const int _maxConcurrent = 2;
  static const int _maxQueue = 40;
  static const int _maxRetries = 2;

  final TranslationRepository _repository;
  final List<_TranslationJob> _queue = <_TranslationJob>[];
  final Set<String> _pendingKeys = <String>{};
  int _activeRequests = 0;

  Future<void> init() async {
    final TranslationSettings settings = await _repository.loadSettings();
    final bool hasAzureKey = await _repository.hasAzureKey();
    final bool hasOpenAiKey = await _repository.hasOpenAiKey();
    final Map<String, bool> originalPreferences = await _repository
        .loadShowOriginalPreferences();
    final bool azureAck = await _repository.isDataSharingAcknowledged(
      TranslationProviderType.azure,
    );
    final bool openAiAck = await _repository.isDataSharingAcknowledged(
      TranslationProviderType.openAi,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        settings: settings,
        hasAzureKey: hasAzureKey,
        hasOpenAiKey: hasOpenAiKey,
        originalPreferences: originalPreferences,
        azureDataSharingAcknowledged: azureAck,
        openAiDataSharingAcknowledged: openAiAck,
        isLoadingSettings: false,
      ),
    );
  }

  Future<void> saveSettings(TranslationSettings settings) async {
    await _repository.saveSettings(settings);
    if (isClosed) return;
    emit(state.copyWith(settings: settings));
  }

  Future<void> saveAzureKey(String key) async {
    await _repository.saveAzureKey(key);
    if (isClosed) return;
    emit(state.copyWith(hasAzureKey: true));
  }

  Future<void> saveOpenAiKey(String key) async {
    await _repository.saveOpenAiKey(key);
    if (isClosed) return;
    emit(state.copyWith(hasOpenAiKey: true));
  }

  Future<void> clearAzureKey() async {
    await _repository.clearAzureKey();
    if (isClosed) return;
    emit(state.copyWith(hasAzureKey: false));
  }

  Future<void> clearOpenAiKey() async {
    await _repository.clearOpenAiKey();
    if (isClosed) return;
    emit(state.copyWith(hasOpenAiKey: false));
  }

  Future<void> acknowledgeDataSharing(
    TranslationProviderType provider,
  ) async {
    await _repository.acknowledgeDataSharing(provider);
    if (isClosed) return;
    emit(
      switch (provider) {
        TranslationProviderType.azure => state.copyWith(
          azureDataSharingAcknowledged: true,
        ),
        TranslationProviderType.openAi => state.copyWith(
          openAiDataSharingAcknowledged: true,
        ),
      },
    );
  }

  /// Enqueues an automatic translation. The queue is bounded and only two
  /// requests run at a time so opening a large thread cannot flood a provider.
  void queueAutoTranslate({required String key, required String text}) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty || !state.canAutoTranslate) return;
    final TranslationEntry? existing = state.entries[key];
    if (existing != null &&
        (existing.status == TranslationEntryStatus.success ||
            existing.status == TranslationEntryStatus.loading ||
            existing.status == TranslationEntryStatus.queued ||
            existing.status == TranslationEntryStatus.failure)) {
      return;
    }
    if (_pendingKeys.contains(key) || _queue.length >= _maxQueue) return;

    _pendingKeys.add(key);
    final Map<String, TranslationEntry> entries =
        Map<String, TranslationEntry>.of(state.entries);
    entries[key] = TranslationEntry(
      original: trimmed,
      showOriginal: _prefersOriginal(key),
      status: TranslationEntryStatus.queued,
    );
    emit(state.copyWith(entries: entries));
    _queue.add(_TranslationJob(key: key, text: trimmed));
    _drainQueue();
  }

  Future<TranslationResult> translate({
    required String key,
    required String text,
  }) async {
    final TranslationEntry? previous = state.entries[key];
    if (previous?.status == TranslationEntryStatus.loading ||
        previous?.status == TranslationEntryStatus.queued) {
      throw const TranslationException(TranslationErrorType.unknown);
    }

    final Map<String, TranslationEntry> entries =
        Map<String, TranslationEntry>.of(state.entries);
    entries[key] = TranslationEntry(
      original: text,
      translated: previous?.translated,
      showOriginal: _prefersOriginal(key),
      status: TranslationEntryStatus.loading,
    );
    emit(state.copyWith(entries: entries));

    try {
      final TranslationResult result = await _repository.translate(
        providerType: state.settings.defaultProvider,
        text: text,
        sourceLanguage: state.settings.sourceLanguage,
        targetLanguage: state.settings.targetLanguage,
      );
      if (isClosed) return result;
      final Map<String, TranslationEntry> updated =
          Map<String, TranslationEntry>.of(state.entries);
      updated[key] = TranslationEntry(
        original: text,
        translated: result.text,
        showOriginal: _prefersOriginal(key),
        status: TranslationEntryStatus.success,
      );
      emit(state.copyWith(entries: updated));
      return result;
    } on TranslationException catch (error) {
      _markFailure(key, text, error.type);
      rethrow;
    } catch (_) {
      _markFailure(key, text, TranslationErrorType.unknown);
      throw const TranslationException(TranslationErrorType.unknown);
    }
  }

  void toggle(String key) {
    final TranslationEntry? entry = state.entries[key];
    if (entry == null || !entry.hasTranslation) return;
    final bool showOriginal = !entry.showOriginal;
    final Map<String, TranslationEntry> entries =
        Map<String, TranslationEntry>.of(state.entries);
    final Map<String, bool> preferences =
        Map<String, bool>.of(state.originalPreferences);
    entries[key] = entry.copyWith(showOriginal: showOriginal);
    preferences[key] = showOriginal;
    emit(
      state.copyWith(
        entries: entries,
        originalPreferences: preferences,
      ),
    );
    unawaited(_repository.saveShowOriginalPreferences(preferences));
  }

  void setAll({
    required bool showOriginal,
    required Iterable<String> keys,
  }) {
    final Map<String, TranslationEntry> entries =
        Map<String, TranslationEntry>.of(state.entries);
    final Map<String, bool> preferences =
        Map<String, bool>.of(state.originalPreferences);
    for (final String key in keys) {
      final TranslationEntry? entry = entries[key];
      if (entry == null || !entry.hasTranslation) continue;
      entries[key] = entry.copyWith(showOriginal: showOriginal);
      preferences[key] = showOriginal;
    }
    emit(
      state.copyWith(
        entries: entries,
        originalPreferences: preferences,
      ),
    );
    unawaited(_repository.saveShowOriginalPreferences(preferences));
  }

  Future<TranslationResult> testAzure({
    required String region,
    String? apiKey,
  }) => _repository.testAzure(region: region, apiKey: apiKey);

  Future<TranslationResult> testOpenAi({
    required String baseUrl,
    required String model,
    String? apiKey,
  }) => _repository.testOpenAi(baseUrl: baseUrl, model: model, apiKey: apiKey);

  void _drainQueue() {
    while (_activeRequests < _maxConcurrent && _queue.isNotEmpty) {
      final _TranslationJob job = _queue.removeAt(0);
      _activeRequests++;
      unawaited(
        _runJob(job).whenComplete(() {
          _activeRequests--;
          _pendingKeys.remove(job.key);
          _drainQueue();
        }),
      );
    }
  }

  Future<void> _runJob(_TranslationJob job) async {
    _setEntryStatus(job.key, job.text, TranslationEntryStatus.loading);
    try {
      final TranslationResult result = await _repository.translate(
        providerType: state.settings.defaultProvider,
        text: job.text,
        sourceLanguage: state.settings.sourceLanguage,
        targetLanguage: state.settings.targetLanguage,
      );
      if (isClosed) return;
      final Map<String, TranslationEntry> entries =
          Map<String, TranslationEntry>.of(state.entries);
      entries[job.key] = TranslationEntry(
        original: job.text,
        translated: result.text,
        showOriginal: _prefersOriginal(job.key),
        status: TranslationEntryStatus.success,
      );
      emit(state.copyWith(entries: entries));
    } on TranslationException catch (error) {
      if (_shouldRetry(error.type) && job.attempt < _maxRetries) {
        await Future<void>.delayed(
          Duration(milliseconds: 600 * (job.attempt + 1)),
        );
        if (isClosed) return;
        _queue.insert(0, job.copyWith(attempt: job.attempt + 1));
        return;
      }
      _markFailure(job.key, job.text, error.type);
    } catch (_) {
      _markFailure(job.key, job.text, TranslationErrorType.unknown);
    }
  }

  bool _shouldRetry(TranslationErrorType type) => switch (type) {
    TranslationErrorType.network ||
    TranslationErrorType.server ||
    TranslationErrorType.rateLimited => true,
    _ => false,
  };

  void _setEntryStatus(
    String key,
    String text,
    TranslationEntryStatus status,
  ) {
    if (isClosed) return;
    final Map<String, TranslationEntry> entries =
        Map<String, TranslationEntry>.of(state.entries);
    final TranslationEntry? previous = entries[key];
    entries[key] = TranslationEntry(
      original: text,
      translated: previous?.translated,
      showOriginal: _prefersOriginal(key),
      status: status,
    );
    emit(state.copyWith(entries: entries));
  }

  void _markFailure(
    String key,
    String text,
    TranslationErrorType errorType,
  ) {
    if (isClosed) return;
    final Map<String, TranslationEntry> entries =
        Map<String, TranslationEntry>.of(state.entries);
    entries[key] = TranslationEntry(
      original: text,
      showOriginal: true,
      status: TranslationEntryStatus.failure,
      errorType: errorType,
    );
    emit(state.copyWith(entries: entries));
  }

  bool _prefersOriginal(String key) =>
      state.originalPreferences[key] ?? false;
}

class _TranslationJob {
  const _TranslationJob({
    required this.key,
    required this.text,
    this.attempt = 0,
  });

  final String key;
  final String text;
  final int attempt;

  _TranslationJob copyWith({int? attempt}) =>
      _TranslationJob(key: key, text: text, attempt: attempt ?? this.attempt);
}
