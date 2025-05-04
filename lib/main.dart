import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

final database = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL:
      'https://flutter-test-9c5f7-default-rtdb.asia-southeast1.firebasedatabase.app/',
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Chat',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthPage(),
    );
  }
}

// ======================= AUTH PAGE =======================

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  String errorMessage = '';

  void handleAuth() async {
    setState(() {
      errorMessage = ''; // Reset the error message
    });

    try {
      UserCredential userCredential;
      if (isLogin) {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        final uid = userCredential.user!.uid;
        await database.ref('mahasiswa/$uid').set({
          'email': userCredential.user!.email,
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            userNim: userCredential.user!.uid,
            userName: userCredential.user!.email ?? 'User',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        {
          errorMessage = 'Authentication failed. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleAuth,
              child: Text(isLogin ? 'Login' : 'Sign Up'),
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin
                  ? "Don't have an account? Sign Up"
                  : "Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= CHAT ROOM =======================

// ======================= CHAT ROOM DENGAN EDIT / HAPUS =======================

class ChatRoomPage extends StatefulWidget {
  final String userNim;
  final String userName;

  const ChatRoomPage(
      {super.key, required this.userNim, required this.userName});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final DatabaseReference chatRef = database.ref().child('roomchat');
  final TextEditingController chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void showOptions(String key, String currentMessage) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Pesan'),
            onTap: () {
              Navigator.pop(context);
              showEditDialog(key, currentMessage);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Hapus Pesan'),
            onTap: () {
              Navigator.pop(context);
              chatRef.child(key).remove();
            },
          ),
        ],
      ),
    );
  }

  void showEditDialog(String key, String currentMessage) {
    TextEditingController editController =
        TextEditingController(text: currentMessage);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pesan'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'Tulis pesan baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              chatRef.child(key).update({'message': editController.text});
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Roomchat - ${widget.userName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: chatRef.orderByChild('timestamp').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic> data =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List items = data.entries.toList()
                    ..sort((a, b) =>
                        (a.value['timestamp']).compareTo(b.value['timestamp']));

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final key = items[index].key;
                      final item = items[index].value;
                      final from = item['from'];
                      final name = item['name'];
                      final message = item['message'];
                      bool isMe = from == widget.userNim;

                      return GestureDetector(
                        onLongPress: isMe
                            ? () {
                                showOptions(key, message);
                              }
                            : null,
                        child: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                Text(message),
                              ],
                            ),
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
