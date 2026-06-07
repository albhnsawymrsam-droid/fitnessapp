// lib/repositories/progress_repository.dart

import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';
import '../models/progress_model.dart';

class ProgressRepository {
  final ApiService _api = ApiService.instance;

  Future<ProgressResponse?> fetchProgressData() async {
    try {
      await _api.restoreAuthToken();

      final requestUrl = '${AppConstants.vercelUrl}my-progress';
      print('*** PROGRESS DATA REQUEST ***');
      print('url: $requestUrl');
      print('method: GET');
      print('*** END PROGRESS DATA REQUEST ***');

      final response = await _api.get(requestUrl);

      print('*** PROGRESS DATA RESPONSE ***');
      print('url: ${response.requestOptions.uri}');
      print('statusCode: ${response.statusCode}');
      print('data: ${response.data}');
      print('*** END PROGRESS DATA RESPONSE ***');

      if (response.statusCode == 200) {
        return ProgressResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching progress data: $e');
      return null;
    }
  }

  // TODO: Add save/delete progress methods when Vercel endpoints are available.
}
