import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/location.dart';
import '../models/routine_program.dart' show RoutineProgram;
import '../services/location_service.dart';
import '../services/routine_program_service.dart';
import 'edit_routine_program_screen.dart';
import 'edit_location_screen.dart';
import 'photo_viewer_screen.dart';
import 'package:image_picker/image_picker.dart';

class LocationDetailScreen extends StatefulWidget {
  final Location location;

  const LocationDetailScreen({
    Key? key,
    required this.location,
  }) : super(key: key);

  @override
  _LocationDetailScreenState createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final _locationService = LocationService();
  final _routineProgramService = RoutineProgramService();
  final _pageController = PageController();
  final _imagePicker = ImagePicker();
  final _equipmentController = TextEditingController();
  late Location _location;
  List<RoutineProgram> _routinePrograms = [];

  @override
  void initState() {
    super.initState();
    _location = widget.location;
    _loadRoutinePrograms();
  }

  Future<void> _loadRoutinePrograms() async {
    final programs = await _routineProgramService.getRoutineProgramsForLocation(_location.locationId);
    if (mounted) {
      setState(() {
        _routinePrograms = programs;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _locationService.uploadLocationPhoto(
          _location.locationId,
          File(image.path),
        );

        // Refresh location data
        final updatedLocation = await _locationService.getLocationById(_location.locationId);
        if (updatedLocation != null && mounted) {
          setState(() {
            _location = updatedLocation;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add photo: $e')),
        );
      }
    }
  }

  void _openPhotoViewer([int initialIndex = 0]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          photoUrls: _location.photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _viewRoutineProgram(RoutineProgram program) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            AppBar(
              title: Text(program.name),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pop(context);
                    _editRoutineProgram(program);
                  },
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (program.equipment.isNotEmpty) ...[
                      const Text(
                        'Required Equipment:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: program.equipment.map((equipment) {
                          return Chip(
                            label: Text(equipment),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Program Outline:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: program.outline,
                      selectable: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editRoutineProgram(RoutineProgram program) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoutineProgramScreen(
          locationId: _location.locationId,
          program: program,
        ),
      ),
    );

    if (result == true) {
      await _loadRoutinePrograms();
    }
  }

  Future<void> _deleteRoutineProgram(RoutineProgram program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: const Text('Are you sure you want to delete this program?'),
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
        await _routineProgramService.deleteRoutineProgram(program.id);
        
        // Also update the location's routineProgramIds
        await _locationService.updateLocation(
          locationId: _location.locationId,
          name: _location.name,
          equipment: _location.equipment,
          photoUrls: _location.photoUrls,
          routineProgramIds: _location.routineProgramIds..remove(program.id),
        );
        
        await _loadRoutinePrograms();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete program: $e')),
          );
        }
      }
    }
  }

  Future<void> _addEquipment() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Equipment'),
        content: TextField(
          controller: _equipmentController,
          decoration: const InputDecoration(
            hintText: 'Enter equipment name',
            labelText: 'Equipment',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = _equipmentController.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final updatedEquipment = List<String>.from(_location.equipment)..add(result);
      try {
        await _locationService.updateLocation(
          locationId: _location.locationId,
          name: _location.name,
          equipment: updatedEquipment,
          photoUrls: _location.photoUrls,
          routineProgramIds: _location.routineProgramIds,
        );

        final updatedLocation = await _locationService.getLocationById(_location.locationId);
        if (updatedLocation != null && mounted) {
          setState(() {
            _location = updatedLocation;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipment added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add equipment: $e')),
          );
        }
      }
    }
    _equipmentController.clear();
  }

  Future<void> _scanEquipment() async {
    try {
      if (_location.photoUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add photos before scanning for equipment'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Scanning photos for equipment...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      try {
        // Call the Cloud Function
        final result = await FirebaseFunctions.instance
            .httpsCallable('detectGymEquipment')
            .call({'locationId': _location.locationId});

        // Dismiss loading dialog
        if (mounted) Navigator.pop(context);

        // Show success message
        if (mounted) {
          final detectedEquipment = (result.data['detectedEquipment'] as List).cast<String>();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detected ${detectedEquipment.length} pieces of equipment'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh location data to show new equipment
          final updatedLocation = await _locationService.getLocationById(_location.locationId);
          if (updatedLocation != null && mounted) {
            setState(() {
              _location = updatedLocation;
            });
          }
        }
      } catch (e) {
        // Dismiss loading dialog if it's showing
        if (mounted) Navigator.pop(context);
        
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error scanning equipment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Title Banner
          SliverAppBar(
            expandedHeight: 100.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _location.name,
                style: const TextStyle(fontSize: 18.0),
              ),
              titlePadding: const EdgeInsets.only(bottom: 16.0),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditLocationScreen(location: _location),
                    ),
                  );

                  if (result == true) {
                    final updatedLocation = await _locationService.getLocationById(_location.locationId);
                    if (updatedLocation != null && mounted) {
                      setState(() {
                        _location = updatedLocation;
                      });
                    }
                  }
                },
              ),
            ],
          ),

          // Image Carousel
          SliverToBoxAdapter(
            child: Container(
              height: 240,
              margin: const EdgeInsets.only(bottom: 16),
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _location.photoUrls.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _location.photoUrls.length) {
                        return InkWell(
                          onTap: _addPhoto,
                          child: Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return GestureDetector(
                        onTap: () => _openPhotoViewer(index),
                        child: Image.network(
                          _location.photoUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  if (_location.photoUrls.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: Center(
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: _location.photoUrls.length + 1,
                          effect: WormEffect(
                            dotHeight: 8,
                            dotWidth: 8,
                            type: WormType.thin,
                            activeDotColor: Theme.of(context).primaryColor,
                            dotColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Equipment Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Equipment',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _scanEquipment,
                            tooltip: 'Scan Photos for Equipment',
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addEquipment,
                            tooltip: 'Add Equipment',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_location.equipment.isEmpty)
                    const Text(
                      'No equipment added yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _location.equipment.map((equipment) {
                        return Chip(
                          label: Text(equipment),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          // Routine Programs List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Routine Programs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditRoutineProgramScreen(
                            locationId: _location.locationId,
                          ),
                        ),
                      );

                      if (result == true) {
                        await _loadRoutinePrograms();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_routinePrograms.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No routine programs yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final program = _routinePrograms[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        program.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        program.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: const Icon(Icons.description),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () => _editRoutineProgram(program),
                          ),
                          PopupMenuItem(
                            child: const ListTile(
                              leading: Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              title: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () => _deleteRoutineProgram(program),
                          ),
                        ],
                      ),
                      onTap: () => _viewRoutineProgram(program),
                    ),
                  );
                },
                childCount: _routinePrograms.length,
              ),
            ),
        ],
      ),
    );
  }
}
