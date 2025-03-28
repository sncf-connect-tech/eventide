import 'package:eventide/eventide.dart';
import 'package:flutter/material.dart';

typedef OnAttendeeFormSubmit = void Function(
  String name,
  String email,
  ETAttendeeType type,
);

class AttendeeForm extends StatefulWidget {
  final OnAttendeeFormSubmit onSubmit;

  const AttendeeForm({
    required this.onSubmit,
    super.key,
  });

  @override
  State<AttendeeForm> createState() => _AttendeeFormState();
}

class _AttendeeFormState extends State<AttendeeForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  ETAttendeeType _attendeeType = ETAttendeeType.unknown;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Attendee name',
          ),
          validator: (value) {
            if (value == null && value!.isEmpty) {
              return "name should not be empty";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Attendee email',
          ),
          validator: (value) {
            if (value == null && value!.isEmpty) {
              return "email should not be empty";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownMenu(
          initialSelection: _attendeeType,
          dropdownMenuEntries:
              ETAttendeeType.values.map((type) => DropdownMenuEntry(value: type, label: type.name)).toList(),
          onSelected: (type) {
            if (type != null) {
              _attendeeType = type;
            }
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(
              _nameController.text,
              _emailController.text,
              _attendeeType,
            );

            Navigator.of(context).pop();
          },
          child: const Text('Add attendee'),
        ),
      ],
    );
  }
}
