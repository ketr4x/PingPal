import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../globals.dart';
import '../helpers.dart';
import '../handlers/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _selectedIndex = 2;

  final query = db;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getCurrentLocation(),
      builder: (context, locationSnapshot) {
        if (locationSnapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong')),
          );
        }
        if (!locationSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final latitude = locationSnapshot.data?.latitude;
        final longitude = locationSnapshot.data?.longitude;
        if (latitude == null ||
            longitude == null ||
            !latitude.isFinite ||
            !longitude.isFinite) {
          return const Scaffold(
            body: Center(child: Text('Cannot get valid location data')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Map')),
          body: FlutterMap(
            mapController: MapController(),
            options: MapOptions(initialCenter: LatLng(latitude, longitude)),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ketr4x.pingpal',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latitude, longitude),
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.parse('https://openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: bottomNavBar(context, _selectedIndex),
        );
      },
    );
  }
}
