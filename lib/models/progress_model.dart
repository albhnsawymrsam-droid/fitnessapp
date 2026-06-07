// lib/models/progress_model.dart

class ProgressPoint {
  final double weight;
  final DateTime recordedAt;

  ProgressPoint({
    required this.weight,
    required this.recordedAt,
  });

  factory ProgressPoint.fromJson(Map<String, dynamic> json) {
    return ProgressPoint(
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ProgressSummary {
  final double startedAt;
  final double currentlyAt;
  final double aimingFor;

  ProgressSummary({
    required this.startedAt,
    required this.currentlyAt,
    required this.aimingFor,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      startedAt: (json['started_at'] as num?)?.toDouble() ?? 0.0,
      currentlyAt: (json['currently_at'] as num?)?.toDouble() ?? 0.0,
      aimingFor: (json['aiming_for'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProgressData {
  final List<ProgressPoint> chartData;
  final ProgressSummary summary;

  ProgressData({
    required this.chartData,
    required this.summary,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      chartData: (json['chartData'] as List<dynamic>?)
              ?.map((item) => ProgressPoint.fromJson(item))
              .toList() ??
          [],
      summary: ProgressSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

class ProgressResponse {
  final String status;
  final ProgressData data;

  ProgressResponse({
    required this.status,
    required this.data,
  });

  factory ProgressResponse.fromJson(Map<String, dynamic> json) {
    return ProgressResponse(
      status: json['status']?.toString() ?? 'error',
      data: ProgressData.fromJson(json['data'] ?? {}),
    );
  }
}
