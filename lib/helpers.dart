import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'handlers/database_handler.dart';
import 'screens/login_screen.dart';
import 'providers/ping_provider.dart';
import 'screens/pager_screen.dart';
import 'globals.dart';

void printDebug(String text) {
  if (kDebugMode) {
    print(text);
  }
}

String getUid() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return uid;
}

Future<void> getNotificationsPermission(BuildContext context) async {
  NotificationSettings permission = await FirebaseMessaging.instance
      .requestPermission();
  if (permission.authorizationStatus == AuthorizationStatus.denied) {
    printDebug('Notifications disabled');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notifications disabled'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }
}

void startListening(BuildContext context) {
  final uid = getUid();
  Provider.of<PingProvider>(context, listen: false).startListening(uid);
}

void enterApp(BuildContext context, String uid) {
  if (context.mounted) {
    Provider.of<PingProvider>(context, listen: false).startListening(uid);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => PagerScreen()),
      (Route<dynamic> route) => false,
    );
  }
}

Future<void> signOut(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Provider.of<PingProvider>(context, listen: false).stopListening();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  } catch (e) {
    printDebug('Cannot sign out: $e');
  }
}

Future<String> getUsernameFuture(String uid) {
  return usernameFutureCache.putIfAbsent(uid, () => getUsernameByUid(uid));
}

AccountType getAccountType(User? user) {
  if (user == null || user.isAnonymous) return AccountType.guest;

  for (final userInfo in user.providerData) {
    switch (userInfo.providerId) {
      case 'google.com':
        return AccountType.google;
    }
  }
  return AccountType.guest;
}
