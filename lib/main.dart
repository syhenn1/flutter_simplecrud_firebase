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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference dbRef = database.ref().child('mahasiswa');

  final TextEditingController nimController = TextEditingController();
  final TextEditingController namaController = TextEditingController();

  void tambahData(String nim, String nama) {
    dbRef.child(nim).set({
      'nim': nim,
      'nama': nama,
    });
  }

  void updateData(String nim, String newName) {
    dbRef.child(nim).update({'nama': newName});
  }

  void deleteData(String nim) {
    dbRef.child(nim).remove();
  }

  void showTambahDialog() {
    nimController.clear();
    namaController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Mahasiswa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nimController,
                decoration: const InputDecoration(labelText: 'NIM'),
              ),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                String nim = nimController.text;
                String nama = namaController.text;
                if (nim.isNotEmpty && nama.isNotEmpty) {
                  tambahData(nim, nama);
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void showUpdateDialog(String nim, String currentName) {
    TextEditingController updateController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Nama'),
          content: TextField(
            controller: updateController,
            decoration: const InputDecoration(labelText: 'Nama Baru'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                updateData(nim, updateController.text);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Mahasiswa')),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              showUpdateDialog(nim, nama);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteData(nim);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            return const Center(child: Text('Belum ada data'));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showTambahDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------- CHAT ROOM PAGE -------------------

class ChatRoomPage extends StatefulWidget {
  final String userNim;
  final String userName;

  const ChatRoomPage({super.key, required this.userNim, required this.userName});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final DatabaseReference chatRef = database.ref().child('chats');
  final TextEditingController chatController = TextEditingController();

  void sendMessage() {
    String text = chatController.text;
    if (text.isNotEmpty) {
      chatRef.child(widget.userNim).push().set({
        'from': widget.userNim,
        'message': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      chatController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat: ${widget.userName}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: chatRef.child(widget.userNim).orderByChild('timestamp').onValue,
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
                          child: Text(message),
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
