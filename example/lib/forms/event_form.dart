import 'package:flutter/material.dart';

typedef OnEventFormSubmit = void Function(
  String title,
  String description,
  DateTime startDate,
  DateTime endDate,
);

class EventForm extends StatefulWidget {
  final OnEventFormSubmit onSubmit;

  const EventForm({
    required this.onSubmit,
    super.key,
  });

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Event title',
          ),
        ),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Event description',
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final lastDate = _selectedEndDate ?? DateTime.now().add(const Duration(days: 365));
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: lastDate,
            );

            if (picked != null) {
              setState(() {
                _selectedStartDate = picked;
              });
            }
          },
          child: const Text('Select start date'),
        ),
        ElevatedButton(
          onPressed: () async {
            final firstDate = _selectedStartDate ?? DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: firstDate,
              lastDate: firstDate.add(const Duration(days: 365)),
            );

            if (picked != null) {
              setState(() {
                _selectedEndDate = picked;
              });
            }
          },
          child: const Text('Select end date'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_selectedStartDate == null || _selectedEndDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end dates')));
              return;
            }

            widget.onSubmit(
              _titleController.text,
              _descriptionController.text,
              _selectedStartDate!,
              _selectedEndDate!,
            );

            Navigator.of(context).pop();
          },
          child: const Text('Create event'),
        ),
      ],
    );
  }
}