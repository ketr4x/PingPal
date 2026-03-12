import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const PingPal());
}

class PingPal extends StatelessWidget {
  const PingPal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PingPal',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.black),
      ),
      home: const HomePage(title: 'PingPal'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [

          ],
        ),
      ),
    );
  }
}
