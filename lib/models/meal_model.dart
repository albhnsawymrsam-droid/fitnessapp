// lib/models/meal_model.dart

class Meal {
  final int mealId;
  final String mealTime;
  final String name;
  String status;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final String ingredients;

  Meal({
    required this.mealId,
    required this.mealTime,
    required this.name,
    required this.status,
    required this.calories,
    required this.protein,
    required this.carbs,
    this.fats = 0.0,
    this.ingredients = '',
  });

  bool get isDone => status == 'DONE' || status == 'COMPLETED';
  set isDone(bool val) => status = val ? 'COMPLETED' : 'NOT_DONE';

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      mealId: json['mealId'] ?? 0,
      mealTime: json['mealTime'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'NOT_DONE',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0.0,
      ingredients: json['ingredients'] ?? '',
    );
  }
}

class TodayMealsResponse {
  final int planId;
  final int day;
  final List<Meal> meals;

  TodayMealsResponse({
    required this.planId,
    required this.day,
    required this.meals,
  });

  factory TodayMealsResponse.fromJson(Map<String, dynamic> json) {
    return TodayMealsResponse(
      planId: json['planId'] ?? 0,
      day: json['day'] ?? 0,
      meals:
          (json['meals'] as List?)?.map((m) => Meal.fromJson(m)).toList() ?? [],
    );
  }
}

class MealDay {
  final String title;
  final int day;
  final List<Meal> meals;

  MealDay({
    required this.title,
    required this.day,
    required this.meals,
  });

  factory MealDay.fromJson(Map<String, dynamic> json) {
    return MealDay(
      title: json['title'] ?? '',
      day: json['day'] ?? 0,
      meals:
          (json['meals'] as List?)?.map((m) => Meal.fromJson(m)).toList() ?? [],
    );
  }
}

class CurrentMealsResponse {
  final int planId;
  final double dailyCalories;
  final int durationDays;
  final String status;
  final DateTime? createdAt;
  final List<MealDay> mealDays;

  CurrentMealsResponse({
    required this.planId,
    required this.dailyCalories,
    required this.durationDays,
    required this.status,
    required this.createdAt,
    required this.mealDays,
  });

  factory CurrentMealsResponse.fromJson(Map<String, dynamic> json) {
    return CurrentMealsResponse(
      planId: json['planId'] ?? 0,
      dailyCalories: (json['dailyCalories'] as num?)?.toDouble() ?? 0.0,
      durationDays: json['durationDays'] ?? 0,
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      mealDays:
          (json['meals'] as List?)?.map((d) => MealDay.fromJson(d)).toList() ??
              [],
    );
  }
}
