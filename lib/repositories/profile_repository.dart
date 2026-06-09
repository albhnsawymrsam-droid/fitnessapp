import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_constants.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final ApiService _api = ApiService.instance;

  Future<UserProfile?> addProfile({
    required int age,
    required String gender,
    required int height,
    required int currentWeight,
    required int targetWeight,
    required String activeLevel,
    required String fitnessGoal,
    required String experienceLevel,
    required String equipment,
  }) async {
    try {
      await _api.restoreAuthToken();

      final response = await _api.post(
        '${AppConstants.vercelUrl}addprofile',
        data: {
          'age': age,
          'gender': gender,
          'height': height,
          'current_weight': currentWeight,
          'target_weight': targetWeight,
          'active_level': activeLevel,
          'fitness_goal': fitnessGoal,
          'experience_level': experienceLevel,
          'equipment': equipment,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['status'] == 'success') {
          return UserProfile.fromJson(response.data);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error in addProfile repository: $e");
      return null;
    }
  }

  // ضيف الدالة دي عشان تجيب بيانات البروفايل
  // دالة جلب بيانات البروفايل (GET)
  Future<UserProfile?> getProfileData() async {
    try {
      final response = await _api.get('${AppConstants.vercelUrl}getProfile');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return UserProfile.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print("Error fetching profile in Repository: $e");
      return null;
    }
  }

  // في ملف profile_repository.dart
  Future<UserProfile?> updateProfile({
    required int profileId,
    required dynamic age, // خليناها dynamic عشان نقبل أي صيغة
    required dynamic height,
    required dynamic currentWeight,
    required dynamic targetWeight,
    required String gender,
    required String activeLevel,
    required String fitnessGoal,
    required String experienceLevel,
    required String equipment,
  }) async {
    try {
      int parseSafe(dynamic value) {
        if (value is int) return value;
        if (value is double) return value.toInt();
        return int.tryParse(value.toString()) ?? 0;
      }

      final Map<String, dynamic> requestData = {
        "profile_id": profileId,
        "age": parseSafe(age),
        "height": parseSafe(height),
        "gender": gender,
        "current_weight": parseSafe(currentWeight),
        "target_weight": parseSafe(targetWeight),
        "active_level": activeLevel,
        "fitness_goal": fitnessGoal,
        "experience_level": experienceLevel,
        "equipment": equipment
      };

      String? token = _api.authToken;

      final response = await _api.patch(
        '${AppConstants.vercelUrl}updateProfile',
        data: requestData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        }),
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return UserProfile.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint("الخطأ اللي حصل: $e");
      return null;
    }
  }
}
