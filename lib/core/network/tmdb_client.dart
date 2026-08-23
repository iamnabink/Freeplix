import 'package:dio/dio.dart';
import 'package:freeplix/core/config/app_config.dart';
import 'package:freeplix/core/network/api_exception.dart';

/// Thin Dio wrapper that knows how TMDB wants to be talked to.
class TmdbClient {
  TmdbClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio
      ..options = _dio.options.copyWith(
        baseUrl: AppConfig.tmdbBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'accept': 'application/json',
          if (AppConfig.tmdbReadToken.isNotEmpty)
            'Authorization': 'Bearer ${AppConfig.tmdbReadToken}',
        },
      )
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // v3 key only when there is no bearer token to use.
            if (AppConfig.tmdbReadToken.isEmpty &&
                AppConfig.tmdbApiKey.isNotEmpty) {
              options.queryParameters['api_key'] = AppConfig.tmdbApiKey;
            }
            options.queryParameters.putIfAbsent('language', () => 'en-US');
            handler.next(options);
          },
        ),
      );
  }

  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      return response.data ?? const {};
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }
}
