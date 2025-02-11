import 'package:flutter/material.dart';
import '../models/routine_generation_params.dart';

class AIRoutineDialog extends StatefulWidget {
  final List<String> availableEquipment;

  const AIRoutineDialog({
    Key? key,
    required this.availableEquipment,
  }) : super(key: key);

  @override
  _AIRoutineDialogState createState() => _AIRoutineDialogState();
}

class _AIRoutineDialogState extends State<AIRoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  int _numberOfDays = 3;
  int _durationMinutes = 45;
  String _fitnessGoal = '';
  late Set<String> _selectedEquipment;

  @override
  void initState() {
    super.initState();
    _selectedEquipment = Set.from(widget.availableEquipment);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.smart_toy, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('Generate AI Routine'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number of Days Slider
              const Text('Number of Days'),
              Slider(
                value: _numberOfDays.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: _numberOfDays.toString(),
                onChanged: (value) {
                  setState(() {
                    _numberOfDays = value.round();
                  });
                },
              ),
              
              // Duration Slider
              const Text('Workout Duration (minutes)'),
              Slider(
                value: _durationMinutes.toDouble(),
                min: 15,
                max: 120,
                divisions: 7,
                label: _durationMinutes.toString(),
                onChanged: (value) {
                  setState(() {
                    _durationMinutes = value.round();
                  });
                },
              ),
              
              // Fitness Goal TextField
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Fitness Goal',
                  hintText: 'e.g., Build Muscle, Lose Fat, Increase Endurance',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a fitness goal';
                  }
                  return null;
                },
                onSaved: (value) {
                  _fitnessGoal = value ?? '';
                },
              ),
              
              // Equipment Selection
              const SizedBox(height: 16),
              const Text('Available Equipment'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.availableEquipment.map((equipment) {
                  return FilterChip(
                    label: Text(equipment),
                    selected: _selectedEquipment.contains(equipment),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedEquipment.add(equipment);
                        } else {
                          _selectedEquipment.remove(equipment);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.of(context).pop(
                RoutineGenerationParams(
                  numberOfDays: _numberOfDays,
                  durationMinutes: _durationMinutes,
                  fitnessGoal: _fitnessGoal,
                  selectedEquipment: _selectedEquipment.toList(),
                ),
              );
            }
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }
}
