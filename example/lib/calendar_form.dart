import 'package:flutter/material.dart';

typedef OnCalendarFormSubmit = void Function(String title, Color color);

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
  late final TextEditingController _titleController;
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    
    _titleController = TextEditingController();
    selectedColor = Colors.red;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Calendar title',
          ),
        ),
        DropdownButtonFormField(
          value: selectedColor,
          items: const [
            DropdownMenuItem(
              value: Colors.red,
              child: Text('Red'),
            ),
            DropdownMenuItem(
              value: Colors.green,
              child: Text('Green'),
            ),
            DropdownMenuItem(
              value: Colors.blue,
              child: Text('Blue'),
            ),
          ],
          onChanged: (Color? value) {
            setState(() {
              selectedColor = value ?? selectedColor;
            });
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text;
  
            widget.onSubmit(title, selectedColor);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Creating calendar...')),
            );
          },
          child: const Text('Create calendar'),
        ),
      ],
    );
  }
}