import 'package:flutter/material.dart';

typedef OnCalendarFormSubmit = void Function(String title, String hexColor);

class CalendarForm extends StatefulWidget {
  final OnCalendarFormSubmit onSubmit;

  const CalendarForm({
    required this.onSubmit,
    super.key,
  });

  @override
  State<CalendarForm> createState() => _CalendarFormState();
}

class _CalendarFormState extends State<CalendarForm> {
  final _titleController = TextEditingController();
  final _colorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Calendar title',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }

              return null;
            },
          ),
          TextFormField(
            controller: _colorController,
            decoration: const InputDecoration(
              labelText: 'Calendar color',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }

              if (!value.startsWith('#')) {
                return 'Hex color should start with # (#RRGGBB)';
              }

              if (value.length != 7) {
                return 'Hex color should be 7 characters long (#RRGGBB)';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final title = _titleController.text;
                final hexColor = _colorController.text;
                widget.onSubmit(title, hexColor);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Creating calendar...')),
                );
              }
            },
            child: const Text('Create calendar'),
          ),
        ],
      ),
    );
  }
}