import 'package:coproduct/coproduct.dart' show CoproductClient;

import 'location_service.dart';

/// Opt-in GPS geo-fence location for a [CoproductClient].
///
/// The main `coproduct` package ships no location code, so an app that only
/// reads flags carries no location-permission API at all — not even a dead
/// code path Apple's App Store scanner could flag (ITMS-90683). Add this
/// package only if you use geo-fence targeting.
///
/// Each method takes the [CoproductClient] you already hold from
/// `Coproduct.initialize(...)`. State is held per client: a client that is
/// shut down and replaced by a later `initialize` call starts with location
/// off again.
final class CoproductLocation {
  CoproductLocation._();

  static final Expando<LocationService> _services = Expando();

  static LocationService _serviceFor(CoproductClient client) =>
      _services[client] ??= LocationService(client);

  /// Turn on GPS geo-fence targeting. Requests OS location permission (the
  /// first and only prompt), then starts a foreground refresh loop at the
  /// default 2-minute cadence, publishing `device_location` so geo-fence
  /// rules evaluate live. Opt-in: nothing happens until you call this.
  /// Returns whether permission was granted. Idempotent.
  static Future<bool> enable(CoproductClient client) =>
      _serviceFor(client).enable();

  /// Set the foreground refresh interval in milliseconds, enabling location
  /// if it was not already. `0` takes a single fix without a repeating loop;
  /// values below a 30-second floor are clamped. Returns whether permission
  /// was granted.
  static Future<bool> setUpdateInterval(
    CoproductClient client,
    int milliseconds,
  ) => _serviceFor(client).setIntervalMs(milliseconds);

  /// Read one GPS fix on demand and publish it. A no-op until location has
  /// been enabled for this client.
  static Future<void> refresh(CoproductClient client) =>
      _serviceFor(client).refreshNow();

  /// Stop the foreground refresh loop for this client. Call this alongside
  /// `Coproduct.shutdown()` if you want the GPS loop to stop rather than keep
  /// reading location in the background — it would otherwise just publish
  /// into a shut-down client, which is a harmless no-op, but still costs
  /// battery. [enable] starts the loop again.
  static void disable(CoproductClient client) {
    _services[client]?.disable();
  }
}
