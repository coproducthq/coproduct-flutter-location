/// GPS geo-fence location for the Coproduct Flutter SDK.
///
/// Opt-in: add this package only if you use geo-fence targeting. The main
/// `coproduct` package ships no location code, so an app that only reads
/// flags carries no location-permission API.
library;

export 'src/coproduct_location.dart' show CoproductLocation;
