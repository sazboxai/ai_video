import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final trainer = await _authService.getCurrentTrainer();
    if (trainer != null) {
      setState(() {
        _bioController.text = trainer.bio ?? '';
        _nameController.text = trainer.name;
        _profilePictureUrl = trainer.profilePictureUrl;
      });
    }
  }

  Future<void> _updateProfilePicture({bool fromCamera = false}) async {
    try {
      final imagePath = await _profileService.pickImage(fromCamera: fromCamera);
      if (imagePath == null) return;

      final user = _authService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final downloadUrl = await _profileService.uploadProfilePicture(
        imagePath,
        user.uid,
      );

      setState(() {
        _profilePictureUrl = downloadUrl;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    try {
      setState(() => _isLoading = true);

      final user = _authService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      await _profileService.updateProfile(
        user.uid,
        bio: _bioController.text,
        name: _nameController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _profilePictureUrl != null
                      ? NetworkImage(_profilePictureUrl!)
                      : null,
                  child: _profilePictureUrl == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                FloatingActionButton.small(
                  onPressed: () => _showImageSourceDialog(),
                  child: const Icon(Icons.camera_alt),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
                hintText: 'Tell us about yourself...',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _updateProfilePicture(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _updateProfilePicture();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}