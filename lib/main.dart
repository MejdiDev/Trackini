import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:trackini/screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyDOpxju62yp0ITVWc3T1znoZDL5tKIFpYM",
        appId: "1:539477892852:android:eb9bc5373ecec94cbf88a1",
        messagingSenderId: "539477892852",
        projectId: "tracking-c7cb4"
    ),
  );

  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home:  MapScreen(),
    );
  }
}
