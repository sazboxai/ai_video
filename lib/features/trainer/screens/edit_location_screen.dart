import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditLocationScreen extends StatefulWidget {
  final Location? location;

  const EditLocationScreen({Key? key, this.location}) : super(key: key);

  @override
  _EditLocationScreenState createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  final _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _scrollController = ScrollController();
  List<String> _selectedEquipment = [];
  List<String> _photoUrls = [];
  List<String> _equipmentSuggestions = [
    'Dumbbells', 'Barbell', 'Squat Rack', 'Bench Press',
    'Treadmill', 'Exercise Bike', 'Elliptical', 'Rowing Machine',
    'Kettlebells', 'Resistance Bands', 'Yoga Mat', 'Pull-up Bar',
    'Medicine Ball', 'Foam Roller', 'Jump Rope', 'Weight Plates',
    'Cable Machine', 'Smith Machine', 'Leg Press', 'Battle Ropes'
  ];
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      _nameController.text = widget.location!.name;
      _selectedEquipment = List.from(widget.location!.equipment);
      _photoUrls = List.from(widget.location!.photoUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _equipmentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterEquipment(String query) {
    setState(() {
      _filteredSuggestions = _equipmentSuggestions
          .where((equipment) =>
              equipment.toLowerCase().contains(query.toLowerCase()) &&
              !_selectedEquipment.contains(equipment))
          .toList();
    });
  }

  void _addEquipment(String equipment) {
    setState(() {
      if (!_selectedEquipment.contains(equipment)) {
        _selectedEquipment.add(equipment);
      }
      _equipmentController.clear();
      _filteredSuggestions.clear();
    });
  }

  void _removeEquipment(String equipment) {
    setState(() {
      _selectedEquipment.remove(equipment);
    });
  }

  Future<void> _addPhoto() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // Show confirmation dialog with preview
        final bool? shouldUpload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Photos'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected ${images.length} photos to upload:'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(images[index].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Upload'),
              ),
            ],
          ),
        );

        if (shouldUpload == true) {
          // Show loading indicator
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final locationId = widget.location?.locationId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
          
          // Upload all images
          for (final image in images) {
            final String photoUrl = await _locationService.uploadLocationPhoto(
              locationId,
              File(image.path),
            );
            setState(() {
              _photoUrls.add(photoUrl);
            });
          }

          // Dismiss loading indicator
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully uploaded ${images.length} photos'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Dismiss loading indicator if it's showing
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoUrls.removeAt(index);
    });
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      if (widget.location == null) {
        // Create new location
        await _locationService.createLocation(
          trainerId: currentUser.uid,
          name: _nameController.text,
          equipment: _selectedEquipment,
          photoUrls: _photoUrls,
        );
      } else {
        // Update existing location
        await _locationService.updateLocation(
          locationId: widget.location!.locationId,
          name: _nameController.text,
          equipment: _selectedEquipment,
          photoUrls: _photoUrls,
          routinePrograms: widget.location!.routinePrograms,
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location == null ? 'Add Location' : 'Edit Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveLocation,
          ),
          if (widget.location != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Location'),
                    content: const Text('Are you sure you want to delete this location?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await _locationService.deleteLocation(widget.location!.locationId);
                    if (mounted) {
                      Navigator.pop(context, true);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete location: $e')),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
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
            Text(
              'Photos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photoUrls.length + 1,
                itemBuilder: (context, index) {
                  if (index == _photoUrls.length) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: _addPhoto,
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_photo_alternate, size: 32),
                              SizedBox(height: 4),
                              Text('Add Photo'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _photoUrls[index],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _removePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Equipment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedEquipment.map((equipment) {
                return Chip(
                  label: Text(equipment),
                  onDeleted: () => _removeEquipment(equipment),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _equipmentController,
              decoration: const InputDecoration(
                labelText: 'Add Equipment',
                border: OutlineInputBorder(),
                hintText: 'Type to search equipment...',
              ),
              onChanged: _filterEquipment,
            ),
            if (_filteredSuggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_filteredSuggestions[index]),
                      onTap: () {
                        _addEquipment(_filteredSuggestions[index]);
                        // Scroll the screen up when keyboard appears
                        _scrollController.animateTo(
                          _scrollController.offset + 100,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
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
