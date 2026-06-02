import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'handlers/background_handler.dart';
import 'providers/ping_provider.dart';
import 'globals.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  runApp(PingPal(savedThemeMode: savedThemeMode));
}

class PingPal extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  const PingPal({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PingProvider(),
      child: AdaptiveTheme(
        light: .light(useMaterial3: true),
        dark: .dark(useMaterial3: true),
        initial: savedThemeMode ?? AdaptiveThemeMode.system,
        builder: (theme, darkTheme) => MaterialApp(
          title: 'PingPal',
          theme: theme,
          darkTheme: darkTheme,
          home: LoginScreen(),
          scaffoldMessengerKey: rootScaffoldMessengerKey,
        ),
      ),
    );
  }
}
