import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../helpers.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final usernameController = TextEditingController();

  FirebaseFirestore db = FirebaseFirestore.instance;

  final uid = FirebaseAuth.instance.currentUser!.uid;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search and add')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "Enter your friend's username"
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final username = usernameController.text.trim();
                    if (username.isEmpty) {
                      printDebug('Receiver username is empty');
                      return;
                    }
                    
                    final querySnapshot = await db.collection("Users").where("username", isEqualTo: username).get();

                    if (querySnapshot.docs.isEmpty) {
                      printDebug('Cannot find the user');
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Cannot find this user"),
                            duration: Duration(seconds: 3),
                          )
                        );
                      });
                      return;
                    }
                    final userDoc = querySnapshot.docs.first;

                    final currentUserDoc = await db.collection('Users').doc(uid).get();
                    if (currentUserDoc['friends'].contains(userDoc.get("uid"))) {
                      printDebug('User is already in friendlist');
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("User is already your friend"),
                            duration: Duration(seconds: 3),
                          )
                        );
                      });
                      return;
                    }

                    await db.collection('Users').doc(uid).update({
                      "friends": FieldValue.arrayUnion([userDoc.get("uid")])
                    }).then((val) {
                      printDebug('User added to friendlist');
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("User added to friendlist"),
                            duration: Duration(seconds: 3),
                          )
                        );
                      });
                    });
                    
                  } catch (e) {
                    printDebug('Unable to send the ping');
                  }
                },
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}