import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final Map<String, Future<String>> usernameFutureCache = {};

enum AccountType { guest, google }
