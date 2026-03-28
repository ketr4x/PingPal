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
  final usernameController = TextEditingController();

  FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _pingsStream;
  bool _hasSeenFirstPingSnapshot = false;

  final uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? userData;
  
  Future<void> _loadUserData() async{
    try {
      final doc = await db.collection('Users').doc(uid).get();
      final data = doc.data();

      if (!mounted) return;
      setState(() {
        userData = data;
        final username = userData?['username'] as String?;
        if (username != null && username.isNotEmpty) {
          _pingsStream = db.collection('Pings').where('receiver', isEqualTo: username).snapshots();
        }
      });
    } catch (e) {
      printDebug('Error getting user info: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pingsStream == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pingsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong'))
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
          final hasNewPing = snapshot.data!.docChanges.any((c) => c.type == DocumentChangeType.added);
          if (hasNewPing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You have been paged!'),
                  duration: Duration(seconds: 3),
                )
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
                      try {
                        final sender = userData?['username'] as String?;
                        if (sender == null || sender.isEmpty) {
                          printDebug('User data not loaded yet');
                          return;
                        }

                        final receiver = usernameController.text.trim();
                        if (receiver.isEmpty) {
                          printDebug('Receiver username is empty');
                          return;
                        }

                        await db.collection('Pings').add({
                          'sender': sender,
                          'receiver': receiver,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                      } catch (e) {
                        printDebug('Unable to send the ping');
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
    );
  }
}
