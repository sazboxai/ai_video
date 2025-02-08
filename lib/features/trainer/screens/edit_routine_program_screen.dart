import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/location.dart';
import '../services/location_service.dart';

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
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationService = LocationService();
  bool _isLoading = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    if (widget.program != null) {
      _titleController.text = widget.program!.title;
      _contentController.text = widget.program!.markdownContent;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.program == null) {
        // Create new program
        await _locationService.addRoutineProgram(
          widget.locationId,
          _titleController.text,
          _contentController.text,
        );
      } else {
        // Update existing program
        final updatedProgram = RoutineProgram(
          programId: widget.program!.programId,
          title: _titleController.text,
          markdownContent: _contentController.text,
        );
        await _locationService.updateRoutineProgram(
          widget.locationId,
          updatedProgram,
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
            ),
            Expanded(
              child: _showPreview
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Markdown(
                        data: _contentController.text,
                        selectable: true,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          labelText: 'Content (Markdown)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          hintText: 'Write your routine program using Markdown...',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some content';
                          }
                          return null;
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
