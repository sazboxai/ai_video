import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../utils/exercise_constants.dart';

class AddLocationScreen extends StatefulWidget {
  @override
  _AddLocationScreenState createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _locationService = LocationService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  
  List<File> _selectedPhotos = [];
  List<String> _selectedEquipment = [];
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  void _addEquipment(String equipment) {
    if (!_selectedEquipment.contains(equipment)) {
      setState(() {
        _selectedEquipment.add(equipment);
        _equipmentController.clear();
      });
    }
  }

  void _removeEquipment(String equipment) {
    setState(() {
      _selectedEquipment.remove(equipment);
    });
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create location first
      final location = await _locationService.createLocation(
        trainerId: _authService.currentUser!.uid,
        name: _nameController.text,
        equipment: _selectedEquipment,
      );

      // Upload photos if any
      for (final photo in _selectedPhotos) {
        await _locationService.uploadLocationPhoto(location.locationId, photo);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Location'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveLocation,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Location Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Location Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a location name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Photos Section
            Text(
              'Photos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_selectedPhotos.isEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Photos'),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedPhotos.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedPhotos.length) {
                      return Center(
                        child: IconButton(
                          icon: const Icon(Icons.add_photo_alternate),
                          onPressed: _pickImage,
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Image.file(
                            _selectedPhotos[index],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () => _removePhoto(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Equipment Section
            Text(
              'Equipment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return ExerciseConstants.predefinedEquipment;
                }
                return ExerciseConstants.predefinedEquipment.where((equipment) =>
                    equipment.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: _addEquipment,
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Add Equipment',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (textEditingController.text.isNotEmpty) {
                          _addEquipment(textEditingController.text);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _selectedEquipment.map((equipment) {
                return Chip(
                  label: Text(equipment),
                  onDeleted: () => _removeEquipment(equipment),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
