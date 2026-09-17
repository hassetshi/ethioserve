import 'package:ethioserve/core/location/location_service.dart';

/// The real [LocationService] calls Geolocator's platform channels, which
/// never resolve inside `testWidgets` (no platform implementation is
/// registered and, unlike a plain `test()`, the widget-test binding doesn't
/// fail it fast with `MissingPluginException` - it just hangs, timing out
/// `pumpAndSettle`). Any widget test that reaches code calling
/// `locationServiceProvider` must override it with this instead.
class FakeLocationService implements LocationService {
  const FakeLocationService({this.location});

  final LatLng? location;

  @override
  Future<LatLng?> getCurrentLocation() async => location;
}
