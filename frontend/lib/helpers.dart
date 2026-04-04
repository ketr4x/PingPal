import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/pager_screen.dart';
import 'screens/friends_screen.dart';

void printDebug(String text) {
  if (kDebugMode) {
    print(text);
  }
}

BottomNavigationBar bottomNavBar(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    items: [
      BottomNavigationBarItem(
        icon: Icon(Icons.notification_add),
        label: 'Pager',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Friends'),
    ],
    currentIndex: currentIndex,
    onTap: (index) {
      Widget page;
      switch (index) {
        case 0:
          page = PagerScreen();
          break;
        case 1:
          page = FriendsScreen();
          break;
        default:
          return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    },
  );
}

Future<void> sendPing(String receiverUid) async {
  try {
    final senderUid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore db = FirebaseFirestore.instance;

    if (receiverUid.isEmpty) {
      printDebug('Receiver username is empty');
      return;
    }

    await db.collection('Pings').add({
      'sender': senderUid,
      'receiver': receiverUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    printDebug('Unable to send the ping');
  }
}

Future<String> getUsernameByUid(String uid) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  final userDoc = await db.collection('Users').doc(uid).get();
  return userDoc.data()?['username'];
}

Future<String> getUidByUsername(String username) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  final userDoc = await db
      .collection('Users')
      .where('username', isEqualTo: username)
      .get();
  return userDoc.docs.first.id;
}
