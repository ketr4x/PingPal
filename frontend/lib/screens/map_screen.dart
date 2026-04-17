import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../handlers/database_handler.dart';
import '../handlers/location_service.dart';
import '../helpers.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _selectedIndex = 2;

  final uid = getUid();

  final _mapController = MapController();
  String? _selectedPingId;

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

  Marker _buildPingPopupMarker({
    required LatLng point,
    required String senderUid,
    required Timestamp timestamp,
  }) {
    final timestampText = _formatTimestamp(timestamp);

    return Marker(
      point: point,
      width: 200,
      height: 90,
      alignment: const Alignment(0, 0.65),
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Transform.translate(
              offset: const Offset(0, 30),
              child: Container(
                width: 150,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: FutureBuilder<String>(
                  future: _getUsernameFuture(senderUid),
                  builder: (context, usernameSnapshot) {
                    if (usernameSnapshot.connectionState != ConnectionState.done) {
                      return const Text(
                        'Loading user...',
                        textAlign: TextAlign.center,
                      );
                    }

                    if (usernameSnapshot.hasError) {
                      return const Text(
                        'Could not load user',
                        textAlign: TextAlign.center,
                      );
                    }

                    final username = usernameSnapshot.data ?? 'Unknown username';

                    return Text(
                      'Ping from $username\nSent at $timestampText',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  alignment: Alignment.bottomCenter,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              ];

              final List<Marker> pingMarkers = [];
              QueryDocumentSnapshot<Map<String, dynamic>>? selectedPingDoc;

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

                final point = LatLng(
                  rawLatitude.toDouble(),
                  rawLongitude.toDouble(),
                );

                if (doc.id == _selectedPingId) {
                  selectedPingDoc = doc;
                }

                pingMarkers.add(
                  Marker(
                    key: ValueKey(doc.id),
                    point: point,
                    width: 40,
                    height: 40,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPingId =
                              _selectedPingId == doc.id ? null : doc.id;
                        });
                      },
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  ),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_selectedPingId != null && selectedPingDoc == null) {
                  setState(() {
                    _selectedPingId = null;
                  });
                }
              });

              Marker? selectedPopupMarker;
              if (selectedPingDoc != null) {
                final data = selectedPingDoc.data();
                final rawLatitude = data['latitude'];
                final rawLongitude = data['longitude'];
                final rawSenderUid = data['sender'];
                final rawTimestamp = data['timestamp'];

                if (rawLatitude is num &&
                    rawLongitude is num &&
                    rawSenderUid is String &&
                    rawTimestamp is Timestamp) {
                  selectedPopupMarker = _buildPingPopupMarker(
                    point: LatLng(
                      rawLatitude.toDouble(),
                      rawLongitude.toDouble(),
                    ),
                    senderUid: rawSenderUid,
                    timestamp: rawTimestamp,
                  );
                }
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  onTap: (_, _) {
                    if (_selectedPingId != null) {
                      setState(() {
                        _selectedPingId = null;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ketr4x.pingpal',
                  ),
                  MarkerLayer(markers: staticMarkers),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 40,
                      size: const Size(40, 40),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(50),
                      markers: pingMarkers,
                      builder: (context, markers) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Center(
                            child: Text(
                              markers.length.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (selectedPopupMarker != null)
                    MarkerLayer(markers: [selectedPopupMarker]),
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