import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../globals.dart';
import '../handlers/database_handler.dart';

class PingProvider extends ChangeNotifier {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pingsSub;
  bool _hasSeenFirstSnapshot = false;

  void handlePing() {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('You have been paged!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void startListening(String uid) {
    _pingsSub?.cancel();
    _hasSeenFirstSnapshot = false;

    _pingsSub = db
        .collection('Pings')
        .where('receiver', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          if (!_hasSeenFirstSnapshot) {
            _hasSeenFirstSnapshot = true;
            return;
          }

          final hasNewPing = snapshot.docChanges.any(
            (c) => c.type == DocumentChangeType.added,
          );

          if (hasNewPing) {
            handlePing();
          }
        });
  }

  Future<void> stopListening() async {
    await _pingsSub?.cancel();
    _pingsSub = null;
  }
}
