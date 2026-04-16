import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../globals.dart';
import '../helpers.dart';
import '../handlers/database_handler.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _selectedIndex = 1;

  final uid = FirebaseAuth.instance.currentUser!.uid;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream = db
      .collection('Users')
      .doc(uid)
      .snapshots();

  Future<Map<String, String>> _loadFriendMap(List<String> friendUids) async {
    final entries = await Future.wait(
      friendUids.map((uid) async {
        final username = await getUsernameByUid(uid);
        return MapEntry(uid, username);
      }),
    );
    return Map.fromEntries(entries);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _userDocStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final rawFriends = snapshot.data!.data()?['friends'];
        final friends = rawFriends is List
            ? rawFriends.whereType<String>().toList()
            : <String>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Friends'),
            actions: [
              IconButton(
                onPressed: () {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFriendScreen(),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.add),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Column(
                children: [
                  Expanded(
                    child: FutureBuilder(
                      future: _loadFriendMap(friends),
                      builder: (context, friendMapSnapshot) {
                        if (!friendMapSnapshot.hasData) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final friendMap = friendMapSnapshot.data!;

                        return ListView(
                          children: friendMap.entries.map((entry) {
                            final friendUid = entry.key;
                            final username = entry.value;

                            return Card(
                              child: ListTile(
                                title: Text(username),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          sendPing(friendUid, false),
                                      icon: Icon(Icons.notification_add),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          sendPing(friendUid, true),
                                      icon: Icon(Icons.location_pin),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: bottomNavBar(context, _selectedIndex),
        );
      },
    );
  }
}
