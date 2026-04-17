import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

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

  final Map<String, Future<String>> _usernameFutureCache = {};
  Future<String> _getUsernameFuture(String uid) {
    return _usernameFutureCache.putIfAbsent(uid, () => getUsernameByUid(uid));
  }

  final cutoff = Timestamp.fromDate(
    DateTime.now().subtract(const Duration(hours: 24)),
  );

  late final _pingsStream = db
      .collection('Pings')
      .where('receiver', isEqualTo: uid)
      .where('timestamp', isGreaterThanOrEqualTo: cutoff)
      .snapshots();

  String _formatTimestamp(Timestamp rawTs) {
    final dt = rawTs.toDate().toLocal();

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

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

              final List<Marker> pingMarkers = [];
              final Map<Marker, Map<String, dynamic>> markerMeta = {};

              for (final doc in pingSnapshot.data!.docs) {
                if (!doc.data().containsKey('latitude') ||
                    !doc.data().containsKey('longitude')) {
                  printDebug('Skipping ping ${doc.id}: no location data');
                  continue;
                }

                final rawLatitude = doc.get('latitude') as Object?;
                final rawLongitude = doc.get('longitude') as Object?;

                if (rawLatitude is! num || rawLongitude is! num) {
                  printDebug(
                    'Skipping ping ${doc.id} @ $rawLatitude $rawLongitude: invalid value}',
                  );
                  continue;
                }

                final pointLatitude = rawLatitude.toDouble();
                final pointLongitude = rawLongitude.toDouble();

                printDebug(
                  "Found a valid ping @ $pointLatitude $pointLongitude",
                );
                final marker = Marker(
                  point: LatLng(pointLatitude, pointLongitude),
                  child: Icon(Icons.location_pin, color: Colors.blue, size: 30),
                );
                pingMarkers.add(marker);

                final senderUid = doc.get('sender');
                final time = doc.get('timestamp');
                markerMeta[marker] = {
                  'senderUid': senderUid,
                  'timestamp': time,
                };
              }

              return PopupScope(
                child: FlutterMap(
                  mapController: MapController(),
                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ketr4x.pingpal',
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 30,
                        size: Size(30, 30),
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(50),
                        markers: [
                          Marker(
                            point: LatLng(latitude, longitude),
                            child: Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 30,
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
                        popupOptions: PopupOptions(
                          markerTapBehavior: MarkerTapBehavior.togglePopup(),
                          popupSnap: PopupSnap.markerTop,
                          popupBuilder: (context, marker) {
                            final meta = markerMeta[marker];
                            if (meta == null) return Text('Ping');

                            final senderUid = meta['senderUid'] as String;
                            final timestamp = _formatTimestamp(
                              meta['timestamp'],
                            );

                            return FutureBuilder(
                              future: _getUsernameFuture(senderUid),
                              builder: (context, usernameSnapshot) {
                                if (usernameSnapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const Text('Loading user...');
                                }
                                if (usernameSnapshot.hasError) {
                                  return const Text('Could not load user');
                                }

                                final username =
                                    usernameSnapshot.data ?? 'Unknown username';
                                return Card(
                                  child: Padding(
                                    padding: EdgeInsetsGeometry.all(8),
                                    child: Text(
                                      'Ping from $username\nSent at $timestamp',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
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
                ),
              );
            },
          ),
          bottomNavigationBar: bottomNavBar(context, _selectedIndex),
        );
      },
    );
  }
}
