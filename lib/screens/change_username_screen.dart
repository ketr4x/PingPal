import 'package:flutter/material.dart';

import '../handlers/database_handler.dart';
import '../helpers.dart';

class ChangeUsernameScreen extends StatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
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
      appBar: AppBar(title: const Text('Change your username')),
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

                          await db.collection('Users').doc(uid).update({
                            "username": username,
                            "username_lower": username.toLowerCase(),
                          });

                          if (!context.mounted) {
                            return;
                          }

                          printDebug('Changed the username');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Changed the username'),
                              duration: Duration(seconds: 3),
                            ),
                          );

                          Navigator.of(context).pop(context);
                        } catch (e) {
                          printDebug('Unable to change username: $e');
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
