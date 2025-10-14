import 'package:eventide/eventide.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart';

typedef OnEventFormSubmit = void Function(
  ETCalendar? selectedCalendar,
  String title,
  String description,
  bool isAllDay,
  TZDateTime startDate,
  TZDateTime endDate,
);

final class EventForm extends StatefulWidget {
  final List<ETCalendar> calendars;
  final OnEventFormSubmit onSubmit;
  final DateTime? initialDate;

  const EventForm({
    required this.calendars,
    required this.onSubmit,
    this.initialDate,
    super.key,
  });

  @override
  State<EventForm> createState() => _EventFormState();
}

final class _EventFormState extends State<EventForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  ETCalendar? _selectedCalendar;
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(hours: 1));
  bool isAllDay = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.initialDate != null) {
      _selectedStartDate = widget.initialDate!;
      _selectedEndDate = widget.initialDate!.add(const Duration(hours: 1));
    } else {
      _selectedStartDate = DateTime.now();
      _selectedEndDate = DateTime.now().add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
          if (widget.calendars.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownMenu<ETCalendar>(
              label: Text('Calendar :'),
              dropdownMenuEntries: widget.calendars.map((calendar) {
                return DropdownMenuEntry(
                  value: calendar,
                  label: calendar.title,
                  leadingIcon: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: calendar.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(),
              onSelected: (ETCalendar? value) {
                setState(() {
                  _selectedCalendar = value;
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Text('isAllDay')),
              Expanded(
                child: Switch(
                  value: isAllDay,
                  onChanged: (value) => setState(() {
                    isAllDay = value;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Start date: ${_selectedStartDate.toLocal()}'),
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
              if (!isAllDay) ...[
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
            ],
          ),
          const SizedBox(height: 16),
          Text('End date: ${_selectedEndDate.toLocal()}'),
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
              if (!isAllDay) ...[
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
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.calendars.isEmpty || _selectedCalendar != null
                ? () {
                    widget.onSubmit(
                      _selectedCalendar,
                      _titleController.text,
                      _descriptionController.text,
                      isAllDay,
                      TZDateTime.from(_selectedStartDate, getLocation('Europe/Paris')),
                      TZDateTime.from(_selectedEndDate, getLocation('Europe/Paris')),
                    );
                  }
                : null,
            child: const Text('Create event'),
          ),
          if (!isAllDay) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.calendars.isEmpty || _selectedCalendar != null
                  ? () {
                      widget.onSubmit(
                        _selectedCalendar,
                        'Paris - Montreal',
                        _descriptionController.text,
                        false,
                        TZDateTime(getLocation('Europe/Paris'), 2025, 9, 8, 13, 30, 0),
                        TZDateTime(getLocation('America/Montreal'), 2025, 9, 8, 15, 0, 0),
                      );
                    }
                  : null,
              child: const Text('Create event in different timezones'),
            ),
          ],
        ],
      ),
    );
  }
}

extension on DateTime {
  DateTime copyWith({
    required TimeOfDay time,
  }) =>
      DateTime(
        year,
        month,
        day,
        time.hour,
        time.minute,
      );
}
