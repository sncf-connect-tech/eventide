// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

typedef OnCalendarFormSubmit = void Function(String title, Color color, String accountName);

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
  late final TextEditingController _accountController;
  late Color selectedColor;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _accountController = TextEditingController();
    selectedColor = Colors.red;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _accountController.dispose();
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
        const SizedBox(height: 16),
        TextFormField(
          controller: _accountController,
          decoration: const InputDecoration(
            labelText: 'Account name (Optional)',
            hintText: 'Default: Eventide App',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Color>(
          value: selectedColor,
          decoration: const InputDecoration(
            labelText: 'Calendar color',
          ),
          items: const [
            DropdownMenuItem(
              value: Colors.red,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Red'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: Colors.green,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('Green'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: Colors.blue,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('Blue'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: Colors.orange,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text('Orange'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: Colors.purple,
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.purple, size: 20),
                  SizedBox(width: 8),
                  Text('Purple'),
                ],
              ),
            ),
          ],
          onChanged: (Color? value) {
            setState(() {
              selectedColor = value ?? selectedColor;
            });
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a calendar title'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final accountName =
                    _accountController.text.trim().isEmpty ? 'Eventide App' : _accountController.text.trim();

                widget.onSubmit(title, selectedColor, accountName);

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Calendar'),
            ),
          ],
        ),
      ],
    );
  }
}
