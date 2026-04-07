import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'providers/ping_provider.dart';
import 'globals.dart';
import 'firebase_options.dart';
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
    return ChangeNotifierProvider(
      create: (_) => PingProvider(),
      child: MaterialApp(
        title: 'PingPal',
        theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.blue)),
        home: LoginScreen(),
        scaffoldMessengerKey: rootScaffoldMessengerKey,
      ),
    );
  }
}
