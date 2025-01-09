import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart';

typedef OnEventFormSubmit = void Function(
  String title,
  String description,
  TZDateTime startDate,
  TZDateTime endDate,
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
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(hours: 1));

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
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Event description',
          ),
        ),
        const SizedBox(height: 16),
        Text('Start date: ${_selectedStartDate.toIso8601String()}'),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final lastDate = _selectedEndDate;
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedStartDate,
                    firstDate: DateTime.now(),
                    lastDate: lastDate,
                  );
              
                  if (pickedDate != null) {
                    final timeOfDay = TimeOfDay.fromDateTime(_selectedStartDate);
                    final duration = Duration(hours: timeOfDay.hour, minutes: timeOfDay.minute);
                    
                    setState(() {
                      _selectedStartDate = pickedDate.add(duration);
                    });
                    
                  }
                },
                child: const Icon(Icons.calendar_month),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final timeOfDay = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedStartDate),
                  );
              
                  if (timeOfDay != null) {
                    setState(() {
                      _selectedStartDate = (_selectedStartDate).copyWith(time: timeOfDay);
                    });
                  }
                },
                child: const Icon(Icons.access_time),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('End date: ${_selectedEndDate.toIso8601String()}'),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final firstDate = _selectedStartDate;
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedEndDate,
                    firstDate: firstDate,
                    lastDate: firstDate.add(const Duration(days: 365)),
                  );
              
                  if (pickedDate != null) {
                    final timeOfDay = TimeOfDay.fromDateTime(_selectedEndDate);
                    final duration = Duration(hours: timeOfDay.hour, minutes: timeOfDay.minute);
                    
                    setState(() {
                      _selectedEndDate = pickedDate.add(duration);
                    }); 
                  }
                },
                child: const Icon(Icons.calendar_month),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final timeOfDay = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedEndDate),
                  );
              
                  if (timeOfDay != null) {
                    setState(() {
                      _selectedEndDate = (_selectedEndDate).copyWith(time: timeOfDay);
                    });
                  }
                },
                child: const Icon(Icons.access_time),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(
              _titleController.text,
              _descriptionController.text,
              TZDateTime(getLocation('Europe/Paris'), 2025, 9, 8, 13, 30),
              TZDateTime(getLocation('America/Montreal'), 2025, 9, 8, 15, 00),
            );

            Navigator.of(context).pop();
          },
          child: const Text('Create event in different timezones'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(
              _titleController.text,
              _descriptionController.text,
              TZDateTime.from(_selectedStartDate, getLocation('Europe/Paris')),
              TZDateTime.from(_selectedEndDate, getLocation('Europe/Paris')),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Creating event...')),
            );

            Navigator.of(context).pop();
          },
          child: const Text('Create event'),
        ),
      ],
    );
  }
}

extension on DateTime {
  DateTime copyWith({
    required TimeOfDay time,
  }) => DateTime(
    year,
    month,
    day,
    time.hour,
    time.minute,
  );
}