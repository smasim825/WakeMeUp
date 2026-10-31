import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakeme/models/alert_stage.dart';
import 'package:wakeme/models/destination.dart';
import 'package:wakeme/models/journey_state.dart';
import 'package:wakeme/providers/journey_provider.dart';
import 'package:wakeme/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const MethodChannel audioPlayerChannel = MethodChannel('xyz.luan/audioplayers');
  const MethodChannel notificationsChannel = MethodChannel('dexterous.com/flutter/local_notifications');
  const MethodChannel vibrationChannel = MethodChannel('vibration');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobalChannel, (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioPlayerChannel, (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, (call) async => true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(vibrationChannel, (call) async => true);
  });

  late StorageService storageService;
  late JourneyProvider journeyProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await StorageService.init();
    journeyProvider = JourneyProvider(storageService);
  });

  tearDown(() {
    journeyProvider.dispose();
  });

  group('Journey Provider Simulation & Alert Threshold Tests', () {
    const testDestination = Destination(
      name: 'Central Station',
      address: 'Main Terminal',
      latitude: 40.7128,
      longitude: -74.0060,
    );

    test('Selecting destination saves to state and storage', () async {
      await journeyProvider.setDestination(testDestination);

      expect(journeyProvider.hasDestination, isTrue);
      expect(journeyProvider.state.destination?.name, equals('Central Station'));

      final saved = storageService.getSavedDestination();
      expect(saved?.name, equals('Central Station'));
    });

    test('Customizing alert distances updates state and storage', () async {
      await journeyProvider.updateAlertDistances(stage1Km: 7.0, stage2Km: 3.0);

      expect(journeyProvider.state.stage1DistanceKm, equals(7.0));
      expect(journeyProvider.state.stage2DistanceKm, equals(3.0));
      expect(storageService.getStage1Distance(), equals(7.0));
      expect(storageService.getStage2Distance(), equals(3.0));
    });

    test('Simulator mode correctly transitions through Stage 1 and Stage 2 without duplicates', () async {
      await journeyProvider.setDestination(testDestination);
      journeyProvider.toggleSimulatorMode(true);

      expect(journeyProvider.isSimulatorActive, isTrue);

      // 1. Initial far distance: 8.0 km (above 5.0 km)
      await journeyProvider.setSimulatedDistance(8000.0);
      expect(journeyProvider.state.stage1Status, equals(AlertStageStatus.waiting));
      expect(journeyProvider.state.stage2Status, equals(AlertStageStatus.waiting));
      expect(journeyProvider.state.isAlarmSounding, isFalse);

      // 2. Approach: 4.5 km (under 5.0 km stage 1)
      await journeyProvider.setSimulatedDistance(4500.0);
      expect(journeyProvider.state.stage1Status, equals(AlertStageStatus.triggered));
      expect(journeyProvider.state.stage2Status, equals(AlertStageStatus.waiting));
      expect(journeyProvider.state.stage1TriggeredAt, isNotNull);

      // 3. Fluctuates slightly: 4.6 km -> Should stay triggered, NOT duplicate
      await journeyProvider.setSimulatedDistance(4600.0);
      expect(journeyProvider.state.stage1Status, equals(AlertStageStatus.triggered));

      // 4. Arrive closer: 1.8 km (under 2.0 km stage 2)
      await journeyProvider.setSimulatedDistance(1800.0);
      expect(journeyProvider.state.stage1Status, equals(AlertStageStatus.triggered));
      expect(journeyProvider.state.stage2Status, equals(AlertStageStatus.triggered));
      expect(journeyProvider.state.isAlarmSounding, isTrue);

      // 5. Dismiss sound
      await journeyProvider.dismissAlarm();
      expect(journeyProvider.state.isAlarmSounding, isFalse);
      expect(journeyProvider.state.stage2Status, equals(AlertStageStatus.triggered));
    });

    test('Cancelling journey resets active status and cleans up storage', () async {
      await journeyProvider.setDestination(testDestination);
      journeyProvider.toggleSimulatorMode(true);
      await journeyProvider.setSimulatedDistance(1500.0);

      await journeyProvider.cancelJourney();

      expect(journeyProvider.isJourneyActive, isFalse);
      expect(journeyProvider.state.stage1Status, equals(AlertStageStatus.waiting));
      expect(journeyProvider.state.stage2Status, equals(AlertStageStatus.waiting));
      expect(storageService.getActiveJourney(), isNull);
    });
  });

  group('GPS Accuracy & Stale Fix Filtering Tests', () {
    const testDest = Destination(
      name: 'Destination City',
      address: 'Center',
      latitude: 40.7128,
      longitude: -74.0060,
    );

    test('Inaccurate GPS readings (>100m) are rejected to prevent false alarms', () async {
      await journeyProvider.setDestination(testDest);

      // Initial valid reading far away (~10 km)
      final validPosition = Position(
        latitude: 40.8000,
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 15.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 20.0,
        speedAccuracy: 1.0,
      );
      journeyProvider.processPositionForTesting(validPosition);

      final initialRemaining = journeyProvider.state.remainingDistanceMeters;
      expect(initialRemaining, isNotNull);
      expect(journeyProvider.state.stage1Status, equals(AlertStageStatus.waiting));

      // Spurious inaccurate GPS fix right at the destination (< 500m) with poor accuracy (180m)
      final poorAccuracyPosition = Position(
        latitude: 40.7130,
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 180.0, // Bad accuracy
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 20.0,
        speedAccuracy: 1.0,
      );
      journeyProvider.processPositionForTesting(poorAccuracyPosition);

      // Verify the bad reading was rejected: remaining distance was NOT updated to < 500m
      expect(journeyProvider.state.remainingDistanceMeters, equals(initialRemaining));
      // And alerts were NOT triggered
      expect(journeyProvider.state.stage1Status, equals(AlertStageStatus.waiting));
      expect(journeyProvider.state.stage2Status, equals(AlertStageStatus.waiting));
      expect(journeyProvider.state.statusMessage, contains('GPS signal is weak'));
    });

    test('Stale GPS readings (>60 seconds old) are rejected', () async {
      await journeyProvider.setDestination(testDest);

      final stalePosition = Position(
        latitude: 40.7130,
        longitude: -74.0060,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)), // 5 mins old
        accuracy: 10.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      journeyProvider.processPositionForTesting(stalePosition);

      // Stale fix ignored, distance remains unset
      expect(journeyProvider.state.remainingDistanceMeters, isNull);
      expect(journeyProvider.state.stage1Status, equals(AlertStageStatus.waiting));
    });
  });

  group('Started-Inside-Radius Safety Tests', () {
    const testDest = Destination(
      name: 'Close Stop',
      address: 'Downtown',
      latitude: 40.7128,
      longitude: -74.0060,
    );

    test('Starting journey inside Stage 1 radius (3.5 km) marks it as startedInside without firing alarm', () async {
      await journeyProvider.setDestination(testDest);

      // User's location is ~3.5 km away from destination (inside 5 km, outside 2 km)
      final insideStage1Position = Position(
        latitude: 40.7443, // ~3.5 km north
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 12.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 15.0,
        speedAccuracy: 1.0,
      );

      journeyProvider.processPositionForTesting(insideStage1Position);

      // Stage 1 should be marked startedInside
      expect(journeyProvider.state.stage1Status, equals(AlertStageStatus.startedInside));
      // Stage 2 must still be waiting for user to reach 2 km
      expect(journeyProvider.state.stage2Status, equals(AlertStageStatus.waiting));
      // Alarm must NOT be sounding
      expect(journeyProvider.state.isAlarmSounding, isFalse);
      expect(journeyProvider.state.statusMessage, contains('Started inside'));
    });

    test('Starting journey inside Stage 2 radius (1.2 km) marks both as startedInside without firing alarm', () async {
      await journeyProvider.setDestination(testDest);

      // User's location is ~1.2 km away from destination
      final insideStage2Position = Position(
        latitude: 40.7236, // ~1.2 km north
        longitude: -74.0060,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 10.0,
        speedAccuracy: 1.0,
      );

      journeyProvider.processPositionForTesting(insideStage2Position);

      // Both stages should be marked startedInside
      expect(journeyProvider.state.stage1Status, equals(AlertStageStatus.startedInside));
      expect(journeyProvider.state.stage2Status, equals(AlertStageStatus.startedInside));
      // Alarm must NOT be sounding immediately
      expect(journeyProvider.state.isAlarmSounding, isFalse);
    });
  });

  group('Journey State Persistence Tests', () {
    const testDest = Destination(
      name: 'Airport Terminal',
      address: 'Gate 4',
      latitude: 40.6413,
      longitude: -73.7781,
    );

    test('Active journey state and triggered alert status survive app restart', () async {
      final now = DateTime.now();
      final activeState = JourneyState(
        isActive: true,
        destination: testDest,
        initialDistanceMeters: 25000.0,
        remainingDistanceMeters: 4200.0,
        stage1DistanceKm: 5.0,
        stage2DistanceKm: 2.0,
        stage1Status: AlertStageStatus.triggered,
        stage2Status: AlertStageStatus.waiting,
        stage1TriggeredAt: now,
        startedAt: now.subtract(const Duration(minutes: 30)),
      );

      // 1. Save to storage
      await storageService.saveActiveJourney(activeState);

      // 2. Simulate app restart: re-read from storage
      final restoredJourney = storageService.getActiveJourney();

      expect(restoredJourney, isNotNull);
      expect(restoredJourney!.isActive, isTrue);
      expect(restoredJourney.destination?.name, equals('Airport Terminal'));
      expect(restoredJourney.initialDistanceMeters, equals(25000.0));
      expect(restoredJourney.stage1Status, equals(AlertStageStatus.triggered));
      expect(restoredJourney.stage2Status, equals(AlertStageStatus.waiting));
      expect(restoredJourney.stage1TriggeredAt, isNotNull);

      // 3. New provider initializing with restored state
      final newProvider = JourneyProvider(storageService);
      // Ensure restored state preserves triggered stage1 so it won't re-trigger
      expect(newProvider.state.stage1Status, equals(AlertStageStatus.triggered));
      expect(newProvider.state.stage2Status, equals(AlertStageStatus.waiting));
      newProvider.dispose();
    });
  });
}
