import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';

class AuthRepository {
  final ApiService _api = ApiService.instance;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final requestData = {
      'email': email,
      'password': password,
    };
    final requestUrl = '${AppConstants.baseUrl}login';

    print('*** LOGIN REQUEST ***');
    print('url: $requestUrl');
    print('method: POST');
    print('data: $requestData');
    print('*** END LOGIN REQUEST ***');

    final response = await _api.post('login', data: requestData);

    print('*** LOGIN RESPONSE ***');
    print('url: ${response.requestOptions.uri}');
    print('statusCode: ${response.statusCode}');
    print('statusMessage: ${response.statusMessage}');
    print('headers: ${response.headers.map}');
    print('data: ${response.data}');
    print('*** END LOGIN RESPONSE ***');

    if (response.statusCode == 200) {
      final data = response.data;
      final userData = data['data']?['user'] ?? {};
      final user = UserModel.fromJson(userData);
      final token = data['token'];
      final hasProfile = data['data']?['hasProfile'] ?? false;

      if (token != null) {
        _api.setAuthToken(token.toString());
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', user.fullname);
      await prefs.setString('user_email', user.email);
      await prefs.setBool('has_profile', hasProfile);

      return {
        'user': user,
        'token': token,
        'hasProfile': hasProfile,
      };
    }

    throw DioException(
        requestOptions: response.requestOptions, response: response);
  }

  Future<UserModel> register({
    required String fullname,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _api.post('register', data: {
      'fullname': fullname,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'passwordConfirm': confirmPassword,
      'password_confirm': confirmPassword,
      'confirm_password': confirmPassword,
      'passwordConfirmation': confirmPassword,
      'password_confirmation': confirmPassword,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      final userData = data['data']?['user'] ?? {};
      final user = UserModel.fromJson(userData);
      final token = data['token'];
      if (token != null) _api.setAuthToken(token.toString());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', user.fullname);
      await prefs.setString('user_email', user.email);
      await prefs.setBool('has_profile', false);

      return user;
    }

    throw DioException(
        requestOptions: response.requestOptions, response: response);
  }

  // Future<Map<String, dynamic>> logout() async {
  //   final response = await _api.post('logout');

  //   if (response.statusCode == 200) {
  //     _api.setAuthToken(null);
  //     return response.data;
  //   }

  //   throw DioException(
  //       requestOptions: response.requestOptions, response: response);
  // }
  Future<Map<String, dynamic>> logout() async {
    final response = await _api.post('${AppConstants.vercelUrl}logout');

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        (response.data != null && response.data['status'] == 'success')) {
      _api.setAuthToken(null);

      // ✅ امسح الـ token المحفوظ وكل بيانات اليوزر
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('has_profile');

      return response.data;
    }

    throw DioException(
        requestOptions: response.requestOptions, response: response);
  }

  Future<Map<String, dynamic>> forgetPassword({
    required String email,
  }) async {
    final response = await _api.post('forget-password', data: {
      'email': email,
    });

    if (response.statusCode == 200) {
      return response.data;
    }

    throw DioException(
        requestOptions: response.requestOptions, response: response);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _api.post('reset-password', data: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });

    if (response.statusCode == 200) {
      return response.data;
    }

    throw DioException(
        requestOptions: response.requestOptions, response: response);
  }
}
