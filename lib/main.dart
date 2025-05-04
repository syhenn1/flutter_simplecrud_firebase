import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
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
      title: 'CRUD Firebase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'CRUD Mahasiswa'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController nimController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController jurusanController = TextEditingController();

  final CollectionReference mahasiswaCollection =
      FirebaseFirestore.instance.collection('mahasiswa');

  // CREATE
  Future<void> tambahData() async {
    await mahasiswaCollection.doc(nimController.text).set({
      'nim': nimController.text,
      'nama': namaController.text,
      'jurusan': jurusanController.text,
    });
    clearInput();
  }

  // READ
  Stream<QuerySnapshot> bacaData() {
    return mahasiswaCollection.snapshots();
  }

  // UPDATE
  Future<void> updateData(String nim) async {
    await mahasiswaCollection.doc(nim).update({
      'nama': namaController.text,
      'jurusan': jurusanController.text,
    });
    clearInput();
  }

  // DELETE
  Future<void> hapusData(String nim) async {
    await mahasiswaCollection.doc(nim).delete();
  }

  void clearInput() {
    nimController.clear();
    namaController.clear();
    jurusanController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
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
            TextField(
              controller: jurusanController,
              decoration: const InputDecoration(labelText: 'Jurusan'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: tambahData,
                  child: const Text('Tambah'),
                ),
                ElevatedButton(
                  onPressed: () => updateData(nimController.text),
                  child: const Text('Update'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: bacaData(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final data = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final doc = data[index];
                      return ListTile(
                        title: Text('${doc['nama']} (${doc['nim']})'),
                        subtitle: Text(doc['jurusan']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => hapusData(doc['nim']),
                        ),
                        onTap: () {
                          // Isi field saat ditekan (untuk edit)
                          nimController.text = doc['nim'];
                          namaController.text = doc['nama'];
                          jurusanController.text = doc['jurusan'];
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
