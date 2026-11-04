# coproduct_location

Opt-in geo-fence location targeting for the [Coproduct](https://coproduct.app)
Flutter SDK. Requires location permission.

The main [`coproduct`](https://pub.dev/packages/coproduct) package ships no
location code. Add this package only if you use **geo-fence targeting**:
matching a flag or segment against a center latitude/longitude and a radius.
Apps that just read flags never carry any location-permission API, so they
never risk Apple's App Store scanner flagging a dead location code path
(`ITMS-90683`).

## Install

<!-- x-release-please-start-version -->
```yaml
dependencies:
  coproduct: ^0.1.1
  coproduct_location: ^0.1.1
```
<!-- x-release-please-end -->

Add the platform permission strings, since this package's only job is to
read location through [`geolocator`](https://pub.dev/packages/geolocator),
which requests permission on both platforms:

- iOS: `NSLocationWhenInUseUsageDescription` in `Info.plist`.
- Android: `ACCESS_FINE_LOCATION` (or `ACCESS_COARSE_LOCATION`) in your
  manifest.

Without these, the permission prompt cannot appear and `enable` returns
`false`.

## Usage

Author the fence in the dashboard: add a **Location (GPS)** condition with
the **within radius of** operator to a segment, set the center and radius,
and point your flag's targeting rule at that segment. This package's only
job is to supply the device's position as the `device_location` attribute.

**Data format.** A `within_radius` condition's values are three strings,
`[center_lat, center_lng, radius_meters]`, in that order. The attribute it
matches against, `device_location`, is a two-element number array,
`[lat, lng]`. Both are evaluated by `coproduct-core`'s haversine
great-circle distance, so a device is inside the fence when that distance to
the center is less than or equal to the radius:

```json
{
  "type": "attribute",
  "attribute": "device_location",
  "operator": "within_radius",
  "values": ["37.7749", "-122.4194", "500"]
}
```

This package never constructs that condition itself — it only supplies
`device_location`. The condition above is what the dashboard writes when you
author the fence, shown here so the shape is unambiguous if you're
inspecting a snapshot or writing a test fixture.

```dart
import 'package:coproduct/coproduct.dart';
import 'package:coproduct_location/coproduct_location.dart';

final client = await Coproduct.initialize(sdkKey: '...');

// Request permission and start supplying device_location.
// Returns whether permission was granted.
final granted = await CoproductLocation.enable(client);

// Optional: refresh on a foreground interval, in milliseconds.
// Default 2 minutes, 30s floor, 0 = a single fix with no repeating loop.
await CoproductLocation.setUpdateInterval(client, 120000);

// Force a one-off refresh, for example on a "near me" screen.
await CoproductLocation.refresh(client);

// Stop the refresh loop. enable() starts a fresh one.
CoproductLocation.disable(client);
```

Location is opt-in and keyed by the `CoproductClient` you already hold: the
permission popup appears the first time you call `enable` (or
`setUpdateInterval`), never at startup, and only once. Inside/outside is
delivered through the flag you already observe (`CoproductFlagBuilder` or a
`FlagObservation`); there is no separate geo-fence callback. When the device
crosses the fence, the flag re-evaluates and your observation rebuilds with
the new value.

If permission is denied or location services are off, `device_location`
stays unset and geo-fence rules fall through to the flag's default
variation. No errors, no crash.

Call `CoproductLocation.disable(client)` alongside `Coproduct.shutdown()` if
you want the GPS loop to stop. Publishing into a shut-down client is a
harmless no-op (per `coproduct`'s identity-call contract), but the loop would
otherwise keep reading location in the background until the process exits.

## `device_location` and your own attributes

This package publishes `device_location` through `CoproductClient.updateAttributes`,
the same call your own code would use to set any other attribute. That means
it behaves like any attribute you set yourself:

- Last write wins against your own `identify` / `setContext` /
  `updateAttributes` calls on the same key.
- `removeAttributes(['device_location'])` clears it, same as any attribute
  you set.

Don't also set `device_location` yourself — pick one source for that key.

## Example

See `example/` for a runnable demo: it seeds a snapshot with a 500m geo-fence
around a fixed point and shows a UI element that's enabled only when the
simulated GPS fix is inside it. Drive it on an iOS simulator with:

```
xcrun simctl location booted set 37.7749,-122.4194   # inside  -> enabled
xcrun simctl location booted set 37.8100,-122.4200   # outside -> disabled
```
