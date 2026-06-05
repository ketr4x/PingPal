import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../globals.dart';
import 'location_service.dart';
import '../helpers.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Future<void> createAccount(
  String? uid,
  String username,
  AccountType type,
) async {
  try {
    await db.collection('Users').doc(uid).set({
      "username": username,
      "username_lower": username.toLowerCase(),
      "friends": [],
      "fcm_token": await FirebaseMessaging.instance.getToken(),
      "account_created": FieldValue.serverTimestamp(),
      "photoUrl": '',
    });

    printDebug('Created account with uid $uid');
  } catch (e) {
    printDebug('Unable to create account: $e');
  }
}

Future<void> deleteAccount(String uid) async {
  try {
    final sentPings = await db
        .collection('Pings')
        .where("sender", isEqualTo: uid)
        .get();
    final receivedPings = await db
        .collection('Pings')
        .where("receiver", isEqualTo: uid)
        .get();
    final deletedPingIds = <String>{};

    for (var doc in sentPings.docs) {
      if (!deletedPingIds.contains(doc.id)) {
        await doc.reference.delete();
        deletedPingIds.add(doc.id);
      }
    }
    for (var doc in receivedPings.docs) {
      if (!deletedPingIds.contains(doc.id)) {
        await doc.reference.delete();
        deletedPingIds.add(doc.id);
      }
    }

    await db.collection('Users').doc(uid).delete();
    await FirebaseAuth.instance.currentUser?.delete();
    await storageRef.child('avatars/$uid').delete();
    printDebug('Deleted account with uid $uid');
  } catch (e) {
    printDebug('Unable to delete account');
  }
}

Future<void> sendPing(String receiverUid, bool useLocation) async {
  try {
    final senderUid = getUid();
    double? longitude;
    double? latitude;

    if (receiverUid.isEmpty) {
      printDebug('Receiver username is empty');
      return;
    }

    final receiver = await db.collection('Users').doc(receiverUid).get();
    if (!receiver.exists) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Receiver does not exist'),
          duration: Duration(seconds: 3),
        ),
      );
      printDebug('Receiver does not exist');
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

    printDebug('Sent a ping to $receiverUid');
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Sent a ping!'), duration: Duration(seconds: 3)),
    );
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

Future<void> deleteFriend(String friendUid) async {
  try {
    final uid = getUid();

    await db.collection('Users').doc(uid).update({
      "friends": FieldValue.arrayRemove([friendUid]),
    });

    printDebug('Removed friend $friendUid from $uid');
  } catch (e) {
    printDebug('Unable to remove friend');
  }
}

Future<void> sendMessage(String roomId, String message) async {
  final uid = getUid();

  try {
    await db.collection('Chat').doc(roomId).collection('Messages').add({
      'sender': uid,
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    printDebug('Cannot send message: $e');
  }
}
