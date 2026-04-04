import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../helpers.dart';

class PagerScreen extends StatefulWidget {
  const PagerScreen({super.key});

  @override
  State<PagerScreen> createState() => _PagerScreenState();
}

class _PagerScreenState extends State<PagerScreen> {
  final _selectedIndex = 0;

  final usernameController = TextEditingController();

  FirebaseFirestore db = FirebaseFirestore.instance;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _pingsStream = db
      .collection('Pings')
      .where('receiver', isEqualTo: uid)
      .snapshots();
  bool _hasSeenFirstPingSnapshot = false;

  final uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? userData;

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pingsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_hasSeenFirstPingSnapshot) {
          _hasSeenFirstPingSnapshot = true;
        } else {
          final hasNewPing = snapshot.data!.docChanges.any(
            (c) => c.type == DocumentChangeType.added,
          );
          if (hasNewPing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You have been paged!'),
                  duration: Duration(seconds: 3),
                ),
              );
            });
          }
        }

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
                      sendPing(receiverUid);
                    },
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: bottomNavBar(context, _selectedIndex),
        );
      },
    );
  }
}
