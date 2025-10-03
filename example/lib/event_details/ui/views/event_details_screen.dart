import 'dart:io';
import 'dart:math';

import 'package:eventide/eventide.dart';
import 'package:eventide_example/event_details/logic/event_details_cubit.dart';
import 'package:eventide_example/event_details/ui/components/attendee_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:value_state/value_state.dart';

final class EventDetailsScreen extends StatelessWidget {
  final ETEvent event;
  final bool isCalendarWritable;

  const EventDetailsScreen({
    required this.event,
    required this.isCalendarWritable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EventDetailsCubit(
        selectedEvent: event,
        calendarPlugin: context.read<Eventide>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(event.title),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BlocBuilder<EventDetailsCubit, Value<ETEvent>>(builder: (context, state) {
            return state.map(
              data: (event) => Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.description != null) Text(event.description!),
                  Text("${event.startDate.toString()} -> ${event.endDate.toString()}"),
                  if (event.url != null) Text(event.url!),
                  const Divider(),
                  Row(
                    children: [
                      const Text('Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (isCalendarWritable) ...[
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            context
                                .read<EventDetailsCubit>()
                                .createReminder(Duration(seconds: Random().nextInt(172800)));
                          },
                        ),
                      ]
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
                                      createAttendee(
                                        name: name,
                                        email: email,
                                        type: type,
                                      );
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
          }),
        ),
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
