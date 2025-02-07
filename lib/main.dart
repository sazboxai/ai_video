import 'package:flutter/material.dart';
import 'features/authentication/screens/role_selection_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import your home screen (create this file if it doesn't exist)
import 'features/home/screens/home_screen.dart';
import 'features/trainer/screens/profile_setup_screen.dart';
import 'features/trainer/screens/trainer_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error loading .env file: $e');
    // Provide a fallback or handle the error appropriately
  }
  
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
        '/home': (context) => const HomeScreen(),
        '/trainer/setup': (context) => const ProfileSetupScreen(),
        '/trainer/home': (context) => const TrainerHomeScreen(),
      },
    );
  }
}
