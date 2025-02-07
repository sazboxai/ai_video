import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/trainer_profile.dart';

class Trainer {
  final String id;
  final String name;
  final String? bio;
  final String? profilePictureUrl;

  Trainer({
    required this.id,
    required this.name,
    this.bio,
    this.profilePictureUrl,
  });

  factory Trainer.fromMap(Map<String, dynamic> data, String id) {
    return Trainer(
      id: id,
      name: data['name'] ?? '',
      bio: data['bio'],
      profilePictureUrl: data['profilePictureUrl'],
    );
  }
}

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

  // Add this method to get current trainer data
  Future<Trainer?> getCurrentTrainer() async {
    try {
      if (currentUser == null) return null;

      final doc = await _firestore
          .collection('trainers')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) return null;

      return Trainer.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting trainer data: $e');
      return null;
    }
  }

  Future<void> checkAuthState() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Get fresh token
      final token = await user.getIdToken(true);
      print('[DEBUG] Auth check - User ID: ${user.uid}');
      print('[DEBUG] Auth check - Token available: ${token != null}');
      print('[DEBUG] Auth check - Email verified: ${user.emailVerified}');
    } else {
      print('[DEBUG] Auth check - No user logged in');
    }
  }
} 