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

  final Map<String, Future<String>> _usernameFutureCache = {};
  Future<String> _getUsernameFuture(String uid) {
    return _usernameFutureCache.putIfAbsent(uid, () => getUsernameByUid(uid));
  }

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
                mainAxisAlignment: .center,
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

              Expanded(
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

                      final docs = snapshot.data!.docs.toList();
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Last pings:'),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final ping = docs[index];
                                final doc = ping.data();
                                final senderUid = doc['sender'] as String;
                                final timestamp =
                                    doc['timestamp'] as Timestamp?;
                                final time = timestamp != null
                                    ? TimeOfDay.fromDateTime(
                                        timestamp.toDate(),
                                      ).format(context)
                                    : 'Unknown';

                                return ListTile(
                                  title: FutureBuilder(
                                    future: _getUsernameFuture(senderUid),
                                    builder: (context, usernameSnapshot) {
                                      if (!usernameSnapshot.hasData) {
                                        return const Text('Loading...');
                                      }
                                      return Text(usernameSnapshot.data!);
                                    },
                                  ),
                                  trailing: Text(time),
                                );
                              },
                            ),
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
