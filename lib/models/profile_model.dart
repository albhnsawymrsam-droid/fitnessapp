class UserProfile {
  final int profileId;
  final int userId;
  final String fullName;
  final String email;
  final int age;
  final String gender;
  final int height;
  final int currentWeight;
  final int targetWeight;
  final int initialWeight;
  final double bmi;
  final double bmr;
  final String activeLevel;
  final String fitnessGoal;
  final String experienceLevel;
  final String equipment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.profileId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.age,
    required this.gender,
    required this.height,
    required this.currentWeight,
    required this.targetWeight,
    required this.initialWeight,
    required this.bmi,
    required this.bmr,
    required this.activeLevel,
    required this.fitnessGoal,
    required this.experienceLevel,
    required this.equipment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final account = data['account'] ?? {};
    final profile = data['Profile'] ?? data['profile'] ?? {};

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return UserProfile(
      profileId: profile['profile_id'] ?? 0,
      userId: profile['user_id'] ?? 0,
      fullName: account['fullName']?.toString() ?? 'User',
      email: account['email']?.toString() ?? '',
      age: profile['age'] ?? 20,
      gender: profile['gender']?.toString() ?? 'MALE',
      height: profile['height'] ?? 170,
      currentWeight: profile['current_weight'] ?? 70,
      targetWeight: profile['target_weight'] ?? 70,
      initialWeight:
          profile['initial_weight'] ?? profile['current_weight'] ?? 70,
      bmi: parseDouble(profile['bmi']),
      bmr: parseDouble(profile['bmr']),
      activeLevel: profile['active_level']?.toString() ?? 'LIGHT',
      fitnessGoal: profile['fitness_goal']?.toString() ?? 'LOSE WEIGHT',
      experienceLevel: profile['experience_level']?.toString() ?? 'BEGINNER',
      equipment: profile['equipment']?.toString() ?? 'AT_HOME',
      createdAt: profile['createdAt'] != null
          ? DateTime.tryParse(profile['createdAt'].toString())
          : null,
      updatedAt: profile['updatedAt'] != null
          ? DateTime.tryParse(profile['updatedAt'].toString())
          : null,
    );
  }
}
