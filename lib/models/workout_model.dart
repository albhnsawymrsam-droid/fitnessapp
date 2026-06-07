class WorkoutDay {
  final int day;
  final String title;
  final List<Exercise> exercises;

  WorkoutDay({
    required this.day,
    required this.title,
    required this.exercises,
  });

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      day: json['day'] ?? 0,
      title: json['title'] ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CurrentWorkoutsResponse {
  final int planId;
  final String goal;
  final String level;
  final String equipment;
  final String status;
  final int durationDays;
  final DateTime? createdAt;
  final List<WorkoutDay> workouts;

  CurrentWorkoutsResponse({
    required this.planId,
    required this.goal,
    required this.level,
    required this.equipment,
    required this.status,
    required this.durationDays,
    required this.createdAt,
    required this.workouts,
  });

  factory CurrentWorkoutsResponse.fromJson(Map<String, dynamic> json) {
    return CurrentWorkoutsResponse(
      planId: json['planId'] ?? 0,
      goal: json['goal'] ?? '',
      level: json['level'] ?? '',
      equipment: json['equipment'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      durationDays: json['durationDays'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      workouts: (json['workouts'] as List<dynamic>?)
              ?.map((w) => WorkoutDay.fromJson(w))
              .toList() ??
          [],
    );
  }
}

class Exercise {
  final String exerciseName;
  final int exerciseId;
  final int sets;
  final int reps;
  final double intensity;
  final String status;

  Exercise({
    required this.exerciseName,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.intensity,
    required this.status,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      exerciseName: json['exerciseName'] ?? '',
      exerciseId: json['exerciseId'] ?? 0,
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? 0,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'NOT_DONE',
    );
  }
}
