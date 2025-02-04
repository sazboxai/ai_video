import 'package:flutter/material.dart';
import 'features/authentication/screens/role_selection_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import your home screen (create this file if it doesn't exist)
import 'features/home/screens/home_screen.dart';

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
      title: 'Fitness AI Trainer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Define your routes
      initialRoute: '/',
      routes: {
        '/': (context) => const RoleSelectionScreen(),
        '/home': (context) => const HomeScreen(), // Add your home screen
      },
    );
  }
}
