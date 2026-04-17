import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../handlers/database_handler.dart';
import '../handlers/location_service.dart';
import '../helpers.dart';

class PingMarker extends Marker {
  const PingMarker({
    required this.senderUid,
    required this.timestamp,
    required super.point,
  }) : super(
         width: 40,
         height: 40,
         child: const Icon(Icons.location_pin, color: Colors.blue, size: 30),
       );

  final String senderUid;
  final Timestamp timestamp;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _selectedIndex = 2;

  final uid = getUid();

  final _mapController = MapController();
  final _popupController = PopupController();

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

              final List<Marker> staticMarkers = [
                Marker(
                  point: LatLng(latitude, longitude),
                  key: const ValueKey('current-location'),
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              ];

              final List<Marker> pingMarkers = [];

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

                final rawSenderUid = doc.data()['sender'];
                final rawTimestamp = doc.data()['timestamp'];

                if (rawSenderUid is! String || rawTimestamp is! Timestamp) {
                  printDebug(
                    'Skipping ping ${doc.id}: sender or timestamp has invalid type',
                  );
                  continue;
                }

                final pointLatitude = rawLatitude.toDouble();
                final pointLongitude = rawLongitude.toDouble();

                pingMarkers.add(
                  PingMarker(
                    senderUid: rawSenderUid,
                    timestamp: rawTimestamp,
                    point: LatLng(pointLatitude, pointLongitude),
                  ),
                );
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  onTap: (_, __) => _popupController.hideAllPopups(),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ketr4x.pingpal',
                  ),
                  MarkerLayer(markers: staticMarkers),
                  PopupMarkerLayer(
                    options: PopupMarkerLayerOptions(
                      markers: pingMarkers,
                      popupController: _popupController,
                      markerTapBehavior:
                          MarkerTapBehavior.togglePopupAndHideRest(),
                      popupDisplayOptions: PopupDisplayOptions(
                        builder: (context, marker) {
                          if (marker is! PingMarker) {
                            return const SizedBox.shrink();
                          }

                          final timestamp = _formatTimestamp(marker.timestamp);

                          return SizedBox(
                            width: 220,
                            child: FutureBuilder<String>(
                              future: _getUsernameFuture(marker.senderUid),
                              builder: (context, usernameSnapshot) {
                                if (usernameSnapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Loading user...'),
                                    ),
                                  );
                                }

                                if (usernameSnapshot.hasError) {
                                  return const Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Could not load user'),
                                    ),
                                  );
                                }

                                final username =
                                    usernameSnapshot.data ?? 'Unknown username';

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Ping from $username\nSent at $timestamp',
                                    ),
                                  ),
                                );
                              },
                            ),
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
              );
            },
          ),
          bottomNavigationBar: bottomNavBar(context, _selectedIndex),
        );
      },
    );
  }
}
