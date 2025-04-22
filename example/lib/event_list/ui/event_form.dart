import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart';
import 'package:rrule/rrule.dart';

final _supportedLocations = [
  'Europe/Paris',
  'America/Los_Angeles',
  'America/Montreal',
  'Asia/Beirut',
];

final _recurrenceRules = {
  'daily': RecurrenceRule(
    frequency: Frequency.daily,
    interval: 1,
  ),
  'sun./2weeks dec.': RecurrenceRule(
    frequency: Frequency.weekly,
    interval: 2,
    byMonths: [12],
    byWeekDays: [
      ByWeekDayEntry(DateTime.sunday),
    ],
  ),
  'weekly': RecurrenceRule(
    frequency: Frequency.weekly,
    interval: 1,
  ),
  'every two weeks': RecurrenceRule(
    frequency: Frequency.weekly,
    interval: 2,
  ),
  'monthly': RecurrenceRule(
    frequency: Frequency.monthly,
    interval: 1,
  ),
  '1st wed./month': RecurrenceRule.fromString("RRULE:FREQ=MONTHLY;BYDAY=WE;BYMONTHDAY=1,2,3,4,5,6,-1"),
  'yearly': RecurrenceRule(
    frequency: Frequency.yearly,
    interval: 1,
  ),
};
typedef OnEventFormSubmit = void Function(
  String title,
  String description,
  bool isAllDay,
  TZDateTime startDate,
  TZDateTime endDate,
  RecurrenceRule? rRule,
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
  late String _startLocation;
  late String _endLocation;
  late TZDateTime _selectedStartDate;
  late TZDateTime _selectedEndDate;
  late bool _isAllDay;
  RecurrenceRule? _recurrenceRule;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    _startLocation = _supportedLocations.first;
    _endLocation = _supportedLocations.first;

    _selectedStartDate = TZDateTime.now(getLocation(_startLocation));
    _selectedEndDate = TZDateTime.now(getLocation(_endLocation)).add(const Duration(hours: 1));

    _isAllDay = false;
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
              labelText: 'title',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'description',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('isAllDay')),
              Expanded(
                child: Switch(
                  value: _isAllDay,
                  onChanged: (value) => setState(() {
                    _isAllDay = value;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Start date: ${_selectedStartDate.toIso8601String()}'),
          DropdownButton<String>(
            value: _startLocation,
            items: _supportedLocations.map((location) {
              return DropdownMenuItem<String>(
                value: location,
                child: Text(location),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue == null) return;
              setState(() {
                _startLocation = newValue;
                _selectedStartDate = TZDateTime.from(_selectedStartDate, getLocation(newValue));
                if (_selectedEndDate.toUtc().isBefore(_selectedStartDate.toUtc())) {
                  _selectedEndDate = TZDateTime.from(_selectedStartDate, getLocation(_endLocation));
                }
              });
            },
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedStartDate,
                      firstDate: TZDateTime.now(getLocation(_startLocation)),
                      lastDate: TZDateTime.now(getLocation(_startLocation)).add(Duration(days: 365)),
                    );

                    if (pickedDate != null) {
                      final timeOfDay = TimeOfDay.fromDateTime(_selectedStartDate);

                      setState(() {
                        _selectedStartDate =
                            TZDateTime.from(pickedDate, getLocation(_startLocation)).copyWith(time: timeOfDay);
                      });
                    }
                  },
                  child: const Icon(Icons.calendar_month),
                ),
              ),
              if (!_isAllDay) ...[
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
                          _selectedStartDate = _selectedStartDate.copyWith(time: timeOfDay);
                        });
                      }
                    },
                    child: const Icon(Icons.access_time),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text('End date: ${_selectedEndDate.toIso8601String()}'),
          DropdownButton<String>(
            value: _endLocation,
            items: _supportedLocations.map((location) {
              return DropdownMenuItem<String>(
                value: location,
                child: Text(location),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue == null) return;
              setState(() {
                _endLocation = newValue;
                _selectedEndDate = TZDateTime.from(_selectedEndDate, getLocation(newValue));
              });
            },
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final firstDate = TZDateTime.from(_selectedStartDate, getLocation(_endLocation));
                    final TZDateTime initialDate;
                    if (_selectedStartDate.isAfter(_selectedEndDate)) {
                      initialDate = firstDate;
                    } else {
                      initialDate = _selectedEndDate;
                    }

                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: firstDate,
                      lastDate: firstDate.add(const Duration(days: 365)),
                    );

                    if (pickedDate != null) {
                      final timeOfDay = TimeOfDay.fromDateTime(_selectedEndDate);

                      setState(() {
                        _selectedEndDate =
                            TZDateTime.from(pickedDate, getLocation(_endLocation)).copyWith(time: timeOfDay);
                      });
                    }
                  },
                  child: const Icon(Icons.calendar_month),
                ),
              ),
              if (!_isAllDay) ...[
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
          const SizedBox(height: 8),
          const Text('Recurrence rule'),
          DropdownButton<RecurrenceRule?>(
            value: _recurrenceRule,
            items: [
              DropdownMenuItem(value: null, child: Text('None')),
              ..._recurrenceRules.entries.map((entry) {
                return DropdownMenuItem<RecurrenceRule>(
                  value: entry.value,
                  child: Text(
                    entry.key,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (newValue) {
              setState(() {
                _recurrenceRule = newValue;
              });
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              widget.onSubmit(
                _titleController.text,
                _descriptionController.text,
                _isAllDay,
                TZDateTime.from(_selectedStartDate, getLocation('Europe/Paris')),
                TZDateTime.from(_selectedEndDate, getLocation('Europe/Paris')),
                _recurrenceRule,
              );

              Navigator.of(context).pop();
            },
            child: const Text('Create event'),
          ),
        ],
      ),
    );
  }
}

extension on TZDateTime {
  TZDateTime copyWith({
    required TimeOfDay time,
  }) =>
      TZDateTime(
        location,
        year,
        month,
        day,
        time.hour,
        time.minute,
      );
}
