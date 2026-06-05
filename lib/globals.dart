import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final Map<String, Future<String>> usernameFutureCache = {};

enum AccountType { guest, google }

final storageRef = FirebaseStorage.instance.ref();
