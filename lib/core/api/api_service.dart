import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService_instance = ApiService._internal();
  factory ApiService() => ApiService_instance;
  ApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Add the stored access token to authenticated requests.
  Future<void> _addToken() async {
    final pref = await SharedPreferences.getInstance();
    final token = pref.getString('access_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // GET request
  Future<Response> get(String path) async {
    await _addToken();
    return await _dio.get(path);
  }

  // POST request
  Future<Response> post(String path, {dynamic data}) async {
    await _addToken();
    return await _dio.post(path, data: data);
  }

  // POST with form data (file upload)
  Future<Response> postForm(String path, FormData formData) async {
    await _addToken();
    return await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
