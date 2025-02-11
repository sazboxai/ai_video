import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/routine_program.dart';
import '../services/routine_program_service.dart';

class EditRoutineProgramScreen extends StatefulWidget {
  final String locationId;
  final RoutineProgram? program;

  const EditRoutineProgramScreen({
    Key? key,
    required this.locationId,
    this.program,
  }) : super(key: key);

  @override
  _EditRoutineProgramScreenState createState() => _EditRoutineProgramScreenState();
}

class _EditRoutineProgramScreenState extends State<EditRoutineProgramScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _outlineController = TextEditingController();
  final _routineProgramService = RoutineProgramService();
  final List<String> _selectedEquipment = [];
  bool _isLoading = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    if (widget.program != null) {
      _nameController.text = widget.program!.name;
      _descriptionController.text = widget.program!.description;
      _outlineController.text = widget.program!.outline;
      _selectedEquipment.addAll(widget.program!.equipment);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _outlineController.dispose();
    super.dispose();
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.program == null) {
        // Create new program
        await _routineProgramService.createRoutineProgram(
          name: _nameController.text,
          description: _descriptionController.text,
          equipment: _selectedEquipment,
          outline: _outlineController.text,
          locationId: widget.locationId,
        );
      } else {
        // Update existing program
        await _routineProgramService.updateRoutineProgram(
          id: widget.program!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          equipment: _selectedEquipment,
          outline: _outlineController.text,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save program: $e')),
        );
      }
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
        title: Text(widget.program == null ? 'New Program' : 'Edit Program'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
          ),
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
              onPressed: _saveProgram,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Equipment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _selectedEquipment
                          .map((equipment) => Chip(
                                label: Text(equipment),
                                onDeleted: () {
                                  setState(() {
                                    _selectedEquipment.remove(equipment);
                                  });
                                },
                              ))
                          .toList(),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Add equipment...',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _selectedEquipment.add(value);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_showPreview)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      MarkdownBody(
                        data: _outlineController.text,
                        selectable: true,
                      ),
                    ],
                  ),
                ),
              )
            else
              TextFormField(
                controller: _outlineController,
                maxLines: null,
                minLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Outline (Markdown)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  hintText: 'Write your routine program using Markdown...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the outline';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }
}
