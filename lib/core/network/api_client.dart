import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// Configured [Dio] instance for talking to the FastAPI backend.
///
/// Auth tokens, logging, and error normalisation live here so feature
/// repositories stay thin. Only used when [AppConstants.useMockBackend] is off.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // TODO: attach Firebase ID token:
        // final token = ref.read(authProvider).value?.idToken;
        // if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (err, handler) {
        handler.next(err);
      },
    ),
  );

  return dio;
});

/// Normalised failure type so the UI never sees raw [DioException]s.
class ApiFailure implements Exception {
  ApiFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  factory ApiFailure.from(Object error) {
    if (error is DioException) {
      final code = error.response?.statusCode;
      final detail = error.response?.data is Map
          ? (error.response?.data['detail']?.toString())
          : null;
      return ApiFailure(
        detail ?? error.message ?? 'Network error',
        statusCode: code,
      );
    }
    return ApiFailure(error.toString());
  }

  @override
  String toString() => message;
}
