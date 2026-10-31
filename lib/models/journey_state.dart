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

  // Alert Radii (km)
  final double stage1DistanceKm;
  final double stage2DistanceKm;
  final double stage3DistanceKm;

  // Enabled flags for the three alerts
  final bool isStage1Enabled;
  final bool isStage2Enabled;
  final bool isStage3Enabled;

  // Status for each alert stage
  final AlertStageStatus stage1Status;
  final AlertStageStatus stage2Status;
  final AlertStageStatus stage3Status;

  final DateTime? stage1TriggeredAt;
  final DateTime? stage2TriggeredAt;
  final DateTime? stage3TriggeredAt;
  final DateTime? step2ScheduledAt;
  final int step2DelayMinutes;
  final int currentAlarmStep;
  final DateTime? startedAt;
  final DateTime? lastPositionUpdate;
  final bool isAlarmSounding;
  final bool isSimulatorMode;
  final bool hasLocationPermission;
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
    this.stage3DistanceKm = 0.5,
    this.isStage1Enabled = true,
    this.isStage2Enabled = true,
    this.isStage3Enabled = false,
    this.stage1Status = AlertStageStatus.waiting,
    this.stage2Status = AlertStageStatus.waiting,
    this.stage3Status = AlertStageStatus.waiting,
    this.stage1TriggeredAt,
    this.stage2TriggeredAt,
    this.stage3TriggeredAt,
    this.step2ScheduledAt,
    this.step2DelayMinutes = 2,
    this.currentAlarmStep = 0,
    this.startedAt,
    this.lastPositionUpdate,
    this.isAlarmSounding = false,
    this.isSimulatorMode = false,
    this.hasLocationPermission = true,
    this.statusMessage,
  });

  bool get isStage1Triggered => stage1Status == AlertStageStatus.triggered;
  bool get isStage2Triggered => stage2Status == AlertStageStatus.triggered;
  bool get isStage3Triggered => stage3Status == AlertStageStatus.triggered;

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
    double? stage3DistanceKm,
    bool? isStage1Enabled,
    bool? isStage2Enabled,
    bool? isStage3Enabled,
    AlertStageStatus? stage1Status,
    AlertStageStatus? stage2Status,
    AlertStageStatus? stage3Status,
    DateTime? stage1TriggeredAt,
    DateTime? stage2TriggeredAt,
    DateTime? stage3TriggeredAt,
    DateTime? step2ScheduledAt,
    int? step2DelayMinutes,
    int? currentAlarmStep,
    DateTime? startedAt,
    DateTime? lastPositionUpdate,
    bool? isAlarmSounding,
    bool? isSimulatorMode,
    bool? hasLocationPermission,
    String? statusMessage,
    bool clearDestination = false,
    bool clearRemainingDistance = false,
    bool clearInitialDistance = false,
    bool clearStatusMessage = false,
    bool clearStep2Schedule = false,
    bool clearTriggerTimes = false,
  }) {
    return JourneyState(
      isActive: isActive ?? this.isActive,
      destination: clearDestination ? null : (destination ?? this.destination),
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentAltitude: currentAltitude ?? this.currentAltitude,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentAccuracyMeters: currentAccuracyMeters ?? this.currentAccuracyMeters,
      remainingDistanceMeters:
          clearRemainingDistance ? null : (remainingDistanceMeters ?? this.remainingDistanceMeters),
      initialDistanceMeters:
          clearInitialDistance ? null : (initialDistanceMeters ?? this.initialDistanceMeters),
      stage1DistanceKm: stage1DistanceKm ?? this.stage1DistanceKm,
      stage2DistanceKm: stage2DistanceKm ?? this.stage2DistanceKm,
      stage3DistanceKm: stage3DistanceKm ?? this.stage3DistanceKm,
      isStage1Enabled: isStage1Enabled ?? this.isStage1Enabled,
      isStage2Enabled: isStage2Enabled ?? this.isStage2Enabled,
      isStage3Enabled: isStage3Enabled ?? this.isStage3Enabled,
      stage1Status: stage1Status ?? this.stage1Status,
      stage2Status: stage2Status ?? this.stage2Status,
      stage3Status: stage3Status ?? this.stage3Status,
      stage1TriggeredAt: clearTriggerTimes ? null : (stage1TriggeredAt ?? this.stage1TriggeredAt),
      stage2TriggeredAt: clearTriggerTimes ? null : (stage2TriggeredAt ?? this.stage2TriggeredAt),
      stage3TriggeredAt: clearTriggerTimes ? null : (stage3TriggeredAt ?? this.stage3TriggeredAt),
      step2ScheduledAt:
          (clearStep2Schedule || clearTriggerTimes) ? null : (step2ScheduledAt ?? this.step2ScheduledAt),
      step2DelayMinutes: step2DelayMinutes ?? this.step2DelayMinutes,
      currentAlarmStep: currentAlarmStep ?? this.currentAlarmStep,
      startedAt: startedAt ?? this.startedAt,
      lastPositionUpdate: lastPositionUpdate ?? this.lastPositionUpdate,
      isAlarmSounding: isAlarmSounding ?? this.isAlarmSounding,
      isSimulatorMode: isSimulatorMode ?? this.isSimulatorMode,
      hasLocationPermission: hasLocationPermission ?? this.hasLocationPermission,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'destination': destination?.toJson(),
      'initialDistanceMeters': initialDistanceMeters,
      'stage1DistanceKm': stage1DistanceKm,
      'stage2DistanceKm': stage2DistanceKm,
      'stage3DistanceKm': stage3DistanceKm,
      'isStage1Enabled': isStage1Enabled,
      'isStage2Enabled': isStage2Enabled,
      'isStage3Enabled': isStage3Enabled,
      'stage1Status': stage1Status.index,
      'stage2Status': stage2Status.index,
      'stage3Status': stage3Status.index,
      'stage1TriggeredAt': stage1TriggeredAt?.toIso8601String(),
      'stage2TriggeredAt': stage2TriggeredAt?.toIso8601String(),
      'stage3TriggeredAt': stage3TriggeredAt?.toIso8601String(),
      'step2ScheduledAt': step2ScheduledAt?.toIso8601String(),
      'step2DelayMinutes': step2DelayMinutes,
      'currentAlarmStep': currentAlarmStep,
      'startedAt': startedAt?.toIso8601String(),
    };
  }

  static AlertStageStatus _statusFromJson(dynamic raw) {
    if (raw is int && raw >= 0 && raw < AlertStageStatus.values.length) {
      return AlertStageStatus.values[raw];
    }
    return AlertStageStatus.waiting;
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
      stage3DistanceKm: (json['stage3DistanceKm'] as num?)?.toDouble() ?? 0.5,
      isStage1Enabled: json['isStage1Enabled'] as bool? ?? true,
      isStage2Enabled: json['isStage2Enabled'] as bool? ?? true,
      isStage3Enabled: json['isStage3Enabled'] as bool? ?? false,
      stage1Status: _statusFromJson(json['stage1Status']),
      stage2Status: _statusFromJson(json['stage2Status']),
      stage3Status: _statusFromJson(json['stage3Status']),
      stage1TriggeredAt: json['stage1TriggeredAt'] != null
          ? DateTime.tryParse(json['stage1TriggeredAt'] as String)
          : null,
      stage2TriggeredAt: json['stage2TriggeredAt'] != null
          ? DateTime.tryParse(json['stage2TriggeredAt'] as String)
          : null,
      stage3TriggeredAt: json['stage3TriggeredAt'] != null
          ? DateTime.tryParse(json['stage3TriggeredAt'] as String)
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
