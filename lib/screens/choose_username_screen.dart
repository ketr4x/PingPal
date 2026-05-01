import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../handlers/database_handler.dart';
import '../helpers.dart';

class ChooseUsernameScreen extends StatefulWidget {
  const ChooseUsernameScreen({super.key});

  @override
  State<ChooseUsernameScreen> createState() => _ChooseUsernameScreenState();
}

class _ChooseUsernameScreenState extends State<ChooseUsernameScreen> {
  final usernameController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your username')),
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
                    final uid = getUid();

                    final matchingUsernameUser = await db
                        .collection('Users')
                        .where(
                          'username_lower',
                          isEqualTo: usernameController.text
                              .trim()
                              .toLowerCase(),
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
                      "username_lower": usernameController.text
                          .trim()
                          .toLowerCase(),
                      "friends": [],
                      "fcm_token": await FirebaseMessaging.instance.getToken(),
                    });

                    if (!context.mounted) {
                      return;
                    }
                    enterApp(context, uid);
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
