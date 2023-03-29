import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  String _messageText = '';

  void _sendMessage() {
    try {
      if (_messageText.isNotEmpty) {
        FirebaseFirestore.instance.collection('announcements').add({
          'text': _messageText,
          'senderId': FirebaseAuth.instance.currentUser?.email,
          'timestamp': Timestamp.now(),
        });
        setState(
          () {
            _messageText = '';
          },
        );
      }
    } catch (e, stackTrace) {
      print('An error occurred while sending the message: $e\n$stackTrace');
      // Handle the error gracefully.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    ;
                    return ListTile(
                      title: Text(message['text'] ?? 'No message'),
                      subtitle: Text(message['senderId'] ?? 'No message'),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: 'Type a message'),
                    onChanged: (value) {
                      setState(() {
                        _messageText = value;
                      });
                    },
                    onSubmitted: (value) {
                      _sendMessage();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
