import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:messages_board/services/firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:messages_board/firebase_options.dart'; 
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String boardId;
  final String boardName;

  ChatScreen({required this.boardId, required this.boardName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  bool _isFirebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      setState(() {
        _isFirebaseInitialized = true;
      });
    } catch (e) {
      print("Firebase initialization failed: $e");
    }
  }

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_messageController.text.isEmpty) return;

    try {
      await _firestoreService.addMessage(
        widget.boardId,
        user.displayName ?? 'Anonymous',
        _messageController.text,
      );
      _messageController.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFirebaseInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Initializing...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.boardName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getMessages(widget.boardId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No messages yet.'));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true, // Display the newest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final timestamp = message['timestamp'] != null
                        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(message['timestamp'].toDate())
                        : 'No timestamp';
                    return ListTile(
                      title: Text(message['username']),
                      subtitle: Text(message['message']),
                      trailing: Text(timestamp),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Enter message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}