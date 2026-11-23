import 'package:dio/dio.dart';
import 'package:hacki/models/translation/translation_models.dart';
import 'package:hacki/services/translation/translation_error_mapper.dart';

class OpenAiTranslationProvider implements TranslationProvider {
  OpenAiTranslationProvider({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    required this.defaultSourceLanguage,
    required this.defaultTargetLanguage,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String apiKey;
  final String baseUrl;
  final String model;
  final String defaultSourceLanguage;
  final String defaultTargetLanguage;
  final Dio _dio;

  @override
  TranslationProviderType get type => TranslationProviderType.openAi;

  @override
  String get configurationFingerprint =>
      'openai:${baseUrl.trim()}:${model.trim()}';

  Uri get _endpoint {
    final Uri base = Uri.parse(baseUrl.trim());
    if (base.scheme != 'https' && base.scheme != 'http') {
      throw const TranslationException(
        TranslationErrorType.invalidConfiguration,
      );
    }
    if (base.host.isEmpty) {
      throw const TranslationException(
        TranslationErrorType.invalidConfiguration,
      );
    }
    final String path = base.path.replaceFirst(RegExp(r'/+$'), '');
    return base.replace(
      path: path.endsWith('/chat/completions')
          ? path
          : '$path/chat/completions',
    );
  }

  @override
  Future<TranslationResult> translate(TranslationRequest request) async {
    if (apiKey.trim().isEmpty ||
        baseUrl.trim().isEmpty ||
        model.trim().isEmpty) {
      throw const TranslationException(
        TranslationErrorType.invalidConfiguration,
      );
    }

    final String source =
        request.sourceLanguage == TranslationSettings.sourceAuto
        ? 'the detected source language'
        : _languageName(request.sourceLanguage);
    final String target = _languageName(request.targetLanguage);

    try {
      final Response<dynamic> response = await _dio.postUri(
        _endpoint,
        data: <String, dynamic>{
          'model': model.trim(),
          'messages': <Map<String, String>>[
            <String, String>{
              'role': 'system',
              'content':
                  'You are a translation engine. Translate the user text '
                  'from $source to $target. Return only the translation, '
                  'without quotes, notes, or explanations.',
            },
            <String, String>{'role': 'user', 'content': request.text},
          ],
        },
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer ${apiKey.trim()}',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final dynamic data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const TranslationException(TranslationErrorType.parsing);
      }
      final List<dynamic> choices =
          data['choices'] as List<dynamic>? ?? <dynamic>[];
      if (choices.isEmpty) {
        throw const TranslationException(TranslationErrorType.parsing);
      }
      final Map<String, dynamic> choice = choices.first as Map<String, dynamic>;
      final Map<String, dynamic>? message =
          choice['message'] as Map<String, dynamic>?;
      final dynamic content = message?['content'];
      final String text = switch (content) {
        String value => value.trim(),
        List<dynamic> parts =>
          parts
              .whereType<Map<String, dynamic>>()
              .map((Map<String, dynamic> part) => part['text'] as String? ?? '')
              .join()
              .trim(),
        _ => '',
      };
      if (text.isEmpty) {
        throw const TranslationException(TranslationErrorType.parsing);
      }
      return TranslationResult(
        text: text,
        provider: TranslationProviderType.openAi,
        model: model.trim(),
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

  String _languageName(String code) => switch (code) {
    TranslationSettings.targetEnglish => 'English',
    TranslationSettings.targetSimplifiedChinese => 'Simplified Chinese',
    _ => code,
  };
}
