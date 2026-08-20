import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../handlers/database_handler.dart';
import '../helpers.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.uid});
  final String uid;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final textController = TextEditingController();

  final myUid = getUid();

  String? username;
  String? photoUrl;
  String? roomId;

  late Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream =
      Stream.empty();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _initProfileData();
    await _initPingsStream();
  }

  Future<void> _initProfileData() async {
    final myUid = getUid();
    final currentUsername = await getUsernameFuture(widget.uid);
    final userDoc = await db.collection('Users').doc(widget.uid).get();
    final currentRoomId = generateRoomId(widget.uid, myUid);

    if (!mounted) return;
    setState(() {
      username = currentUsername;
      photoUrl = userDoc['photoUrl'];
      roomId = currentRoomId;
    });
  }

  Future<void> _initPingsStream() async {
    setState(() {
      messagesStream = db
          .collection('Chat')
          .doc(roomId)
          .collection('Messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(username ?? 'Loading...')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == .waiting) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return SizedBox();
                    }

                    final messages = snapshot.data!.docs.toList();
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final doc = message.data();
                        final sentByMe = doc['sender'] == myUid;

                        return Align(
                          alignment: sentByMe ? .centerRight : .centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * .75,
                            ),
                            child: Container(
                              margin: .symmetric(vertical: 6, horizontal: 8),
                              padding: .symmetric(vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: sentByMe
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.secondary,
                                borderRadius: .only(
                                  topLeft: .circular(12),
                                  topRight: .circular(12),
                                  bottomLeft: .circular(sentByMe ? 12 : 0),
                                  bottomRight: .circular(sentByMe ? 0 : 12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                doc['text'] ?? '',
                                style: TextStyle(
                                  color: sentByMe
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                spacing: 8,
                children: [
                  IconButton(
                    icon: Icon(Icons.photo),
                    onPressed: () {
                      
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Message',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (roomId == null) return;
                      sendMessage(roomId!, textController.text.trim());
                      textController.clear();
                    },
                    icon: Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
