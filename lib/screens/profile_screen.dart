import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'profile_edit_screen.dart';
import 'settings_screen.dart';
import '../handlers/database_handler.dart';
import '../helpers.dart';
import '../widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _selectedIndex = 3;

  String? uid;
  String username = "Unknown";
  String accountCreated = "Unknown";
  String photoUrl = '';
  int sentCount = 0;
  int receivedCount = 0;
  int followersCount = 0;
  int followingCount = 0;

  late Stream<QuerySnapshot<Map<String, dynamic>>> pingsStream = Stream.empty();

  @override
  void initState() {
    super.initState();
    _initPingsStream();
    _initProfileData();
    _loadStats();
  }

  Future<void> _initProfileData() async {
    final currentUid = getUid();
    final currentUsername = await getUsernameByUid(currentUid);

    final userDoc = await db.collection('Users').doc(currentUid).get();

    final timestamp = userDoc['account_created'] as Timestamp?;
    final sentAt = timestamp?.toDate().toLocal();
    final now = DateTime.now();

    final String time;
    if (sentAt == null) {
      time = 'Unknown';
    } else {
      final hh = sentAt.hour.toString().padLeft(2, '0');
      final mm = sentAt.minute.toString().padLeft(2, '0');
      final month = sentAt.month.toString().padLeft(2, '0');
      final day = sentAt.day.toString().padLeft(2, '0');

      final isToday =
          sentAt.year == now.year &&
          sentAt.month == now.month &&
          sentAt.day == now.day;

      if (isToday) {
        time = '$hh:$mm';
      } else if (sentAt.year == now.year) {
        time = '$month/$day $hh:$mm';
      } else {
        time = '${sentAt.year}/$month/$day $hh:$mm';
      }
    }

    if (!mounted) return;
    setState(() {
      uid = currentUid;
      username = currentUsername;
      accountCreated = time;
      photoUrl = userDoc['photoUrl'];
    });
  }

  Future<void> _loadStats() async {
    final currentUid = getUid();
    if (!mounted) return;

    final sentPings = db
        .collection('Pings')
        .where('sender', isEqualTo: currentUid);
    final sentPingsCount = await sentPings.count().get();

    final receivedPings = db
        .collection('Pings')
        .where('receiver', isEqualTo: currentUid);
    final receivedPingsCount = await receivedPings.count().get();

    final followers = db
        .collection('Users')
        .where('friends', arrayContains: currentUid);
    final currentFollowersCount = await followers.count().get();

    final following = await db.collection('Users').doc(uid).get();
    final followList = following['friends'] as List<dynamic>;
    final currentFollowingCount = followList.length;

    setState(() {
      sentCount = sentPingsCount.count ?? 0;
      receivedCount = receivedPingsCount.count ?? 0;
      followingCount = currentFollowingCount;
      followersCount = currentFollowersCount.count ?? 0;
    });
  }

  Future<void> _initPingsStream() async {
    final currentUid = getUid();
    if (!mounted) return;

    setState(() {
      pingsStream = db
          .collection('Pings')
          .where('receiver', isEqualTo: currentUid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileEditScreen()),
                );
                _initProfileData();
              },
              icon: Icon(Icons.edit),
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              ),
              icon: Icon(Icons.settings),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              spacing: 12,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      spacing: 10,
                      children: [
                        photoUrl != ''
                            ? CircleAvatar(
                                radius: 36,
                                backgroundImage: CachedNetworkImageProvider(
                                  photoUrl,
                                ),
                              )
                            : Icon(Icons.account_circle, size: 72),
                        Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(username, style: TextStyle(fontSize: 18)),
                            Text('PingPaling since $accountCreated'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(icon: Icon(Icons.query_stats)),
                            Tab(icon: Icon(Icons.notifications)),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              ListView(
                                children: [
                                  ListTile(
                                    title: Text('Pings sent'),
                                    trailing: Text(
                                      sentCount.toString(),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  ListTile(
                                    title: Text('Pings received'),
                                    trailing: Text(
                                      receivedCount.toString(),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  ListTile(
                                    title: Text('Friends'),
                                    trailing: Text(
                                      followingCount.toString(),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  ListTile(
                                    title: Text('Followers'),
                                    trailing: Text(
                                      followersCount.toString(),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              StreamBuilder(
                                stream: pingsStream,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == .waiting) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: const Text(
                                        "You haven't received any pings!",
                                      ),
                                    );
                                  }

                                  final docs = snapshot.data!.docs.toList();
                                  return Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 18,
                                        ),
                                        child: Text(
                                          'Last received pings:',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: docs.length,
                                          itemBuilder: (context, index) {
                                            final ping = docs[index];
                                            final doc = ping.data();
                                            final senderUid =
                                                doc['sender'] as String;

                                            final timestamp =
                                                doc['timestamp'] as Timestamp?;
                                            final sentAt = timestamp
                                                ?.toDate()
                                                .toLocal();
                                            final now = DateTime.now();

                                            final String time;
                                            if (sentAt == null) {
                                              time = 'Unknown';
                                            } else {
                                              final hh = sentAt.hour
                                                  .toString()
                                                  .padLeft(2, '0');
                                              final mm = sentAt.minute
                                                  .toString()
                                                  .padLeft(2, '0');
                                              final month = sentAt.month
                                                  .toString()
                                                  .padLeft(2, '0');
                                              final day = sentAt.day
                                                  .toString()
                                                  .padLeft(2, '0');

                                              final isToday =
                                                  sentAt.year == now.year &&
                                                  sentAt.month == now.month &&
                                                  sentAt.day == now.day;

                                              if (isToday) {
                                                time = '$hh:$mm';
                                              } else if (sentAt.year ==
                                                  now.year) {
                                                time = '$month/$day $hh:$mm';
                                              } else {
                                                time =
                                                    '${sentAt.year}/$month/$day $hh:$mm';
                                              }
                                            }

                                            return ListTile(
                                              title: FutureBuilder(
                                                future: getUsernameFuture(
                                                  senderUid,
                                                ),
                                                builder:
                                                    (
                                                      context,
                                                      usernameSnapshot,
                                                    ) {
                                                      if (!usernameSnapshot
                                                          .hasData) {
                                                        return const Text(
                                                          'Loading...',
                                                        );
                                                      }
                                                      return Text(
                                                        usernameSnapshot.data!,
                                                      );
                                                    },
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (doc.containsKey(
                                                        'latitude',
                                                      ) &&
                                                      doc.containsKey(
                                                        'longitude',
                                                      ))
                                                    const Icon(
                                                      Icons.location_pin,
                                                    ),
                                                  const SizedBox(width: 8),
                                                  Text(time),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: bottomNavBar(context, _selectedIndex),
      ),
    );
  }
}
