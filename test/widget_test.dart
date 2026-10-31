import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakeme/models/destination.dart';
import 'package:wakeme/models/alert_stage.dart';
import 'package:wakeme/utils/distance_calculator.dart';
import 'package:wakeme/widgets/alarm_distance_selector.dart';

void main() {
  group('DistanceCalculator Tests', () {
    test('Calculates Haversine distance between known coordinates accurately', () {
      // London (51.5074, -0.1278) to Paris (48.8566, 2.3522) ~ 343.5 km
      final meters = DistanceCalculator.distanceBetween(
        51.5074,
        -0.1278,
        48.8566,
        2.3522,
      );

      final km = meters / 1000.0;
      expect(km, greaterThan(340));
      expect(km, lessThan(350));
    });

    test('Distance between identical points is 0 meters', () {
      final meters = DistanceCalculator.distanceBetween(
        40.7128,
        -74.0060,
        40.7128,
        -74.0060,
      );
      expect(meters, equals(0.0));
    });

    test('Formats distance correctly for meters and kilometers', () {
      expect(DistanceCalculator.formatDistance(450), equals('450 m'));
      expect(DistanceCalculator.formatDistance(999), equals('999 m'));
      expect(DistanceCalculator.formatDistance(1500), equals('1.50 km'));
      expect(DistanceCalculator.formatDistance(12400), equals('12.4 km'));
    });

    test('Progress calculation is clamped between 0.0 and 1.0', () {
      // Started 10km away, now 5km away -> 50%
      expect(DistanceCalculator.calculateProgress(10000, 5000), equals(0.5));
      // Started 10km away, now 0km away -> 100%
      expect(DistanceCalculator.calculateProgress(10000, 0), equals(1.0));
      // Overshot -> clamped to 1.0
      expect(DistanceCalculator.calculateProgress(10000, -500), equals(1.0));
    });
  });

  group('Destination Model Tests', () {
    test('Serializes to and from JSON correctly', () {
      const dest = Destination(
        name: 'Grand Central Station',
        address: '89 E 42nd St, New York, NY',
        latitude: 40.7527,
        longitude: -73.9772,
      );

      final json = dest.toJson();
      final restored = Destination.fromJson(json);

      expect(restored.name, equals('Grand Central Station'));
      expect(restored.latitude, equals(40.7527));
      expect(restored.longitude, equals(-73.9772));
      expect(restored.address, equals('89 E 42nd St, New York, NY'));
    });
  });

  group('Alert Stage Logic Tests', () {
    test('Initial stage status is waiting', () {
      const stage = AlertStageInfo(
        type: AlertStageType.approaching,
        title: 'Approaching',
        description: '5 km radius alert',
        defaultDistanceKm: 5.0,
        currentDistanceKm: 5.0,
      );

      expect(stage.status, equals(AlertStageStatus.waiting));
      expect(stage.isTriggered, isFalse);
    });

    test('Transition to triggered marks isTriggered to true', () {
      const stage = AlertStageInfo(
        type: AlertStageType.wakeUp,
        title: 'Wake Up',
        description: '2 km radius alarm',
        defaultDistanceKm: 2.0,
        currentDistanceKm: 2.0,
      );

      final triggered = stage.copyWith(
        status: AlertStageStatus.triggered,
        triggeredAt: DateTime.now(),
      );

      expect(triggered.isTriggered, isTrue);
      expect(triggered.triggeredAt, isNotNull);
    });
  });

  group('AlarmDistanceSelector Widget Tests', () {
    testWidgets('Renders all 3 alarm cards and triggers callbacks', (tester) async {
      bool is5km = true;
      bool is2km = true;
      bool is500m = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AlarmDistanceSelector(
                  is5kmEnabled: is5km,
                  is2kmEnabled: is2km,
                  is500mEnabled: is500m,
                  on5kmToggle: (val) => setState(() => is5km = val),
                  on2kmToggle: (val) => setState(() => is2km = val),
                  on500mToggle: (val) => setState(() => is500m = val),
                );
              },
            ),
          ),
        ),
      );

      // Verify title & headings
      expect(find.text('When should we wake you?'), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('2 km'), findsOneWidget);
      expect(find.text('500 m'), findsOneWidget);
      expect(find.text('Get ready'), findsOneWidget);
      expect(find.text('Wake me up'), findsOneWidget);
      expect(find.text('Almost there'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);

      // Tap 500m option to enable it
      await tester.tap(find.text('500 m'));
      await tester.pumpAndSettle();

      expect(is500m, isTrue);

      // Tap 5km option to disable it
      await tester.tap(find.text('5 km'));
      await tester.pumpAndSettle();

      expect(is5km, isFalse);
    });
  });
}
