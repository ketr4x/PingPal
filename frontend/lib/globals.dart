import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

FirebaseFirestore db = FirebaseFirestore.instance;