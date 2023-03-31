import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:intl/intl.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  String _messageText = '';
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
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
        // Add this line to clear the TextField after sending the message
        _messageController.clear();
      }
    } catch (e, stackTrace) {
      print('An error occurred while sending the message: $e\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
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
                    return Center(
                      child: ChatBubble(
                        clipper: ChatBubbleClipper2(
                            type: message['senderId'] == currentUser.email
                                ? BubbleType.sendBubble
                                : BubbleType.receiverBubble),
                        alignment: Alignment.center,
                        elevation: 4,
                        backGroundColor:
                            message['senderId'] == currentUser.email
                                ? Colors.white
                                : Colors.blueGrey.shade300,
                        margin:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  message['senderId'] ?? 'No user id',
                                  style: message['senderId'] ==
                                          currentUser.email
                                      ? TextStyle(fontWeight: FontWeight.bold)
                                      : TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                ),
                                Text(
                                  DateFormat('MMM d, y h:mm a')
                                      .format(message['timestamp'].toDate()),
                                  style: message['senderId'] ==
                                          currentUser.email
                                      ? TextStyle(fontWeight: FontWeight.w300)
                                      : TextStyle(
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              message['text'] ?? 'No message',
                              style: message['senderId'] == currentUser.email
                                  ? TextStyle(fontSize: 20, color: Colors.black)
                                  : TextStyle(
                                      fontSize: 20, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
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
                  child: Container(
                    margin: EdgeInsets.only(right: 80, bottom: 15, top: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              hintText: 'Type a message',
                            ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
