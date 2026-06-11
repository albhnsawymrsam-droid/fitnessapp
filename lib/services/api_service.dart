import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

class ApiService {
  ApiService._privateConstructor() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    // ✅ interceptor عشان يتعامل مع 401 أوتوماتيك
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            // امسح الـ token
            await _secureStorage.delete(key: _storageKey);
            _authToken = null;
            _dio.options.headers.remove('Authorization');
            _dio.options.headers.remove('Authentication');

            // إذا كان الطلب هو تسجيل الدخول أو التسجيل، لا نقوم بالتوجيه التلقائي، بل نترك الشاشات تتعامل مع خطأ التحقق وتظهر الرسالة للمستخدم في نفس الصفحة
            final path = error.requestOptions.path.toLowerCase();
            final uriString = error.requestOptions.uri.toString().toLowerCase();
            if (path.contains('login') ||
                path.contains('register') ||
                uriString.contains('login') ||
                uriString.contains('register')) {
              handler.next(error);
              return;
            }

            // مسح بيانات الجلسة والـ Firebase
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_name');
              await prefs.remove('user_email');
              await prefs.remove('user_role');
              await prefs.remove('has_profile');
            } catch (_) {}

            try {
              await FirebaseAuth.instance.signOut();
            } catch (_) {}

            // ابعت اليوزر لشاشة الـ login
            final context = navigatorKey.currentContext;
            if (context != null) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/intro', (route) => false);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiService _instance = ApiService._privateConstructor();
  static ApiService get instance => _instance;

  // ✅ مفتاح الـ Navigator عشان نقدر نتنقل من غير context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  late final Dio _dio;
  String? _authToken;
  static const _storageKey = 'jwt_token';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? get authToken => _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      _dio.options.headers['Authentication'] = 'Bearer $token';
      _secureStorage.write(key: _storageKey, value: token);
    } else {
      _dio.options.headers.remove('Authorization');
      _dio.options.headers.remove('Authentication');
      _secureStorage.delete(key: _storageKey);
    }
  }

  Future<void> restoreAuthToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) return;
    try {
      final stored = await _secureStorage.read(key: _storageKey);
      if (stored != null && stored.isNotEmpty) {
        _authToken = stored;
        _dio.options.headers['Authorization'] = 'Bearer $stored';
        _dio.options.headers['Authentication'] = 'Bearer $stored';
      }
    } catch (e) {
      // ignore storage errors
    }
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return _dio.delete(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) async {
    return await _dio.patch(path, data: data, options: options);
  }
}
