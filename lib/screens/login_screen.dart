import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../handlers/database_handler.dart';
import '../providers/ping_provider.dart';
import 'pager_screen.dart';
import '../helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter your username',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final userCredential = await FirebaseAuth.instance
                        .signInAnonymously();
                    final uid = userCredential.user?.uid;

                    printDebug('Signed in with temporary account $uid');

                    NotificationSettings permission = await FirebaseMessaging
                        .instance
                        .requestPermission();
                    if (permission.authorizationStatus ==
                        AuthorizationStatus.denied) {
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

                    final matchingUsernameUser = await db
                        .collection('Users')
                        .where(
                          'username',
                          isEqualTo: usernameController.text.trim(),
                        )
                        .get();
                    if (matchingUsernameUser.docs.isNotEmpty) {
                      final docId = matchingUsernameUser.docs.first.id;
                      if (docId != uid) {
                        printDebug('Username is already taken');
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Username is already taken'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        });
                        throw Exception('Username is already taken');
                      }
                    }

                    await db.collection('Users').doc(uid).set({
                      "username": usernameController.text.trim(),
                      "friends": [],
                      "fcm_token": await FirebaseMessaging.instance.getToken(),
                    });

                    if (context.mounted) {
                      Provider.of<PingProvider>(
                        context,
                        listen: false,
                      ).startListening(uid!);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => PagerScreen()),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    printDebug('Unable to sign in: $e');
                  }
                },
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
