import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/destination.dart';
import '../models/alert_stage.dart';
import '../models/journey_state.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/alarm_service.dart';
import '../utils/distance_calculator.dart';

class JourneyProvider extends ChangeNotifier {
  final StorageService _storageService;
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final AlarmService _alarmService = AlarmService();

  JourneyState _state = const JourneyState();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _step2Timer;
  bool _isDisposed = false;

  // Simulator distance override (in meters) when simulator is active
  double? _simulatorDistanceMeters;

  JourneyProvider(this._storageService) {
    // 1. Synchronously restore persisted state immediately to avoid race conditions or UI flash
    final savedStage1 = _storageService.getStage1Distance();
    final savedStage2 = _storageService.getStage2Distance();
    final savedDest = _storageService.getSavedDestination();
    final activeJourney = _storageService.getActiveJourney();

    if (activeJourney != null && activeJourney.isActive && activeJourney.destination != null) {
      _state = activeJourney.copyWith(
        stage1DistanceKm: savedStage1,
        stage2DistanceKm: savedStage2,
      );
    } else {
      _state = _state.copyWith(
        destination: savedDest,
        stage1DistanceKm: savedStage1,
        stage2DistanceKm: savedStage2,
      );
    }

    _initializeAsync();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  JourneyState get state => _state;
  bool get hasDestination => _state.destination != null;
  bool get isJourneyActive => _state.isActive;
  bool get isSimulatorActive => _state.isSimulatorMode;
  double? get simulatorDistanceMeters => _simulatorDistanceMeters;

  Future<void> _initializeAsync() async {
    // 1. Initialize notification service
    await _notificationService.initialize();

    // 2. Resume GPS stream if restored journey is active
    if (_state.isActive) {
      _startTrackingStream();
      _rearmStep2Timer();
    }

    // 3. Fetch initial current location
    await refreshCurrentLocation();
    notifyListeners();
  }

  /// After an app restart the in-memory Step 2 timer is gone; re-create it
  /// from the persisted schedule so the follow-up alarm still fires.
  void _rearmStep2Timer() {
    if (_state.stage1Status != AlertStageStatus.triggered ||
        _state.stage2Status != AlertStageStatus.waiting ||
        _state.step2ScheduledAt == null) {
      return;
    }
    final remaining = _state.step2ScheduledAt!.difference(DateTime.now());
    _step2Timer?.cancel();
    _step2Timer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      () => _triggerStep2Alarm(),
    );
  }

  /// Request permissions and get current GPS location
  Future<LocationPermissionResult> refreshCurrentLocation() async {
    final result = await _locationService.checkAndRequestPermissions();
    _state = _state.copyWith(hasLocationPermission: result.isSuccess);
    if (!result.isSuccess) {
      _state = _state.copyWith(statusMessage: result.errorMessage);
      notifyListeners();
      return result;
    }

    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      _updateCurrentPosition(pos);
    }
    return result;
  }

  void _updateCurrentPosition(Position pos) {
    double? remaining;
    if (_state.destination != null) {
      if (_state.isSimulatorMode && _simulatorDistanceMeters != null) {
        remaining = _simulatorDistanceMeters;
      } else {
        remaining = DistanceCalculator.distanceBetween(
          pos.latitude,
          pos.longitude,
          _state.destination!.latitude,
          _state.destination!.longitude,
        );
      }
    }

    _state = _state.copyWith(
      currentLatitude: pos.latitude,
      currentLongitude: pos.longitude,
      currentAltitude: pos.altitude,
      currentSpeedKmh: pos.speed >= 0 ? (pos.speed * 3.6) : 0.0,
      currentAccuracyMeters: pos.accuracy,
      remainingDistanceMeters: remaining,
      lastPositionUpdate: DateTime.now(),
    );
    notifyListeners();
  }

  /// Set selected destination and persist locally for offline usage
  Future<void> setDestination(Destination destination) async {
    _state = _state.copyWith(
      destination: destination,
      clearRemainingDistance: true,
    );

    await _storageService.saveDestination(destination);

    // Recalculate distance if we have current coordinates
    if (_state.currentLatitude != null && _state.currentLongitude != null) {
      final distance = DistanceCalculator.distanceBetween(
        _state.currentLatitude!,
        _state.currentLongitude!,
        destination.latitude,
        destination.longitude,
      );
      _state = _state.copyWith(remainingDistanceMeters: distance);
    }

    notifyListeners();
  }

  /// Clear selected destination
  Future<void> clearDestination() async {
    if (_state.isActive) {
      await cancelJourney();
    }
    _state = _state.copyWith(
      clearDestination: true,
      clearRemainingDistance: true,
    );
    await _storageService.clearSavedDestination();
    notifyListeners();
  }

  /// Update customizable alert distance thresholds
  Future<void> updateAlertDistances({required double stage1Km, required double stage2Km}) async {
    if (stage2Km >= stage1Km) return; // Stage 2 (wake up) must be closer than Stage 1

    _state = _state.copyWith(
      stage1DistanceKm: stage1Km,
      stage2DistanceKm: stage2Km,
    );
    await _storageService.saveAlertDistances(stage1Km: stage1Km, stage2Km: stage2Km);
    notifyListeners();
  }

  /// Quick segmented selector: 5 km, 2 km, 1 km, 500 m
  Future<void> setAlertRadius(double radiusKm) async {
    final double stage2 = (radiusKm * 0.4).clamp(0.2, 2.0);
    _state = _state.copyWith(
      stage1DistanceKm: radiusKm,
      stage2DistanceKm: stage2,
    );
    await _storageService.saveAlertDistances(stage1Km: radiusKm, stage2Km: stage2);
    notifyListeners();
  }

  /// Toggle individual alert stages: 5km, 2km, 500m
  void toggle5kmAlert(bool enable) {
    _state = _state.copyWith(isStage1Enabled: enable);
    notifyListeners();
  }

  void toggle2kmAlert(bool enable) {
    _state = _state.copyWith(isStage2Enabled: enable);
    notifyListeners();
  }

  void toggle500mAlert(bool enable) {
    _state = _state.copyWith(isStage3Enabled: enable);
    notifyListeners();
  }

  /// Start Journey
  Future<bool> startJourney() async {
    if (_state.destination == null) return false;

    // Check location permission
    final perm = await _locationService.checkAndRequestPermissions();
    if (!perm.isSuccess) {
      _state = _state.copyWith(statusMessage: perm.errorMessage);
      notifyListeners();
      return false;
    }

    // Check notification permissions
    await _notificationService.requestPermissions();

    // Get current position to compute initial distance
    final currentPos = await _locationService.getCurrentPosition();
    if (currentPos != null) {
      _updateCurrentPosition(currentPos);
    }

    // Always compute from the freshest GPS fix (never a stale remaining distance
    // from a previous destination/journey).
    final double? currentDistanceMeters =
        (_state.currentLatitude != null && _state.currentLongitude != null)
            ? DistanceCalculator.distanceBetween(
                _state.currentLatitude!,
                _state.currentLongitude!,
                _state.destination!.latitude,
                _state.destination!.longitude,
              )
            : null;

    // Detect if journey started inside an alert radius
    final double stage1Meters = _state.stage1DistanceKm * 1000.0;
    final double stage2Meters = _state.stage2DistanceKm * 1000.0;

    AlertStageStatus stage1Status = AlertStageStatus.waiting;
    AlertStageStatus stage2Status = AlertStageStatus.waiting;
    String? startNotice;

    if (currentDistanceMeters != null && currentDistanceMeters <= stage2Meters) {
      stage1Status = AlertStageStatus.startedInside;
      stage2Status = AlertStageStatus.startedInside;
      startNotice =
          'You started inside the ${DistanceCalculator.formatDistance(stage2Meters)} radius. Both alerts marked as passed to avoid false alarms.';
    } else if (currentDistanceMeters != null && currentDistanceMeters <= stage1Meters) {
      stage1Status = AlertStageStatus.startedInside;
      startNotice =
          'You started inside the ${DistanceCalculator.formatDistance(stage1Meters)} radius. Approaching alert is marked as passed.';
    }

    // Stage 3 (optional "almost there") – skip it if we already start inside it
    AlertStageStatus stage3Status = AlertStageStatus.waiting;
    if (currentDistanceMeters != null &&
        currentDistanceMeters <= _state.stage3DistanceKm * 1000.0) {
      stage3Status = AlertStageStatus.startedInside;
    }

    _step2Timer?.cancel();
    _step2Timer = null;

    _state = _state.copyWith(
      isActive: true,
      isAlarmSounding: false,
      currentAlarmStep: 0,
      initialDistanceMeters: currentDistanceMeters,
      clearInitialDistance: currentDistanceMeters == null,
      remainingDistanceMeters: currentDistanceMeters,
      clearRemainingDistance: currentDistanceMeters == null,
      stage1Status: stage1Status,
      stage2Status: stage2Status,
      stage3Status: stage3Status,
      clearTriggerTimes: true,
      startedAt: DateTime.now(),
      statusMessage: startNotice,
      clearStatusMessage: startNotice == null,
    );

    // Persist active journey state to SharedPreferences
    await _storageService.saveActiveJourney(_state);

    // Start GPS stream
    _startTrackingStream();

    // Update status notification
    _updateStatusNotification();

    notifyListeners();
    return true;
  }

  void _startTrackingStream() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.startPositionStream().listen(
      (position) {
        if (!_state.isActive) return;
        _processNewPosition(position);
      },
      onError: (err) {
        debugPrint('Location stream error: $err');
      },
    );
  }

  /// Process incoming GPS position and evaluate alert criteria
  void _processNewPosition(Position position) {
    // 1. Stale fix check: ignore cached positions older than 60 seconds
    final fixAge = DateTime.now().difference(position.timestamp).abs();
    if (fixAge > const Duration(seconds: 60)) {
      debugPrint('Skipping stale GPS fix (${fixAge.inSeconds}s old)');
      return;
    }

    // 2. Poor accuracy filtering: ignore readings with accuracy worse than 100m
    if (position.accuracy > 100.0) {
      debugPrint('Skipping inaccurate GPS fix: ${position.accuracy}m');
      _state = _state.copyWith(
        currentAccuracyMeters: position.accuracy,
        statusMessage: 'GPS signal is weak (accuracy ±${position.accuracy.round()}m). Waiting for accurate fix...',
      );
      notifyListeners();
      return;
    }

    if (_state.isSimulatorMode && _simulatorDistanceMeters != null) {
      // In simulator mode, use simulated distance
      _evaluateAlerts(_simulatorDistanceMeters!);
      return;
    }

    if (_state.destination == null) return;

    final remainingMeters = DistanceCalculator.distanceBetween(
      position.latitude,
      position.longitude,
      _state.destination!.latitude,
      _state.destination!.longitude,
    );

    // 3. Started-inside check on initial fix if initialDistanceMeters was not set
    AlertStageStatus stage1Status = _state.stage1Status;
    AlertStageStatus stage2Status = _state.stage2Status;
    String? startNotice = _state.statusMessage;
    if (startNotice != null && startNotice.startsWith('GPS signal is weak')) {
      startNotice = null;
    }

    if (_state.initialDistanceMeters == null || _state.initialDistanceMeters == 0.0) {
      final double stage1Meters = _state.stage1DistanceKm * 1000.0;
      final double stage2Meters = _state.stage2DistanceKm * 1000.0;
      if (remainingMeters <= stage2Meters && stage2Status == AlertStageStatus.waiting) {
        stage1Status = AlertStageStatus.startedInside;
        stage2Status = AlertStageStatus.startedInside;
        startNotice = 'Started inside ${DistanceCalculator.formatDistance(stage2Meters)} alert radius. Alerts marked as passed.';
      } else if (remainingMeters <= stage1Meters && stage1Status == AlertStageStatus.waiting) {
        stage1Status = AlertStageStatus.startedInside;
        startNotice = 'Started inside ${DistanceCalculator.formatDistance(stage1Meters)} alert radius. Approaching alert marked as passed.';
      }
    }

    _state = _state.copyWith(
      currentLatitude: position.latitude,
      currentLongitude: position.longitude,
      currentAltitude: position.altitude,
      currentSpeedKmh: position.speed >= 0 ? (position.speed * 3.6) : 0.0,
      currentAccuracyMeters: position.accuracy,
      remainingDistanceMeters: remainingMeters,
      initialDistanceMeters: (_state.initialDistanceMeters == null || _state.initialDistanceMeters! <= 0)
          ? remainingMeters
          : _state.initialDistanceMeters,
      stage1Status: stage1Status,
      stage2Status: stage2Status,
      statusMessage: startNotice,
      clearStatusMessage: startNotice == null,
      lastPositionUpdate: DateTime.now(),
    );

    _evaluateAlerts(remainingMeters);
  }

  /// Helper exposed for unit and integration testing
  @visibleForTesting
  void processPositionForTesting(Position position) => _processNewPosition(position);

  /// Evaluate Stage 1 (Approaching) and Stage 2 (Wake Up 2-Step) alert criteria
  Future<void> _evaluateAlerts(double remainingMeters) async {
    final double stage1Meters = _state.stage1DistanceKm * 1000.0;
    final double stage2Meters = _state.stage2DistanceKm * 1000.0;
    final destName = _state.destination?.name ?? 'Destination';

    // 1. Step 1: Perimeter Entry Alert
    if (_state.stage1Status == AlertStageStatus.waiting && remainingMeters <= stage1Meters) {
      if (!_state.isStage1Enabled) {
        // Alert turned off: mark as passed silently so Step 2 can still run.
        _state = _state.copyWith(stage1Status: AlertStageStatus.startedInside);
      } else {
        final bool scheduleStep2 = _state.isStage2Enabled;
        final step2Time = DateTime.now().add(Duration(minutes: _state.step2DelayMinutes));
        _state = _state.copyWith(
          stage1Status: AlertStageStatus.triggered,
          stage1TriggeredAt: DateTime.now(),
          step2ScheduledAt: scheduleStep2 ? step2Time : null,
          currentAlarmStep: 1,
          isAlarmSounding: true,
          statusMessage: scheduleStep2
              ? 'Approaching $destName! Step 1 Alert sounded. Step 2 follow-up in ${_state.step2DelayMinutes} mins.'
              : 'Approaching $destName! Step 1 Alert sounded.',
        );

        if (scheduleStep2) {
          // Start Step 2 follow-up timer before awaiting anything so a fast
          // second GPS fix cannot race it.
          _step2Timer?.cancel();
          _step2Timer = Timer(Duration(minutes: _state.step2DelayMinutes), () {
            _triggerStep2Alarm();
          });
        }

        await _notificationService.showApproachingNotification(
          destinationName: destName,
          distanceKm: _state.stage1DistanceKm,
        );
        await _alarmService.triggerApproachingAlert();
        await _storageService.saveActiveJourney(_state);
      }
    }

    // 2. Step 2: Wake Up Follow-up Alert (triggers either N mins later OR when entering close boundary).
    // Stage 1 may be "triggered" OR "startedInside" (user began between the two radii) –
    // in the latter case only the close boundary applies (no schedule exists).
    final bool isScheduledTimeReached = _state.step2ScheduledAt != null &&
        DateTime.now().isAfter(_state.step2ScheduledAt!);
    final bool isCloseBoundaryReached = remainingMeters <= stage2Meters;

    if (_state.stage1Status != AlertStageStatus.waiting &&
        _state.stage2Status == AlertStageStatus.waiting &&
        (isScheduledTimeReached || isCloseBoundaryReached)) {
      await _triggerStep2Alarm();
    }

    // 3. Stage 3 check (500 m – Almost there optional alert)
    if (_state.isStage3Enabled &&
        _state.stage3Status == AlertStageStatus.waiting &&
        remainingMeters <= (_state.stage3DistanceKm * 1000.0)) {
      _state = _state.copyWith(
        stage3Status: AlertStageStatus.triggered,
        stage3TriggeredAt: DateTime.now(),
        isAlarmSounding: true,
        statusMessage: '🚨 Almost there! Within 500m of $destName!',
      );
      await _notificationService.showWakeUpNotification(
        destinationName: destName,
        distanceKm: _state.stage3DistanceKm,
        notificationId: NotificationService.stage3NotificationId,
      );
      await _alarmService.triggerWakeUpAlarm();
      await _storageService.saveActiveJourney(_state);
    }

    _updateStatusNotification();
    notifyListeners();
  }

  /// Trigger Step 2 Follow-up Wake-up Alarm
  Future<void> _triggerStep2Alarm() async {
    if (_state.stage2Status != AlertStageStatus.waiting) return;
    _step2Timer?.cancel();
    _step2Timer = null;

    if (!_state.isStage2Enabled) {
      // Wake-up alarm disabled by the user: mark as passed without sounding.
      _state = _state.copyWith(stage2Status: AlertStageStatus.startedInside);
      await _storageService.saveActiveJourney(_state);
      notifyListeners();
      return;
    }

    final destName = _state.destination?.name ?? 'Destination';
    _state = _state.copyWith(
      stage2Status: AlertStageStatus.triggered,
      stage2TriggeredAt: DateTime.now(),
      currentAlarmStep: 2,
      isAlarmSounding: true,
      statusMessage: '🚨 Step 2 Follow-up Alarm: WAKE UP! Arriving at $destName!',
    );

    await _notificationService.showWakeUpNotification(
      destinationName: destName,
      distanceKm: _state.stage2DistanceKm,
    );
    await _alarmService.triggerWakeUpAlarm();
    await _storageService.saveActiveJourney(_state);
    _updateStatusNotification();
    notifyListeners();
  }

  /// Manually trigger Step 2 in simulator/test mode without waiting 2 minutes
  Future<void> triggerStep2NowForTesting() async {
    await _triggerStep2Alarm();
  }

  void _updateStatusNotification() {
    if (!_state.isActive || _state.destination == null) return;
    final remaining = _state.remainingDistanceMeters ?? 0.0;
    final initial = _state.initialDistanceMeters ?? remaining;
    final progress = DistanceCalculator.calculateProgress(initial, remaining);

    _notificationService.showJourneyStatusNotification(
      destinationName: _state.destination!.name,
      formattedDistance: DistanceCalculator.formatDistance(remaining),
      progressPercent: progress,
    );
  }

  /// Dismiss sounding alarm (sound + vibration) while maintaining journey
  Future<void> dismissAlarm() async {
    await _alarmService.stopAlarm();
    _state = _state.copyWith(isAlarmSounding: false);
    notifyListeners();
  }

  /// Cancel active journey
  Future<void> cancelJourney() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _step2Timer?.cancel();
    _step2Timer = null;
    await _alarmService.stopAlarm();
    await _notificationService.cancelAll();

    _state = _state.copyWith(
      isActive: false,
      isAlarmSounding: false,
      currentAlarmStep: 0,
      stage1Status: AlertStageStatus.waiting,
      stage2Status: AlertStageStatus.waiting,
      stage3Status: AlertStageStatus.waiting,
      clearTriggerTimes: true,
      clearInitialDistance: true,
      statusMessage: 'Journey cancelled.',
    );

    await _storageService.clearActiveJourney();
    notifyListeners();
  }

  // ==========================================
  // Developer Distance Simulator
  // ==========================================

  void toggleSimulatorMode(bool enable) {
    _state = _state.copyWith(isSimulatorMode: enable);
    if (!enable) {
      _simulatorDistanceMeters = null;
    } else {
      _simulatorDistanceMeters ??= _state.remainingDistanceMeters ?? 8000.0;
    }
    notifyListeners();
  }

  /// Inject simulated distance in meters to test alert triggers cleanly
  Future<void> setSimulatedDistance(double distanceMeters) async {
    if (!_state.isSimulatorMode) return;
    _simulatorDistanceMeters = distanceMeters;
    _state = _state.copyWith(
      remainingDistanceMeters: distanceMeters,
      lastPositionUpdate: DateTime.now(),
      statusMessage: '[Simulator] Distance set to ${DistanceCalculator.formatDistance(distanceMeters)}',
    );
    await _evaluateAlerts(distanceMeters);
    notifyListeners();
  }

  /// Step simulator distance closer by a set amount
  Future<void> stepSimulatorCloser(double stepMeters) async {
    if (!_state.isSimulatorMode) return;
    final current = _simulatorDistanceMeters ?? _state.remainingDistanceMeters ?? 6000.0;
    final next = (current - stepMeters).clamp(0.0, 50000.0);
    await setSimulatedDistance(next);
  }

  /// Reset alert triggers in simulator mode for quick repeated testing
  void resetAlertTriggersForTesting() {
    _alarmService.stopAlarm();
    _step2Timer?.cancel();
    _step2Timer = null;
    _state = _state.copyWith(
      stage1Status: AlertStageStatus.waiting,
      stage2Status: AlertStageStatus.waiting,
      stage3Status: AlertStageStatus.waiting,
      clearTriggerTimes: true,
      currentAlarmStep: 0,
      isAlarmSounding: false,
      statusMessage: '[Simulator] Alert stages reset for testing.',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _step2Timer?.cancel();
    _step2Timer = null;
    _positionSubscription?.cancel();
    _alarmService.dispose();
    super.dispose();
  }
}
