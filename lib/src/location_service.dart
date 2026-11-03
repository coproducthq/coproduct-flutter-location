import 'dart:async';

import 'package:coproduct/coproduct.dart' show AttributeValue, CoproductClient;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'foreground_resume.dart';

/// Keeps `device_location` current for one [CoproductClient] by reading a GPS
/// fix on a foreground cadence and publishing it through
/// [CoproductClient.updateAttributes], so a geo-fence re-evaluates as the
/// device moves.
///
/// Opt-in and gated: nothing runs until the host calls [enable] (or
/// [setIntervalMs]), which requests OS location permission on its first call.
/// The loop is foreground-only; a `Timer` naturally stops firing while the
/// isolate is frozen in the background and resumes on return, and the
/// foreground-resume binder takes a fresh fix the moment the app is
/// foregrounded. The service holds no continuous `Geolocator` stream; it
/// reads one fix per tick on its own cadence.
class LocationService {
  LocationService(this._client);

  /// Interval used when the host enables location without naming one.
  static const Duration defaultInterval = Duration(minutes: 2);

  /// Smallest repeating interval, so an over-eager caller cannot drain the
  /// battery.
  static const Duration minInterval = Duration(seconds: 30);

  /// Clamp a requested interval. `Duration.zero` disables the loop (one fix
  /// only), anything else is floored.
  static Duration clampInterval(Duration requested) {
    if (requested <= Duration.zero) return Duration.zero;
    return requested < minInterval ? minInterval : requested;
  }

  final CoproductClient _client;

  Duration _interval = defaultInterval;
  bool _enabled = false;
  bool _acquiring = false;
  Timer? _timer;
  void Function()? _disposeResume;

  /// Request permission and, if granted, turn location on: take a first fix
  /// now and start the foreground loop unless the interval is zero. Returns
  /// whether permission was granted. Idempotent.
  Future<bool> enable() async {
    if (!await _ensurePermission()) return false;
    if (!_enabled) {
      _enabled = true;
      _disposeResume = bindForegroundResume(_onResume);
    }
    await _tick();
    _schedule();
    return true;
  }

  /// Enable (requesting permission) and set the repeating interval. `0` keeps
  /// only the one-shot fix. Returns whether permission was granted.
  Future<bool> setIntervalMs(int ms) async {
    _interval = clampInterval(Duration(milliseconds: ms));
    return enable();
  }

  /// On-demand fix, ignored until [enable] has been called.
  Future<void> refreshNow() async {
    if (!_enabled) return;
    await _tick();
  }

  /// Stops the refresh loop. [enable] starts a fresh one.
  void disable() {
    if (!_enabled) return;
    _enabled = false;
    _timer?.cancel();
    _timer = null;
    final dispose = _disposeResume;
    _disposeResume = null;
    dispose?.call();
  }

  Future<bool> _ensurePermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (error) {
      _debugLog('location permission request failed: $error');
      return false;
    }
  }

  void _onResume() {
    if (!_enabled) return;
    unawaited(_tick());
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!_enabled || _interval <= Duration.zero) return;
    _timer = Timer(_interval, () {
      _timer = null;
      unawaited(_tickThenSchedule());
    });
  }

  Future<void> _tickThenSchedule() async {
    await _tick();
    _schedule();
  }

  Future<void> _tick() async {
    if (_acquiring) return;
    _acquiring = true;
    try {
      final position = await Geolocator.getCurrentPosition();
      // Re-checked after the await: a disable() mid-fetch must not publish a
      // fix the caller just asked to stop collecting
      if (!_enabled) return;
      await _client.updateAttributes({
        'device_location': AttributeValue.numberList([
          position.latitude,
          position.longitude,
        ]),
      });
    } catch (error) {
      _debugLog('failed to read location: $error');
    } finally {
      _acquiring = false;
    }
  }
}

void _debugLog(String message) {
  assert(() {
    debugPrint('coproduct_location: $message');
    return true;
  }());
}
