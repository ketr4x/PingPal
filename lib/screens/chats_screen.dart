import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../handlers/database_handler.dart';
import '../helpers.dart';
import '../widgets.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _selectedIndex = 0;

  final uid = getUid();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream = db
      .collection('Users')
      .doc(uid)
      .snapshots();

  Future<Map<String, Map<String, String>>> _loadFriendMap(
    List<String> friendUids,
  ) async {
    final entries = await Future.wait(
      friendUids.map((uid) async {
        final userDoc = await db.collection('Users').doc(uid).get();
        final data = userDoc.data();
        final username = (data?['username'] as String?) ?? '';
        final photoUrl = (data?['photoUrl'] as String?) ?? '';
        return MapEntry(uid, {'username': username, 'photoUrl': photoUrl});
      }),
    );
    return Map.fromEntries(entries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PingPal')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: StreamBuilder(
            stream: _userDocStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Something went wrong'));
              }
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final rawFriends = snapshot.data!.data()?['friends'];
              final friends = rawFriends is List
                  ? rawFriends.whereType<String>().toList()
                  : <String>[];

              if (friends.isEmpty) {
                return Text('No active chats');
              }

              return FutureBuilder(
                future: _loadFriendMap(friends),
                builder: (context, friendMapSnapshot) {
                  if (friendMapSnapshot.hasError) {
                    Center(child: Text('Something went wrong'));
                  }
                  if (!friendMapSnapshot.hasData) {
                    Center(child: CircularProgressIndicator());
                  }

                  final friendMap = friendMapSnapshot.data!;
                  final entriesList = friendMap.entries.toList();

                  return ListView.separated(
                    itemCount: entriesList.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entriesList[index];
                      final friendUid = entry.key;
                      final data = entry.value;
                      final username = data['username'];
                      final photoUrl = data['photoUrl'] ?? '';

                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(uid: friendUid),
                            ),
                          );
                        },
                        leading: photoUrl != ''
                            ? CircleAvatar(
                                radius: 36,
                                backgroundImage: CachedNetworkImageProvider(
                                  photoUrl,
                                ),
                              )
                            : Icon(Icons.account_circle, size: 54),
                        title: Text(username!),
                        //trailing: StreamBuilder(
                        //  stream: stream,
                        //  builder: builder,
                        //),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: bottomNavBar(context, _selectedIndex),
    );
  }
}
