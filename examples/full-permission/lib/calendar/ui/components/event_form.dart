import 'package:eventide/eventide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart';

enum RecurrenceOption {
  never(null, 'Never'),
  everyDay('FREQ=DAILY', 'Every Day'),
  everyWeek('FREQ=WEEKLY', 'Every Week'),
  every2Weeks('FREQ=WEEKLY;INTERVAL=2', 'Every 2 Weeks'),
  everyMonth('FREQ=MONTHLY', 'Every Month'),
  everyYear('FREQ=YEARLY', 'Every Year');

  final String? rule;
  final String label;

  const RecurrenceOption(this.rule, this.label);

  static RecurrenceOption fromRule(String? rule) {
    if (rule == null) return RecurrenceOption.never;
    final upper = rule.toUpperCase();
    if (upper.contains('FREQ=DAILY')) return RecurrenceOption.everyDay;
    if (upper.contains('FREQ=WEEKLY')) {
      if (upper.contains('INTERVAL=2')) return RecurrenceOption.every2Weeks;
      return RecurrenceOption.everyWeek;
    }
    if (upper.contains('FREQ=MONTHLY')) return RecurrenceOption.everyMonth;
    if (upper.contains('FREQ=YEARLY')) return RecurrenceOption.everyYear;
    return RecurrenceOption.values.firstWhere((opt) => opt.rule == rule, orElse: () => RecurrenceOption.never);
  }
}

typedef OnEventFormSubmit = void Function(
  ETCalendar? selectedCalendar,
  String title,
  String description,
  bool isAllDay,
  TZDateTime startDate,
  TZDateTime endDate,
  String? recurrenceRule,
);

final class EventForm extends StatefulWidget {
  final List<ETCalendar> calendars;
  final OnEventFormSubmit onSubmit;
  final DateTime? initialDate;
  final ETEvent? initialEvent;
  final ETCalendar? initialCalendar;

  const EventForm({
    required this.calendars,
    required this.onSubmit,
    this.initialDate,
    this.initialEvent,
    this.initialCalendar,
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
  RecurrenceOption _selectedRecurrence = RecurrenceOption.never;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialEvent?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initialEvent?.description ?? '');
    _selectedCalendar = widget.initialCalendar;
    _selectedRecurrence = RecurrenceOption.fromRule(widget.initialEvent?.recurrenceRule);

    if (widget.initialEvent != null) {
      _selectedStartDate = widget.initialEvent!.startDate;
      _selectedEndDate = widget.initialEvent!.endDate;
      isAllDay = widget.initialEvent!.isAllDay;
    } else if (widget.initialDate != null) {
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
            decoration: const InputDecoration(labelText: 'Event title'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Event description'),
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
                    decoration: BoxDecoration(color: calendar.color, borderRadius: BorderRadius.circular(2)),
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
          DropdownMenu<RecurrenceOption>(
            initialSelection: _selectedRecurrence,
            label: const Text('Recurrence :'),
            dropdownMenuEntries: RecurrenceOption.values.map((option) {
              return DropdownMenuEntry(value: option, label: option.label);
            }).toList(),
            onSelected: (RecurrenceOption? value) {
              setState(() {
                _selectedRecurrence = value ?? RecurrenceOption.never;
              });
            },
          ),
          const SizedBox(height: 16),
          Text('Start date: ${_selectedStartDate.toLocal()}'),
          if (!isAllDay) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.access_time),
                label: const Text('Pick start time'),
                onPressed: () async {
                  final timeOfDay = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedStartDate),
                  );

                  if (timeOfDay != null) {
                    setState(() {
                      final newStartDate = (_selectedStartDate).copyWith(time: timeOfDay);
                      _selectedStartDate = newStartDate;
                      if (_selectedEndDate.isBefore(newStartDate)) {
                        _selectedEndDate = newStartDate.add(const Duration(hours: 1));
                      }
                    });
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('End date: ${_selectedEndDate.toLocal()}'),
          if (!isAllDay) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.access_time),
                label: const Text('Pick end time'),
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
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.calendars.isEmpty || _selectedCalendar != null
                ? () {
                    final recurrenceRule =
                        (_selectedRecurrence == RecurrenceOption.fromRule(widget.initialEvent?.recurrenceRule))
                        ? widget.initialEvent?.recurrenceRule
                        : _selectedRecurrence.rule;
                    widget.onSubmit(
                      _selectedCalendar,
                      _titleController.text,
                      _descriptionController.text,
                      isAllDay,
                      TZDateTime.from(_selectedStartDate, getLocation('Europe/Paris')),
                      TZDateTime.from(_selectedEndDate, getLocation('Europe/Paris')),
                      recurrenceRule,
                    );
                  }
                : null,
            child: Text(widget.initialEvent != null ? 'Update event' : 'Create event'),
          ),
          if (!isAllDay && widget.initialEvent == null) ...[
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
                        _selectedRecurrence.rule,
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
  DateTime copyWith({required TimeOfDay time}) => DateTime(year, month, day, time.hour, time.minute);
}
