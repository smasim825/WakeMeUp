import 'destination.dart';
import 'alert_stage.dart';

/// Complete state of an active or configured travel journey.
class JourneyState {
  final bool isActive;
  final Destination? destination;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? currentAltitude;
  final double? currentSpeedKmh;
  final double? currentAccuracyMeters;
  final double? remainingDistanceMeters;
  final double? initialDistanceMeters;
  final double stage1DistanceKm;
  final double stage2DistanceKm;
  final AlertStageStatus stage1Status;
  final AlertStageStatus stage2Status;
  final DateTime? stage1TriggeredAt;
  final DateTime? stage2TriggeredAt;
  final DateTime? step2ScheduledAt;
  final int step2DelayMinutes;
  final int currentAlarmStep;
  final DateTime? startedAt;
  final DateTime? lastPositionUpdate;
  final bool isAlarmSounding;
  final bool isSimulatorMode;
  final String? statusMessage;

  const JourneyState({
    this.isActive = false,
    this.destination,
    this.currentLatitude,
    this.currentLongitude,
    this.currentAltitude,
    this.currentSpeedKmh,
    this.currentAccuracyMeters,
    this.remainingDistanceMeters,
    this.initialDistanceMeters,
    this.stage1DistanceKm = 5.0,
    this.stage2DistanceKm = 2.0,
    this.stage1Status = AlertStageStatus.waiting,
    this.stage2Status = AlertStageStatus.waiting,
    this.stage1TriggeredAt,
    this.stage2TriggeredAt,
    this.step2ScheduledAt,
    this.step2DelayMinutes = 2,
    this.currentAlarmStep = 0,
    this.startedAt,
    this.lastPositionUpdate,
    this.isAlarmSounding = false,
    this.isSimulatorMode = false,
    this.statusMessage,
  });

  bool get isStage1Triggered => stage1Status == AlertStageStatus.triggered;
  bool get isStage2Triggered => stage2Status == AlertStageStatus.triggered;

  JourneyState copyWith({
    bool? isActive,
    Destination? destination,
    double? currentLatitude,
    double? currentLongitude,
    double? currentAltitude,
    double? currentSpeedKmh,
    double? currentAccuracyMeters,
    double? remainingDistanceMeters,
    double? initialDistanceMeters,
    double? stage1DistanceKm,
    double? stage2DistanceKm,
    AlertStageStatus? stage1Status,
    AlertStageStatus? stage2Status,
    DateTime? stage1TriggeredAt,
    DateTime? stage2TriggeredAt,
    DateTime? step2ScheduledAt,
    int? step2DelayMinutes,
    int? currentAlarmStep,
    DateTime? startedAt,
    DateTime? lastPositionUpdate,
    bool? isAlarmSounding,
    bool? isSimulatorMode,
    String? statusMessage,
    bool clearDestination = false,
  }) {
    return JourneyState(
      isActive: isActive ?? this.isActive,
      destination: clearDestination ? null : (destination ?? this.destination),
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentAltitude: currentAltitude ?? this.currentAltitude,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentAccuracyMeters: currentAccuracyMeters ?? this.currentAccuracyMeters,
      remainingDistanceMeters: remainingDistanceMeters ?? this.remainingDistanceMeters,
      initialDistanceMeters: initialDistanceMeters ?? this.initialDistanceMeters,
      stage1DistanceKm: stage1DistanceKm ?? this.stage1DistanceKm,
      stage2DistanceKm: stage2DistanceKm ?? this.stage2DistanceKm,
      stage1Status: stage1Status ?? this.stage1Status,
      stage2Status: stage2Status ?? this.stage2Status,
      stage1TriggeredAt: stage1TriggeredAt ?? this.stage1TriggeredAt,
      stage2TriggeredAt: stage2TriggeredAt ?? this.stage2TriggeredAt,
      step2ScheduledAt: step2ScheduledAt ?? this.step2ScheduledAt,
      step2DelayMinutes: step2DelayMinutes ?? this.step2DelayMinutes,
      currentAlarmStep: currentAlarmStep ?? this.currentAlarmStep,
      startedAt: startedAt ?? this.startedAt,
      lastPositionUpdate: lastPositionUpdate ?? this.lastPositionUpdate,
      isAlarmSounding: isAlarmSounding ?? this.isAlarmSounding,
      isSimulatorMode: isSimulatorMode ?? this.isSimulatorMode,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'destination': destination?.toJson(),
      'initialDistanceMeters': initialDistanceMeters,
      'stage1DistanceKm': stage1DistanceKm,
      'stage2DistanceKm': stage2DistanceKm,
      'stage1Status': stage1Status.index,
      'stage2Status': stage2Status.index,
      'stage1TriggeredAt': stage1TriggeredAt?.toIso8601String(),
      'stage2TriggeredAt': stage2TriggeredAt?.toIso8601String(),
      'step2ScheduledAt': step2ScheduledAt?.toIso8601String(),
      'step2DelayMinutes': step2DelayMinutes,
      'currentAlarmStep': currentAlarmStep,
      'startedAt': startedAt?.toIso8601String(),
    };
  }

  factory JourneyState.fromJson(Map<String, dynamic> json) {
    return JourneyState(
      isActive: json['isActive'] as bool? ?? false,
      destination: json['destination'] != null
          ? Destination.fromJson(Map<String, dynamic>.from(json['destination'] as Map))
          : null,
      initialDistanceMeters: (json['initialDistanceMeters'] as num?)?.toDouble(),
      stage1DistanceKm: (json['stage1DistanceKm'] as num?)?.toDouble() ?? 5.0,
      stage2DistanceKm: (json['stage2DistanceKm'] as num?)?.toDouble() ?? 2.0,
      stage1Status: json['stage1Status'] != null
          ? AlertStageStatus.values[(json['stage1Status'] as int)]
          : AlertStageStatus.waiting,
      stage2Status: json['stage2Status'] != null
          ? AlertStageStatus.values[(json['stage2Status'] as int)]
          : AlertStageStatus.waiting,
      stage1TriggeredAt: json['stage1TriggeredAt'] != null
          ? DateTime.tryParse(json['stage1TriggeredAt'] as String)
          : null,
      stage2TriggeredAt: json['stage2TriggeredAt'] != null
          ? DateTime.tryParse(json['stage2TriggeredAt'] as String)
          : null,
      step2ScheduledAt: json['step2ScheduledAt'] != null
          ? DateTime.tryParse(json['step2ScheduledAt'] as String)
          : null,
      step2DelayMinutes: json['step2DelayMinutes'] as int? ?? 2,
      currentAlarmStep: json['currentAlarmStep'] as int? ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
    );
  }
}
