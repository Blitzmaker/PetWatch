import 'package:dio/dio.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient(this._tokenStore)
      : dio = Dio(BaseOptions(baseUrl: _baseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _tokenStore.getAccessToken();
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          if (error.response?.statusCode == 401 && !alreadyRetried) {
            final refreshToken = await _tokenStore.getRefreshToken();
            if (refreshToken != null) {
              try {
                final refreshResponse = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
                final nextAccess = refreshResponse.data['accessToken'] as String;
                final nextRefresh = refreshResponse.data['refreshToken'] as String;
                await _tokenStore.saveTokens(nextAccess, nextRefresh);

                final requestOptions = error.requestOptions;
                requestOptions.headers['Authorization'] = 'Bearer $nextAccess';
                requestOptions.extra['retried'] = true;
                final retryResponse = await dio.fetch(requestOptions);
                return handler.resolve(retryResponse);
              } catch (_) {
                await _tokenStore.clear();
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }


  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  final Dio dio;
  final TokenStore _tokenStore;
}
