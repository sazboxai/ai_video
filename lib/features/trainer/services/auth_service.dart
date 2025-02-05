import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/trainer_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Create a new trainer profile
  Future<void> createTrainerProfile(TrainerProfile profile) async {
    try {
      // Check if user exists
      if (currentUser == null) {
        throw 'No authenticated user found';
      }

      // Create the trainers collection if it doesn't exist
      final trainerRef = _firestore.collection('trainers').doc(profile.uid);
      
      print('Creating trainer profile for uid: ${profile.uid}'); // Debug print
      
      await trainerRef.set(profile.toMap());
      
      print('Trainer profile created successfully'); // Debug print
    } catch (e) {
      print('Error creating trainer profile: $e'); // Debug print
      throw 'Failed to create trainer profile: ${e.toString()}';
    }
  }
} 