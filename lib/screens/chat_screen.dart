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

  String? username;
  String? photoUrl;
  String? roomId;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initProfileData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(username ?? 'Loading...')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            children: [
              Expanded(child: SizedBox()),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Message'
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (roomId == null) return;
                      sendMessage(roomId!, textController.text.trim());
                      textController.clear();
                    },
                    icon: Icon(Icons.send)
                  )
                ],
              )
            ],
          )
        ),
      ),
    );
  }
}
