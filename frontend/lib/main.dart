import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PingPal());
}

class PingPal extends StatelessWidget {
  const PingPal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PingPal',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.blue)),
      home: LoginScreen(),
    );
  }
}
