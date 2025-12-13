// ignore_for_file: deprecated_member_use

import 'package:eventide/eventide.dart';
import 'package:flutter/material.dart';

typedef OnCalendarFormSubmit = void Function(String title, Color color, ETAccount? account);

class CalendarForm extends StatefulWidget {
  final OnCalendarFormSubmit onSubmit;
  final Iterable<ETAccount> availableAccounts;

  const CalendarForm({
    required this.onSubmit,
    this.availableAccounts = const [],
    super.key,
  });

  @override
  State<CalendarForm> createState() => _CalendarFormState();
}

class _CalendarFormState extends State<CalendarForm> {
  late final TextEditingController _titleController;
  late Color selectedColor;
  ETAccount? selectedAccount;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    selectedColor = Colors.red;

    // Sélectionner le premier compte par défaut s'il y en a
    if (widget.availableAccounts.isNotEmpty) {
      selectedAccount = widget.availableAccounts.first;
    }
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
        const SizedBox(height: 16),
        if (widget.availableAccounts.isNotEmpty) ...[
          DropdownButtonFormField<ETAccount>(
            value: selectedAccount,
            decoration: const InputDecoration(
              labelText: 'Account',
              hintText: 'Select an account',
            ),
            items: widget.availableAccounts.map((account) {
              return DropdownMenuItem<ETAccount>(
                value: account,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_circle, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        account.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (ETAccount? value) {
              setState(() {
                selectedAccount = value;
              });
            },
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No accounts available. Calendar will be created in default account.',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          ),
        ],
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

                widget.onSubmit(title, selectedColor, selectedAccount);

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
