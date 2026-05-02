import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    usernameController.text =
        FirebaseAuth.instance.currentUser?.displayName?.replaceAll(' ', '') ??
        '';
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
                          final uid = getUid();
                          final username = usernameController.text.trim();

                          setState(() {
                            _isLoading = true;
                          });

                          final matchingUsernameUser = await db
                              .collection('Users')
                              .where(
                                'username_lower',
                                isEqualTo: username.toLowerCase(),
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

                          await db.collection('Users').doc(uid).set({
                            "username": username,
                            "username_lower": username.toLowerCase(),
                            "friends": [],
                            "fcm_token": await FirebaseMessaging.instance
                                .getToken(),
                          });

                          if (!context.mounted) {
                            return;
                          }
                          enterApp(context, uid);
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
