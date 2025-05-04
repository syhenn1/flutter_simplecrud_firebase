import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';

final database = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: 'https://flutter-test-9c5f7-default-rtdb.asia-southeast1.firebasedatabase.app/', // Tanpa < >
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
  final DatabaseReference dbRef =
      database.ref().child('mahasiswa'); // Sudah pakai database yang benar

  final TextEditingController nimController = TextEditingController();
  final TextEditingController namaController = TextEditingController();

  void tambahData() {
    String nim = nimController.text;
    String nama = namaController.text;

    dbRef.child(nim).set({
      'nim': nim,
      'nama': nama,
    });

    nimController.clear();
    namaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realtime Database')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nimController,
              decoration: const InputDecoration(labelText: 'NIM'),
            ),
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            ElevatedButton(
              onPressed: tambahData,
              child: const Text('Tambah Mahasiswa'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: dbRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    Map<dynamic, dynamic> data =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    List items = data.entries.toList();

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index].value;
                        return ListTile(
                          title: Text('${item['nama']} (${item['nim']})'),
                        );
                      },
                    );
                  }
                  return const Text('Belum ada data');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
