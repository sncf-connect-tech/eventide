import 'dart:math';

import 'package:eventide/eventide.dart';
import 'package:eventide_example/logic/event_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EventDetails extends StatelessWidget {
  final ETEvent event;
  final bool isCalendarWritable;

  const EventDetails({
    required this.event,
    required this.isCalendarWritable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ListTile(
            title: Text(event.title),
            subtitle:
                event.description != null ? Text(event.description!) : null,
          ),
          ListTile(
            title: const Text('Duration'),
            subtitle: Text(
                "${event.startDate.toString()} -> ${event.endDate.toString()}"),
          ),
          if (event.url != null)
            ListTile(
              title: Text(event.url!),
            ),
          if (event.reminders != null && event.reminders!.isNotEmpty) ...[
            Row(
              children: [
                const Text('Reminders'),
                if (isCalendarWritable) ...[
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      BlocProvider.of<EventCubit>(context).createReminder(
                          Duration(seconds: Random().nextInt(172800)),
                          event.id);
                    },
                  ),
                ]
              ],
            ),
            for (final reminder in event.reminders ?? [])
              Text('${reminder.inMinutes} minutes before'),
          ],
          if (event.attendees != null && event.attendees!.isNotEmpty) ...[
            const Text('Attendees'),
            for (final attendee in event.attendees ?? []) Text(attendee.name),
          ],
        ],
      ),
    );
  }
}
