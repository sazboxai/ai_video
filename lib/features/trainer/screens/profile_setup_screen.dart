import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/trainer_profile.dart';
import '../services/auth_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final _authService = AuthService();

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        // Upload image to Firebase Storage with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${_authService.currentUser!.uid}_$timestamp.jpg';
        
        // Use your specific bucket - matching the rules structure
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child(fileName);
        
        // Upload with metadata and error handling
        try {
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': _authService.currentUser!.uid,
              'uploadTime': DateTime.now().toIso8601String(),
            },
          );
          
          // Show upload progress (optional)
          final uploadTask = storageRef.putFile(_imageFile!, metadata);
          await uploadTask.whenComplete(() => null);
          
          // Get download URL
          imageUrl = await storageRef.getDownloadURL();
        } catch (storageError) {
          throw 'Failed to upload image: $storageError';
        }
      }

      // Create profile after successful image upload
      final profile = TrainerProfile(
        uid: _authService.currentUser!.uid,
        username: _usernameController.text,
        photoUrl: imageUrl,
        bio: _bioController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _authService.createTrainerProfile(profile);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/trainer/home');
      }
    } catch (e) {
      print('Error in profile setup: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null 
                    ? FileImage(_imageFile!) 
                    : null,
                  child: _imageFile == null
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
                maxLength: 150,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a bio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
} 