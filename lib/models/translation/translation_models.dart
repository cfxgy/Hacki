import 'package:equatable/equatable.dart';
import 'package:hacki/l10n/l10n.dart';

/// Identifies which cloud service produced a translation.
enum TranslationProviderType { azure, openAi }

/// Why a translation request failed. UI code maps this to localized text.
enum TranslationErrorType {
  invalidConfiguration,
  authentication,
  permission,
  rateLimited,
  network,
  server,
  parsing,
  contentRejected,
  unknown,
}

class TranslationException implements Exception {
  const TranslationException(
    this.type, {
    this.statusCode,
    this.technicalMessage,
  });

  final TranslationErrorType type;
  final int? statusCode;
  final String? technicalMessage;

  String get localizedMessage => switch (type) {
    TranslationErrorType.invalidConfiguration =>
      L10n.current.translationErrorConfiguration,
    TranslationErrorType.authentication =>
      L10n.current.translationErrorAuthentication,
    TranslationErrorType.permission => L10n.current.translationErrorPermission,
    TranslationErrorType.rateLimited =>
      L10n.current.translationErrorRateLimited,
    TranslationErrorType.network => L10n.current.translationErrorNetwork,
    TranslationErrorType.server => L10n.current.translationErrorServer,
    TranslationErrorType.parsing => L10n.current.translationErrorParsing,
    TranslationErrorType.contentRejected =>
      L10n.current.translationErrorContent,
    TranslationErrorType.unknown => L10n.current.translationErrorUnknown,
  };

  @override
  String toString() => 'TranslationException($type, status: $statusCode)';
}

class AzureTranslationConfig extends Equatable {
  const AzureTranslationConfig({this.enabled = false, this.region = ''});

  final bool enabled;
  final String region;

  bool get isConfigured => enabled && region.trim().isNotEmpty;

  AzureTranslationConfig copyWith({bool? enabled, String? region}) =>
      AzureTranslationConfig(
        enabled: enabled ?? this.enabled,
        region: region ?? this.region,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enabled': enabled,
    'region': region,
  };

  factory AzureTranslationConfig.fromJson(Map<String, dynamic> json) =>
      AzureTranslationConfig(
        enabled: json['enabled'] as bool? ?? false,
        region: json['region'] as String? ?? '',
      );

  @override
  List<Object?> get props => <Object?>[enabled, region];
}

class OpenAiTranslationConfig extends Equatable {
  const OpenAiTranslationConfig({
    this.enabled = false,
    this.baseUrl = '',
    this.model = '',
  });

  final bool enabled;
  final String baseUrl;
  final String model;

  bool get isConfigured =>
      enabled && baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  OpenAiTranslationConfig copyWith({
    bool? enabled,
    String? baseUrl,
    String? model,
  }) => OpenAiTranslationConfig(
    enabled: enabled ?? this.enabled,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enabled': enabled,
    'baseUrl': baseUrl,
    'model': model,
  };

  factory OpenAiTranslationConfig.fromJson(Map<String, dynamic> json) =>
      OpenAiTranslationConfig(
        enabled: json['enabled'] as bool? ?? false,
        baseUrl: json['baseUrl'] as String? ?? '',
        model: json['model'] as String? ?? '',
      );

  @override
  List<Object?> get props => <Object?>[enabled, baseUrl, model];
}

class TranslationSettings extends Equatable {
  const TranslationSettings({
    this.defaultProvider = TranslationProviderType.azure,
    this.sourceLanguage = sourceAuto,
    this.targetLanguage = targetSimplifiedChinese,
    this.azure = const AzureTranslationConfig(),
    this.openAi = const OpenAiTranslationConfig(),
  });

  static const String sourceAuto = 'auto';
  static const String sourceEnglish = 'en';
  static const String sourceSimplifiedChinese = 'zh-Hans';
  static const String targetSimplifiedChinese = 'zh-Hans';
  static const String targetEnglish = 'en';

  final TranslationProviderType defaultProvider;
  final String sourceLanguage;
  final String targetLanguage;
  final AzureTranslationConfig azure;
  final OpenAiTranslationConfig openAi;

  bool isEnabled(TranslationProviderType provider) => switch (provider) {
    TranslationProviderType.azure => azure.enabled,
    TranslationProviderType.openAi => openAi.enabled,
  };

  bool hasConfiguration(TranslationProviderType provider) =>
      switch (provider) {
        TranslationProviderType.azure => azure.isConfigured,
        TranslationProviderType.openAi => openAi.isConfigured,
      };

  TranslationSettings copyWith({
    TranslationProviderType? defaultProvider,
    String? sourceLanguage,
    String? targetLanguage,
    AzureTranslationConfig? azure,
    OpenAiTranslationConfig? openAi,
  }) => TranslationSettings(
    defaultProvider: defaultProvider ?? this.defaultProvider,
    sourceLanguage: sourceLanguage ?? this.sourceLanguage,
    targetLanguage: targetLanguage ?? this.targetLanguage,
    azure: azure ?? this.azure,
    openAi: openAi ?? this.openAi,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'defaultProvider': defaultProvider.name,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'azure': azure.toJson(),
    'openAi': openAi.toJson(),
  };

  factory TranslationSettings.fromJson(Map<String, dynamic> json) {
    final String provider = json['defaultProvider'] as String? ?? 'azure';
    return TranslationSettings(
      defaultProvider: TranslationProviderType.values.firstWhere(
        (TranslationProviderType value) => value.name == provider,
        orElse: () => TranslationProviderType.azure,
      ),
      sourceLanguage: json['sourceLanguage'] as String? ?? sourceAuto,
      targetLanguage:
          json['targetLanguage'] as String? ?? targetSimplifiedChinese,
      azure: AzureTranslationConfig.fromJson(
        (json['azure'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      openAi: OpenAiTranslationConfig.fromJson(
        (json['openAi'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    defaultProvider,
    sourceLanguage,
    targetLanguage,
    azure,
    openAi,
  ];
}

class TranslationRequest extends Equatable {
  const TranslationRequest({
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final String text;
  final String sourceLanguage;
  final String targetLanguage;

  @override
  List<Object?> get props => <Object?>[text, sourceLanguage, targetLanguage];
}

class TranslationResult extends Equatable {
  const TranslationResult({
    required this.text,
    required this.provider,
    this.model = '',
    this.detectedSourceLanguage = '',
    this.fromCache = false,
  });

  final String text;
  final TranslationProviderType provider;
  final String model;
  final String detectedSourceLanguage;
  final bool fromCache;

  @override
  List<Object?> get props => <Object?>[
    text,
    provider,
    model,
    detectedSourceLanguage,
    fromCache,
  ];
}

/// A provider is a pure translation client. It never falls back to another
/// provider; callers decide which provider to use and surface failures.
abstract interface class TranslationProvider {
  TranslationProviderType get type;

  /// A stable, non-secret description used in the translation cache key.
  String get configurationFingerprint;

  Future<TranslationResult> translate(TranslationRequest request);

  /// Performs a real request against the remote service.
  Future<TranslationResult> testConnection();
}
