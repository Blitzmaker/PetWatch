import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));

  Future<void> init() async {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('accessToken');
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refreshToken');
          if (refreshToken != null) {
            final refreshResponse = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
            await prefs.setString('accessToken', refreshResponse.data['accessToken'] as String);
            await prefs.setString('refreshToken', refreshResponse.data['refreshToken'] as String);
            final retry = await dio.fetch(error.requestOptions..headers['Authorization'] = 'Bearer ${refreshResponse.data['accessToken']}');
            return handler.resolve(retry);
          }
        }
        handler.next(error);
      },
    ));
  }
}
