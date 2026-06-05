import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:pingpal/widgets.dart';

import '../handlers/database_handler.dart';
import '../helpers.dart';

class LinkAccountScreen extends StatefulWidget {
  const LinkAccountScreen({super.key});

  @override
  State<LinkAccountScreen> createState() => _LinkAccountScreenState();
}

class _LinkAccountScreenState extends State<LinkAccountScreen> {
  final user = FirebaseAuth.instance.currentUser;

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
    final currentProviders = user!.providerData
        .map((info) => info.providerId)
        .toList();
    setState(() {
      providers = currentProviders.isNotEmpty ? currentProviders : ['Guest'];
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
            spacing: 12,
            crossAxisAlignment: .stretch,
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
                          Text(
                            'Providers: ${providers.join(', ')}',
                            overflow: .clip,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!providers.contains('google.com'))
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                  ),
                  onPressed: () async {
                    try {
                      await GoogleSignIn.instance.initialize(
                        serverClientId:
                            '526025104232-naf2pke6e52p3gvjp8s2imiiti8aqmid.apps.googleusercontent.com',
                      );

                      final googleUser = await GoogleSignIn.instance
                          .authenticate();
                      final googleAuth = googleUser.authentication;
                      final credential = GoogleAuthProvider.credential(
                        idToken: googleAuth.idToken,
                      );

                      try {
                        await user!.linkWithCredential(credential);

                        printDebug('Successfully linked a Google account');
                        if (context.mounted) {
                          showAdaptiveSnackBar(
                            context,
                            'Successfully linked a Google account',
                          );
                        }

                        _getProviders();
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'credential-already-in-use') {
                          printDebug(
                            'This Google account is already linked to another user',
                          );
                          if (context.mounted) {
                            showAdaptiveSnackBar(
                              context,
                              'This Google account is already linked to another user',
                            );
                          }
                        }
                      }
                    } catch (e) {
                      printDebug('Unable to connect account: $e');
                      if (context.mounted) {
                        showAdaptiveSnackBar(
                          context,
                          'Unable to connect account',
                        );
                      }
                    }
                  },
                  child: buildLoginRow('google', 30),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
