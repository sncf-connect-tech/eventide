import 'dart:io';
import 'dart:math';

import 'package:eventide/eventide.dart';

import '../../../calendar/ui/components/event_form.dart';
import '../../logic/event_details_cubit.dart';
import '../components/attendee_form.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:value_state/value_state.dart';

final class EventDetailsScreen extends StatelessWidget {
  final ETEvent event;
  final bool isCalendarWritable;

  const EventDetailsScreen({required this.event, required this.isCalendarWritable, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EventDetailsCubit(selectedEvent: event, calendarPlugin: context.read<Eventide>()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(event.title),
          actions: [
            if (isCalendarWritable) ...[
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final cubit = context.read<EventDetailsCubit>();
                    final currentEvent = cubit.state.data ?? event;
                    ETSpan span = ETSpan.thisEvent;
                    if (currentEvent.recurrenceRule != null || currentEvent.originalInstanceDate != null) {
                      final chosen = await _showSpanDialog(context, title: 'Delete recurring event');
                      if (chosen == null) return;
                      span = chosen;
                    }
                    try {
                      await cubit.deleteEvent(span: span);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting event: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ),
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final cubit = context.read<EventDetailsCubit>();
                    final currentEvent = (context.read<EventDetailsCubit>().state).data ?? event;
                    ETSpan span = ETSpan.thisEvent;
                    if (currentEvent.recurrenceRule != null || currentEvent.originalInstanceDate != null) {
                      final chosen = await _showSpanDialog(context, title: 'Edit recurring event');
                      if (chosen == null) return;
                      span = chosen;
                    }

                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Edit event'),
                        content: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: EventForm(
                            calendars: const [],
                            initialEvent: currentEvent,
                            onSubmit: (_, title, description, isAllDay, startDate, endDate, recurrenceRule) async {
                              try {
                                await cubit.updateEvent(
                                  title: title,
                                  description: description,
                                  isAllDay: isAllDay,
                                  startDate: startDate,
                                  endDate: endDate,
                                  recurrenceRule: recurrenceRule,
                                  span: span,
                                );

                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              } catch (e) {
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error updating event: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BlocBuilder<EventDetailsCubit, Value<ETEvent>>(
            builder: (context, state) {
              return state.map(
                data: (event) => Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.description != null) Text(event.description!),
                    Text("${event.startDate.toString()} -> ${event.endDate.toString()}"),
                    if (event.recurrenceRule != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.repeat, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Repeats: ${RecurrenceOption.fromRule(event.recurrenceRule).label} (${event.recurrenceRule})',
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (event.url != null) Text(event.url!),
                    const Divider(),
                    Row(
                      children: [
                        const Text('Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (isCalendarWritable) ...[
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              context.read<EventDetailsCubit>().createReminder(
                                Duration(seconds: Random().nextInt(172800)),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    for (final reminder in event.reminders)
                      Row(
                        children: [
                          Expanded(child: Text('${reminder.inMinutes} minutes before')),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              context.read<EventDetailsCubit>().deleteReminder(reminder);
                            },
                          ),
                        ],
                      ),
                    const Divider(),
                    Row(
                      children: [
                        const Text('Attendees', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (Platform.isAndroid && isCalendarWritable) ...[
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final createAttendee = context.read<EventDetailsCubit>().createAttendee;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Create attendee'),
                                  content: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: AttendeeForm(
                                      onSubmit: (name, email, type) {
                                        createAttendee(name: name, email: email, type: type);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    for (final attendee in event.attendees)
                      Row(
                        children: [
                          Expanded(child: Text(attendee.displayTitle)),
                          if (Platform.isAndroid && isCalendarWritable)
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                context.read<EventDetailsCubit>().removeAttendee(attendee);
                              },
                            ),
                        ],
                      ),
                  ],
                ),
                orElse: () => const CircularProgressIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<ETSpan?> _showSpanDialog(BuildContext context, {required String title}) {
    return showDialog<ETSpan>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ETSpan.thisEvent),
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('This event only')),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ETSpan.thisAndFuture),
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('This and future events')),
          ),
        ],
      ),
    );
  }
}

extension on ETAttendee {
  String get displayTitle {
    if (name.isNotEmpty) {
      return name;
    } else {
      return email;
    }
  }
}
