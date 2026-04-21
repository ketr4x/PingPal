import 'package:geolocator/geolocator.dart';

import '../helpers.dart';

Future<Position?> getCurrentLocation() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission != LocationPermission.whileInUse &&
      permission != LocationPermission.always) {
    return null;
  }

  final location = await Geolocator.getCurrentPosition();
  printDebug("Current location is $location");
  return location;
}
