import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/translation/translation_state.dart';
import 'package:hacki/models/translation/translation_models.dart';
import 'package:hacki/repositories/translation_repository.dart';

class TranslationCubit extends Cubit<TranslationState> {
  TranslationCubit({required TranslationRepository repository})
    : _repository = repository,
      super(const TranslationState());

  final TranslationRepository _repository;

  Future<void> init() async {
    final TranslationSettings settings = await _repository.loadSettings();
    final bool hasAzureKey = await _repository.hasAzureKey();
    final bool hasOpenAiKey = await _repository.hasOpenAiKey();
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

  Future<void> acknowledgeDataSharing(TranslationProviderType provider) async {
    await _repository.acknowledgeDataSharing(provider);
    if (isClosed) return;
    emit(switch (provider) {
      TranslationProviderType.azure => state.copyWith(
        azureDataSharingAcknowledged: true,
      ),
      TranslationProviderType.openAi => state.copyWith(
        openAiDataSharingAcknowledged: true,
      ),
    });
  }

  Future<TranslationResult> translate({
    required String key,
    required String text,
  }) async {
    final TranslationEntry? previous = state.entries[key];
    if (previous?.status == TranslationEntryStatus.loading) {
      throw const TranslationException(TranslationErrorType.unknown);
    }

    final Map<String, TranslationEntry> entries =
        Map<String, TranslationEntry>.of(state.entries);
    entries[key] = TranslationEntry(
      original: text,
      translated: previous?.translated,
      showOriginal: previous?.showOriginal ?? true,
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
        showOriginal: false,
        status: TranslationEntryStatus.success,
      );
      emit(state.copyWith(entries: updated));
      return result;
    } on TranslationException catch (error) {
      if (!isClosed) {
        final Map<String, TranslationEntry> updated =
            Map<String, TranslationEntry>.of(state.entries);
        updated[key] = TranslationEntry(
          original: text,
          translated: previous?.translated,
          showOriginal: previous?.showOriginal ?? true,
          status: TranslationEntryStatus.failure,
          errorType: error.type,
        );
        emit(state.copyWith(entries: updated));
      }
      rethrow;
    } catch (_) {
      if (!isClosed) {
        final Map<String, TranslationEntry> updated =
            Map<String, TranslationEntry>.of(state.entries);
        updated[key] = TranslationEntry(
          original: text,
          translated: previous?.translated,
          showOriginal: previous?.showOriginal ?? true,
          status: TranslationEntryStatus.failure,
          errorType: TranslationErrorType.unknown,
        );
        emit(state.copyWith(entries: updated));
      }
      throw const TranslationException(TranslationErrorType.unknown);
    }
  }

  void toggle(String key) {
    final TranslationEntry? entry = state.entries[key];
    if (entry == null || !entry.hasTranslation) return;
    final Map<String, TranslationEntry> entries =
        Map<String, TranslationEntry>.of(state.entries);
    entries[key] = entry.copyWith(showOriginal: !entry.showOriginal);
    emit(state.copyWith(entries: entries));
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
}
