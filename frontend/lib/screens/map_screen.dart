import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
//import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

import '../handlers/database_handler.dart';
import '../helpers.dart';
import '../handlers/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _selectedIndex = 2;

  final uid = getUid();

  final cutoff = Timestamp.fromDate(
    DateTime.now().subtract(const Duration(hours: 24)),
  );

  late final _pingsStream = db
      .collection('Pings')
      .where('receiver', isEqualTo: uid)
      .where('timestamp', isGreaterThanOrEqualTo: cutoff)
      .snapshots();

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
          body: StreamBuilder(
            stream: _pingsStream,
            builder: (context, pingSnapshot) {
              if (pingSnapshot.hasError) {
                return const Scaffold(
                  body: Center(child: Text('Something went wrong')),
                );
              }
              if (!pingSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              List<Marker> pingMarkers = [];
              for (final doc in pingSnapshot.data!.docs) {
                final pointLatitude = doc.get('latitude');
                final pointLongitude = doc.get('longitude');
                printDebug("Found a ping at $pointLatitude $pointLongitude");
                final marker = Marker(
                  point: LatLng(pointLatitude, pointLongitude),
                  child: Icon(Icons.location_pin, color: Colors.blue, size: 40),
                );
                pingMarkers.add(marker);
              }

              return FlutterMap(
                mapController: MapController(),
                options: MapOptions(initialCenter: LatLng(latitude, longitude)),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ketr4x.pingpal',
                  ),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 30,
                      size: Size(40, 40),
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(50),
                      markers: [
                        Marker(
                          point: LatLng(latitude, longitude),
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        ...pingMarkers,
                      ],
                      builder: (context, pingMarkers) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Center(
                            child: Text(pingMarkers.length.toString()),
                          ),
                        );
                      },
                    ),
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
              );
            },
          ),
          bottomNavigationBar: bottomNavBar(context, _selectedIndex),
        );
      },
    );
  }
}
