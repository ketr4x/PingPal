import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../handlers/database_handler.dart';
import '../helpers.dart';
import '../widgets.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('PingPal')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: StreamBuilder(
            stream: _userDocStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                Center(child: Text('Something went wrong'));
              }
              if (!snapshot.hasData) {
                Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [

                ],
              );
            }
          ),
        ),
      ),
      bottomNavigationBar: bottomNavBar(context, _selectedIndex),
    );
  }
}
