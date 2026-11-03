import 'package:coproduct_location/src/location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationService.clampInterval', () {
    test('zero disables the repeating loop', () {
      expect(LocationService.clampInterval(Duration.zero), Duration.zero);
    });

    test('a negative duration is treated as zero', () {
      expect(
        LocationService.clampInterval(const Duration(seconds: -5)),
        Duration.zero,
      );
    });

    test('floors below the 30-second minimum', () {
      expect(
        LocationService.clampInterval(const Duration(seconds: 5)),
        LocationService.minInterval,
      );
    });

    test('passes through anything at or above the minimum', () {
      expect(
        LocationService.clampInterval(const Duration(minutes: 5)),
        const Duration(minutes: 5),
      );
      expect(
        LocationService.clampInterval(LocationService.minInterval),
        LocationService.minInterval,
      );
    });
  });
}
