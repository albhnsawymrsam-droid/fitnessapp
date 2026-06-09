import 'package:ai/models/workout_model.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';
import '../models/meal_model.dart';

class PlanRepository {
  final ApiService _api = ApiService.instance;

  Future<TodayMealsResponse?> fetchTodayMeals() async {
    try {
      await _api.restoreAuthToken();

      // Use Railway backend for meals/today
      final response = await _api.get('${AppConstants.railwayUrl}meals/today');

      if (response.statusCode == 200) {
        return TodayMealsResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error fetching meals: $e");
      return null;
    }
  }

  // دالة جلب وجبات البرنامج الحالي (بكل الأيام)
  Future<CurrentMealsResponse?> fetchCurrentMeals() async {
    try {
      await _api.restoreAuthToken();

      // Use Railway backend for meals/current
      final requestUrl = '${AppConstants.railwayUrl}meals/current';
      print('*** CURRENT MEALS REQUEST ***');
      print('url: $requestUrl');
      print('method: GET');
      print('*** END CURRENT MEALS REQUEST ***');

      final response = await _api.get(requestUrl);

      print('*** CURRENT MEALS RESPONSE ***');
      print('url: ${response.requestOptions.uri}');
      print('statusCode: ${response.statusCode}');
      print('statusMessage: ${response.statusMessage}');
      print('headers: ${response.headers.map}');
      print('data: ${response.data}');
      print('*** END CURRENT MEALS RESPONSE ***');

      if (response.statusCode == 200) {
        return CurrentMealsResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error fetching current meals: $e");
      return null;
    }
  }

  // دالة جلب خطة التمارين الحالية من Railway
  Future<CurrentWorkoutsResponse?> fetchTodayWorkouts() async {
    try {
      await _api.restoreAuthToken();

      // Use Railway backend for workouts/current
      final requestUrl = '${AppConstants.railwayUrl}workouts/current';
      print('*** WORKOUTS REQUEST ***');
      print('url: $requestUrl');
      print('method: GET');
      print('*** END WORKOUTS REQUEST ***');

      final response = await _api.get(requestUrl);

      print('*** WORKOUTS RESPONSE ***');
      print('url: ${response.requestOptions.uri}');
      print('statusCode: ${response.statusCode}');
      print('statusMessage: ${response.statusMessage}');
      print('headers: ${response.headers.map}');
      print('data: ${response.data}');
      print('*** END WORKOUTS RESPONSE ***');

      if (response.statusCode == 200) {
        return CurrentWorkoutsResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error fetching workouts: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> generatePlan(
      int days, Map<String, dynamic> requestBody,
      {bool isArabic = false}) async {
    try {
      await _api.restoreAuthToken();

      final String queryParam = isArabic ? '?arabic=true' : '';
      final requestUrl = '${AppConstants.railwayUrl}plan/$days$queryParam';
      print('*** GENERATE PLAN REQUEST ***');
      print('url: $requestUrl');
      print('method: POST');
      print('data: $requestBody');
      print('*** END GENERATE PLAN REQUEST ***');

      final response = await _api.post(requestUrl, data: requestBody);

      print('*** GENERATE PLAN RESPONSE ***');
      print('url: ${response.requestOptions.uri}');
      print('statusCode: ${response.statusCode}');
      print('statusMessage: ${response.statusMessage}');
      print('headers: ${response.headers.map}');
      print('data: ${response.data}');
      print('*** END GENERATE PLAN RESPONSE ***');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      throw Exception("Failed with status: ${response.statusCode}");
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          throw Exception(data['message'] ??
              data['error'] ??
              "API Error: ${e.response?.statusCode}");
        } else {
          if (e.response?.statusCode == 401) {
            throw Exception(
                "Session expired. Please log out and log in again.");
          }
          throw Exception("API Error: ${e.response?.statusCode}");
        }
      }
      throw Exception(e.toString());
    }
  }

  // Toggle meal status via API
  Future<bool> toggleMeal(String mealTime, int day) async {
    try {
      await _api.restoreAuthToken();

      // Use Railway backend for meals/toggle
      final requestUrl =
          '${AppConstants.railwayUrl}meals/toggle?mealTime=$mealTime&day=$day';
      print('*** TOGGLE MEAL REQUEST ***');
      print('url: $requestUrl');
      print('method: POST');
      print('*** END TOGGLE MEAL REQUEST ***');

      final response = await _api.post(requestUrl);

      print('*** TOGGLE MEAL RESPONSE ***');
      print('url: ${response.requestOptions.uri}');
      print('statusCode: ${response.statusCode}');
      print('statusMessage: ${response.statusMessage}');
      print('data: ${response.data}');
      print('*** END TOGGLE MEAL RESPONSE ***');

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error toggling meal: $e");
      return false;
    }
  }

  // Toggle exercise status via API
  Future<bool> toggleWorkout(int exerciseId, int day) async {
    try {
      await _api.restoreAuthToken();

      // Use Railway backend for workouts/toggle
      final requestUrl =
          '${AppConstants.railwayUrl}workouts/toggle?exerciseId=$exerciseId&day=$day';
      print('*** TOGGLE WORKOUT REQUEST ***');
      print('url: $requestUrl');
      print('method: POST');
      print('*** END TOGGLE WORKOUT REQUEST ***');

      final response = await _api.post(requestUrl);

      print('*** TOGGLE WORKOUT RESPONSE ***');
      print('url: ${response.requestOptions.uri}');
      print('statusCode: ${response.statusCode}');
      print('statusMessage: ${response.statusMessage}');
      print('data: ${response.data}');
      print('*** END TOGGLE WORKOUT RESPONSE ***');

      return response.statusCode == 200;
    } catch (e) {
      print("Error toggling workout: $e");
      return false;
    }
  }

  // دالة مسح الخطة
  Future<bool> cancelPlan() async {
    try {
      await _api.restoreAuthToken();
      // Use railwayUrl for cancel endpoint (hosted on Railway)
      final response = await _api.post('${AppConstants.railwayUrl}cancel');

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error cancelling plan: $e");
      return false; // لو حصل إيرور نرجع false والتطبيق مش هيضرب
    }
  }
}
