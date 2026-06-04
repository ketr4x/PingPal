import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../handlers/database_handler.dart';
import '../helpers.dart';

class LinkAccountScreen extends StatefulWidget {
  const LinkAccountScreen({super.key});

  @override
  State<LinkAccountScreen> createState() => _LinkAccountScreenState();
}

class _LinkAccountScreenState extends State<LinkAccountScreen> {
  String? uid;
  String username = "Unknown";
  DateTime? accountCreated;
  String photoUrl = '';
  List<String> providers = [];

  @override
  void initState() {
    super.initState();
    _initProfileData();
    _getProviders();
  }

  Future<void> _initProfileData() async {
    final currentUid = getUid();
    final currentUsername = await getUsernameByUid(currentUid);

    final userDoc = await db.collection('Users').doc(currentUid).get();

    final timestamp = userDoc['account_created'] as Timestamp?;
    final time = timestamp?.toDate().toLocal();

    if (!mounted) return;
    setState(() {
      uid = currentUid;
      username = currentUsername;
      accountCreated = time;
      photoUrl = userDoc['photoUrl'];
    });
  }

  void _getProviders() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      providers = user!.providerData.map((info) => info.providerId).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Link Accounts')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    spacing: 10,
                    children: [
                      photoUrl != ''
                          ? CircleAvatar(
                              radius: 36,
                              backgroundImage: CachedNetworkImageProvider(
                                photoUrl,
                              ),
                            )
                          : Icon(Icons.account_circle, size: 72),
                      Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(username, style: TextStyle(fontSize: 18)),
                          Text(
                            'Account created on ${accountCreated != null ? DateFormat.yMMMd().format(accountCreated!) : 'Unknown'}',
                          ),
                          Text('Providers: ${providers.join(', ')}', overflow: .clip,)
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
