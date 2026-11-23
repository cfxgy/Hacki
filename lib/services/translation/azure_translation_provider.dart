import 'package:dio/dio.dart';
import 'package:hacki/models/translation/translation_models.dart';
import 'package:hacki/services/translation/translation_error_mapper.dart';

class AzureTranslationProvider implements TranslationProvider {
  AzureTranslationProvider({
    required this.apiKey,
    required this.region,
    required this.defaultSourceLanguage,
    required this.defaultTargetLanguage,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String apiKey;
  final String region;
  final String defaultSourceLanguage;
  final String defaultTargetLanguage;
  final Dio _dio;

  static const String _host = 'api.cognitive.microsofttranslator.com';

  @override
  TranslationProviderType get type => TranslationProviderType.azure;

  @override
  String get configurationFingerprint => 'azure:${region.trim()}';

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    if (apiKey.trim().isEmpty || region.trim().isEmpty) {
      throw const TranslationException(
        TranslationErrorType.invalidConfiguration,
      );
    }

    final Map<String, String> query = <String, String>{
      'api-version': '3.0',
      'to': request.targetLanguage,
      if (request.sourceLanguage !=
          TranslationSettings.sourceAuto) ...<String, String>{
        'from': request.sourceLanguage,
      },
    };

    try {
      final Response<dynamic> response = await _dio.postUri(
        Uri.https(_host, '/translate', query),
        data: <Map<String, String>>[
          <String, String>{'Text': request.text},
        ],
        options: Options(
          headers: <String, String>{
            'Ocp-Apim-Subscription-Key': apiKey.trim(),
            'Ocp-Apim-Subscription-Region': region.trim(),
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
        ),
      );

      final dynamic data = response.data;
      if (data is! List<dynamic> || data.isEmpty) {
        throw const TranslationException(TranslationErrorType.parsing);
      }
      final Map<String, dynamic> item = data.first as Map<String, dynamic>;
      final List<dynamic> translations =
          item['translations'] as List<dynamic>? ?? <dynamic>[];
      if (translations.isEmpty) {
        throw const TranslationException(TranslationErrorType.parsing);
      }
      final Map<String, dynamic> first =
          translations.first as Map<String, dynamic>;
      final String? text = first['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw const TranslationException(TranslationErrorType.parsing);
      }
      final Map<String, dynamic>? detected =
          item['detectedLanguage'] as Map<String, dynamic>?;
      return TranslationResult(
        text: text,
        provider: TranslationProviderType.azure,
        detectedSourceLanguage: detected?['language'] as String? ?? '',
      );
    } catch (error) {
      throw mapTranslationHttpError(error);
    }
  }

  @override
  Future<TranslationResult> testConnection() => translate(
    TranslationRequest(
      text: defaultTargetLanguage == TranslationSettings.targetEnglish
          ? '你好'
          : 'Hello',
      sourceLanguage: defaultSourceLanguage,
      targetLanguage: defaultTargetLanguage,
    ),
  );
}
