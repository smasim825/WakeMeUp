import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakeme/models/alert_stage.dart';
import 'package:wakeme/models/destination.dart';
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

  group('Journey Provider Simulation & Alert Logic Tests', () {
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
      // But alert stage stays triggered
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
}
