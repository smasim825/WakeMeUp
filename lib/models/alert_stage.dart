enum AlertStageType {
  approaching,
  wakeUp,
}

enum AlertStageStatus {
  waiting,
  triggered,
  startedInside,
}

class AlertStageInfo {
  final AlertStageType type;
  final String title;
  final String description;
  final double defaultDistanceKm;
  final double currentDistanceKm;
  final AlertStageStatus status;
  final DateTime? triggeredAt;

  const AlertStageInfo({
    required this.type,
    required this.title,
    required this.description,
    required this.defaultDistanceKm,
    required this.currentDistanceKm,
    this.status = AlertStageStatus.waiting,
    this.triggeredAt,
  });

  bool get isTriggered => status == AlertStageStatus.triggered;
  bool get wasStartedInside => status == AlertStageStatus.startedInside;

  AlertStageInfo copyWith({
    double? currentDistanceKm,
    AlertStageStatus? status,
    DateTime? triggeredAt,
  }) {
    return AlertStageInfo(
      type: type,
      title: title,
      description: description,
      defaultDistanceKm: defaultDistanceKm,
      currentDistanceKm: currentDistanceKm ?? this.currentDistanceKm,
      status: status ?? this.status,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }
}

