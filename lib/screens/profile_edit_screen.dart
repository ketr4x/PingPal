import 'package:flutter/material.dart';
import 'package:pingpal/helpers.dart';

import 'change_username_screen.dart';
import '../handlers/database_handler.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account and profile settings')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: ListView(
            children: [
              ListTile(
                title: Text('Change username'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeUsernameScreen(),
                      ),
                    );
                  },
                  child: Text('Change'),
                ),
              ),
              ListTile(
                title: Text('Sign out'),
                trailing: FilledButton(
                  onPressed: () async {
                    await signOut(context);
                  },
                  child: Text('Sign out'),
                ),
              ),
              ListTile(
                title: Text('Delete the account'),
                trailing: FilledButton(
                  style: ButtonStyle(backgroundColor: .all(Colors.red)),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Account Deletion'),
                      content: Text(
                        'Are you sure you want to delete your account? '
                        'All of your data will be deleted.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'Cancel'),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await deleteAccount(getUid());
                            if (!context.mounted) return;
                            Navigator.pop(context, 'Delete');
                            await signOut(context);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                  child: Text('Delete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
