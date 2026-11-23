import 'package:dio/dio.dart';
import 'package:hacki/models/translation/translation_models.dart';

TranslationException mapTranslationHttpError(Object error) {
  if (error is TranslationException) return error;
  if (error is DioException) {
    final int? status = error.response?.statusCode;
    if (status != null) {
      if (status == 401) {
        return TranslationException(
          TranslationErrorType.authentication,
          statusCode: status,
        );
      }
      if (status == 403) {
        return TranslationException(
          TranslationErrorType.permission,
          statusCode: status,
        );
      }
      if (status == 429) {
        return TranslationException(
          TranslationErrorType.rateLimited,
          statusCode: status,
        );
      }
      if (status == 400 || status == 404 || status == 422) {
        return TranslationException(
          TranslationErrorType.invalidConfiguration,
          statusCode: status,
        );
      }
      if (status >= 500) {
        return TranslationException(
          TranslationErrorType.server,
          statusCode: status,
        );
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const TranslationException(TranslationErrorType.network);
    }
    return const TranslationException(TranslationErrorType.network);
  }
  return const TranslationException(TranslationErrorType.unknown);
}
