import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';

final database = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://flutter-test-9c5f7-default-rtdb.asia-southeast1.firebasedatabase.app/',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SelectUserPage(),
    );
  }
}

// ================= HALAMAN PILIH USER =================

class SelectUserPage extends StatefulWidget {
  const SelectUserPage({super.key});

  @override
  State<SelectUserPage> createState() => _SelectUserPageState();
}

class _SelectUserPageState extends State<SelectUserPage> {
  final DatabaseReference dbRef = database.ref().child('mahasiswa');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Sebagai User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder(
          stream: dbRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              Map<dynamic, dynamic> data =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List items = data.entries.toList();

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index].value;
                  final nim = item['nim'];
                  final nama = item['nama'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('$nama ($nim)'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomPage(userNim: nim, userName: nama),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }
            return const Center(child: Text('Belum ada data'));
          },
        ),
      ),
    );
  }
}

// =============== HALAMAN CHAT ROOM GLOBAL ===============

class ChatRoomPage extends StatefulWidget {
  final String userNim;
  final String userName;

  const ChatRoomPage({super.key, required this.userNim, required this.userName});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final DatabaseReference chatRef = database.ref().child('roomchat');
  final TextEditingController chatController = TextEditingController();

  void sendMessage() {
    String text = chatController.text;
    if (text.isNotEmpty) {
      chatRef.push().set({
        'from': widget.userNim,
        'name': widget.userName,
        'message': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      chatController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Roomchat - Login sbg: ${widget.userName}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: chatRef.orderByChild('timestamp').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List items = data.entries.toList()
                    ..sort((a, b) => (a.value['timestamp']).compareTo(b.value['timestamp']));

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index].value;
                      final from = item['from'];
                      final name = item['name'];
                      final message = item['message'];

                      bool isMe = from == widget.userNim;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              Text(message),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text('Belum ada chat'));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatController,
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
