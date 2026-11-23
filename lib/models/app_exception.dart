import 'package:hacki/l10n/l10n.dart';

typedef AppExceptionHandler = void Function(AppException);

class AppException implements Exception {
  AppException({required this.message, this.stackTrace, this.error});

  final String? message;
  final StackTrace? stackTrace;
  final dynamic error;
}

class RateLimitedException extends AppException {
  RateLimitedException(this.statusCode, {super.error})
    : super(message: L10n.current.errorRateLimited('$statusCode'));

  final int? statusCode;
}

class RateLimitedWithFallbackException extends AppException {
  RateLimitedWithFallbackException(this.statusCode, {super.error})
    : super(message: L10n.current.errorRateLimitedFallback('$statusCode'));

  final int? statusCode;
}

class TooManyRequestsException extends AppException {
  TooManyRequestsException({required this.retryAfter, super.error})
    : super(
        message: L10n.current.errorTooManyRequests(
          L10n.dateFormat('yMMMd').add_Hm().format(retryAfter.toLocal()),
        ),
      );

  /// The time after which app can keep sending in requests.
  final DateTime retryAfter;
}

class ParsingException extends AppException {
  ParsingException({required this.itemId, super.error})
    : super(message: L10n.current.errorParsing('$itemId'));

  final int itemId;
}

class GenericException extends AppException {
  GenericException({super.error}) : super(message: L10n.current.errorGeneric);
}
