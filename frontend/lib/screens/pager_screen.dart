import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../handlers/database_handler.dart';
import '../helpers.dart';

class PagerScreen extends StatefulWidget {
  const PagerScreen({super.key});

  @override
  State<PagerScreen> createState() => _PagerScreenState();
}

class _PagerScreenState extends State<PagerScreen> {
  final _selectedIndex = 0;

  final usernameController = TextEditingController();

  final uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? userData;

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pager')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "Enter your friend's username",
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final receiverUid = await getUidByUsername(
                    usernameController.text.trim(),
                  );
                  sendPing(receiverUid, false);
                },
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomNavBar(context, _selectedIndex),
    );
  }
}
