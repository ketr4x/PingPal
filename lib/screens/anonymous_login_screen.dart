import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../handlers/database_handler.dart';
import '../helpers.dart';

class AnonymousLoginScreen extends StatefulWidget {
  const AnonymousLoginScreen({super.key});

  @override
  State<AnonymousLoginScreen> createState() => _AnonymousLoginScreenState();
}

class _AnonymousLoginScreenState extends State<AnonymousLoginScreen> {
  final usernameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in as a guest')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            children: [
              Form(
                key: formKey,
                child: TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Enter your username',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username cannot be empty';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters long';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                      return "Only letters, numbers and underscores are allowed";
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        try {
                          final userCredential = await FirebaseAuth.instance
                              .signInAnonymously();
                          final uid = userCredential.user?.uid;
                          final username = usernameController.text.trim();

                          setState(() {
                            _isLoading = true;
                          });

                          printDebug('Signed in with temporary account $uid');

                          NotificationSettings permission =
                              await FirebaseMessaging.instance
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
                                'username_lower',
                                isEqualTo: username
                                    .toLowerCase(),
                              )
                              .get();
                          if (matchingUsernameUser.docs.isNotEmpty) {
                            final docId = matchingUsernameUser.docs.first.id;
                            if (docId != uid) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Username is already taken'),
                                  ),
                                );
                              }
                              setState(() {
                                _isLoading = false;
                              });
                              return;
                            }
                          }

                          if (!context.mounted) {
                            return;
                          }

                          await getNotificationsPermission(context);
                          await db.collection('Users').doc(uid).set({
                            "username": username,
                            "username_lower": username
                                .toLowerCase(),
                            "friends": [],
                            "fcm_token": await FirebaseMessaging.instance
                                .getToken(),
                          });

                          if (!context.mounted) {
                            return;
                          }
                          enterApp(context, uid!);
                        } catch (e) {
                          printDebug('Unable to sign in: $e');
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
