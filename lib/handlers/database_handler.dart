import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'location_service.dart';
import '../helpers.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Future<void> sendPing(String receiverUid, bool useLocation) async {
  try {
    final senderUid = getUid();
    double? longitude;
    double? latitude;

    if (receiverUid.isEmpty) {
      printDebug('Receiver username is empty');
      return;
    }

    if (useLocation) {
      final location = await getCurrentLocation();
      latitude = location?.latitude;
      longitude = location?.longitude;

      final invalid =
          latitude == null ||
          longitude == null ||
          !latitude.isFinite ||
          !longitude.isFinite;
      if (invalid) {
        printDebug('Not sending ping: invalid location');
        return;
      }
    }

    await db.collection('Pings').add({
      'sender': senderUid,
      'receiver': receiverUid,
      'timestamp': FieldValue.serverTimestamp(),
      if (useLocation) 'latitude': latitude,
      if (useLocation) 'longitude': longitude,
    });
  } catch (e) {
    printDebug('Unable to send the ping');
  }
}

Future<String> getUsernameByUid(String uid) async {
  final userDoc = await db.collection('Users').doc(uid).get();
  return userDoc.data()?['username'];
}

Future<String> getUidByUsername(String username) async {
  final userDoc = await db
      .collection('Users')
      .where('username', isEqualTo: username)
      .get();
  return userDoc.docs.first.id;
}

Future<void> updateFcmToken() async {
  final uid = getUid();

  await db.collection('Users').doc(uid).set({
    "fcm_token": await FirebaseMessaging.instance.getToken(),
  }, SetOptions(merge: true));
}

Future<bool> checkUserExists() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = await db.collection('Users').doc(user.uid).get();
    if (userDoc.exists) {
      return true;
    }
  }
  return false;
}

Future<bool> checkUserComplete() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = await db.collection('Users').doc(user.uid).get();
    if (userDoc.exists) {
      final username = userDoc.data()!.containsKey('username');
      final usernameLower = userDoc.data()!.containsKey('username_lower');
      if (username && usernameLower) {
        return true;
      }
    }
  }
  return false;
}
