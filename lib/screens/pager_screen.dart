import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  String? uid;
  Map<String, dynamic>? userData;

  late Stream<QuerySnapshot<Map<String, dynamic>>> pingsStream = Stream.empty();

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initPingsStream();
  }

  Future<void> _initPingsStream() async {
    final currentUid = getUid();
    if (!mounted) return;

    setState(() {
      uid = currentUid;
      pingsStream = db
          .collection('Pings')
          .where('receiver', isEqualTo: currentUid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    });
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
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        final receiver = await db
                            .collection('Users')
                            .where(
                              'username',
                              isEqualTo: usernameController.text.trim(),
                            )
                            .get();
                        if (receiver.docs.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Receiver does not exist'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                          printDebug('Receiver does not exist');
                          return;
                        }
                        final receiverUid = await getUidByUsername(
                          usernameController.text.trim(),
                        );
                        sendPing(receiverUid, false);
                      },
                      child: const Icon(Icons.send),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        final receiver = await db
                            .collection('Users')
                            .where(
                              'username',
                              isEqualTo: usernameController.text.trim(),
                            )
                            .get();
                        if (receiver.docs.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Receiver does not exist'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                          printDebug('Receiver does not exist');
                          return;
                        }
                        final receiverUid = await getUidByUsername(
                          usernameController.text.trim(),
                        );
                        sendPing(receiverUid, true);
                      },
                      child: const Icon(Icons.location_pin),
                    ),
                  ),
                ],
              ),

              SingleChildScrollView(
                child: Card(
                  child: StreamBuilder(
                    stream: pingsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == .waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: const Text("You haven't received any pings!"),
                        );
                      }

                      return Column(
                        children: [
                          Text('Last pings:'),
                          ListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: snapshot.data!.docs.map((ping) {
                              final doc = ping.data();
                              final senderUid = doc['sender'] as String;

                              final timestamp = doc['timestamp'] as Timestamp;
                              final time = TimeOfDay.fromDateTime(
                                timestamp.toDate(),
                              ).format(context);

                              return ListTile(
                                title: FutureBuilder(
                                  future: getUsernameByUid(senderUid),
                                  builder: (context, usernameSnapshot) {
                                    if (!usernameSnapshot.hasData) {
                                      return Text('Loading...');
                                    }
                                    return Text(usernameSnapshot.data!);
                                  },
                                ),
                                trailing: Text(time),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomNavBar(context, _selectedIndex),
    );
  }
}
