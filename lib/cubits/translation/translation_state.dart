import 'package:equatable/equatable.dart';
import 'package:hacki/models/translation/translation_models.dart';

enum TranslationEntryStatus { idle, queued, loading, success, failure }

class TranslationEntry extends Equatable {
  const TranslationEntry({
    required this.original,
    this.translated,
    this.showOriginal = true,
    this.status = TranslationEntryStatus.idle,
    this.errorType,
  });

  final String original;
  final String? translated;
  final bool showOriginal;
  final TranslationEntryStatus status;
  final TranslationErrorType? errorType;

  bool get hasTranslation =>
      translated != null && translated!.trim().isNotEmpty;

  TranslationEntry copyWith({
    String? translated,
    bool? showOriginal,
    TranslationEntryStatus? status,
    TranslationErrorType? errorType,
    bool clearError = false,
  }) => TranslationEntry(
    original: original,
    translated: translated ?? this.translated,
    showOriginal: showOriginal ?? this.showOriginal,
    status: status ?? this.status,
    errorType: clearError ? null : errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => <Object?>[
    original,
    translated,
    showOriginal,
    status,
    errorType,
  ];
}

class TranslationState extends Equatable {
  const TranslationState({
    this.settings = const TranslationSettings(),
    this.isLoadingSettings = true,
    this.hasAzureKey = false,
    this.hasOpenAiKey = false,
    this.entries = const <String, TranslationEntry>{},
    this.originalPreferences = const <String, bool>{},
    this.azureDataSharingAcknowledged = false,
    this.openAiDataSharingAcknowledged = false,
  });

  final TranslationSettings settings;
  final bool isLoadingSettings;
  final bool hasAzureKey;
  final bool hasOpenAiKey;
  final Map<String, TranslationEntry> entries;
  final Map<String, bool> originalPreferences;
  final bool azureDataSharingAcknowledged;
  final bool openAiDataSharingAcknowledged;

  TranslationEntry? entryFor(String key) => entries[key];

  String displayText(String key, String original) {
    final TranslationEntry? entry = entries[key];
    if (entry == null || !entry.hasTranslation || entry.showOriginal) {
      return original;
    }
    return entry.translated!;
  }

  bool isShowingTranslation(String key) {
    final TranslationEntry? entry = entries[key];
    return entry != null && entry.hasTranslation && !entry.showOriginal;
  }

  bool isAcknowledged(TranslationProviderType provider) => switch (provider) {
    TranslationProviderType.azure => azureDataSharingAcknowledged,
    TranslationProviderType.openAi => openAiDataSharingAcknowledged,
  };

  bool get isDefaultProviderConfigured {
    final TranslationProviderType provider = settings.defaultProvider;
    if (!settings.isEnabled(provider)) return false;
    return switch (provider) {
      TranslationProviderType.azure =>
        settings.azure.isConfigured && hasAzureKey,
      TranslationProviderType.openAi =>
        settings.openAi.isConfigured && hasOpenAiKey,
    };
  }

  bool get canAutoTranslate =>
      settings.autoTranslate &&
      isDefaultProviderConfigured &&
      isAcknowledged(settings.defaultProvider);

  TranslationState copyWith({
    TranslationSettings? settings,
    bool? isLoadingSettings,
    bool? hasAzureKey,
    bool? hasOpenAiKey,
    Map<String, TranslationEntry>? entries,
    Map<String, bool>? originalPreferences,
    bool? azureDataSharingAcknowledged,
    bool? openAiDataSharingAcknowledged,
  }) => TranslationState(
    settings: settings ?? this.settings,
    isLoadingSettings: isLoadingSettings ?? this.isLoadingSettings,
    hasAzureKey: hasAzureKey ?? this.hasAzureKey,
    hasOpenAiKey: hasOpenAiKey ?? this.hasOpenAiKey,
    entries: entries ?? this.entries,
    originalPreferences: originalPreferences ?? this.originalPreferences,
    azureDataSharingAcknowledged:
        azureDataSharingAcknowledged ?? this.azureDataSharingAcknowledged,
    openAiDataSharingAcknowledged:
        openAiDataSharingAcknowledged ?? this.openAiDataSharingAcknowledged,
  );

  @override
  List<Object?> get props => <Object?>[
    settings,
    isLoadingSettings,
    hasAzureKey,
    hasOpenAiKey,
    entries,
    originalPreferences,
    azureDataSharingAcknowledged,
    openAiDataSharingAcknowledged,
  ];
}
