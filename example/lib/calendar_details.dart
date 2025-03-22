import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventide_example/forms/event_form.dart';
import 'package:eventide_example/logic/event_cubit.dart';
import 'package:eventide_example/logic/event_state.dart';
import 'package:value_state/value_state.dart';

class CalendarDetails extends StatelessWidget {
  const CalendarDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventCubit, EventState>(listener: (context, state) {
      if (state case Value(:final error?)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString()),
        ));
      }
    }, builder: (context, state) {
      return Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(state.data?.calendar.title ?? ''),
                actions: [
                  if (state.data?.calendar.isWritable ?? false)
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Create event'),
                              content: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: EventForm(
                                  onSubmit: (title, description, isAllDay, startDate, endDate) {
                                    BlocProvider.of<EventCubit>(context).createEvent(
                                      title: title,
                                      description: description,
                                      isAllDay: isAllDay,
                                      startDate: startDate,
                                      endDate: endDate,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
              if (state case Value(:final data?) when data.events.isNotEmpty)
                SliverList(
                  delegate: SliverChildListDelegate([
                    for (final event in data.events..sort((a, b) => a.id.compareTo(b.id)))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (event.description != null)
                                        Text(
                                          event.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(event.startDate.toFormattedString()),
                                      Text(event.endDate.toFormattedString()),
                                    ],
                                  ),
                                ),
                                if (state.data?.calendar.isWritable ?? false)
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      BlocProvider.of<EventCubit>(context)
                                          .createReminder(Duration(seconds: Random().nextInt(172800)), event.id);
                                    },
                                  ),
                                if (state.data?.calendar.isWritable ?? false)
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      BlocProvider.of<EventCubit>(context).deleteEvent(event.id);
                                    },
                                  ),
                              ],
                            ),
                            if (event.reminders != null)
                              ...event.reminders!.map((duration) => _Reminder(
                                    duration: duration,
                                    onDelete: () {
                                      BlocProvider.of<EventCubit>(context).deleteReminder(duration, event.id);
                                    },
                                  )),
                          ],
                        ),
                      ),
                  ]),
                ),
              if (state case Value(:final data?) when data.events.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No events found'),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

extension on DateTime {
  String toFormattedString() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class _Reminder extends StatelessWidget {
  final Duration duration;
  final VoidCallback onDelete;

  const _Reminder({
    required this.duration,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(computeDurationString())),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ],
    );
  }

  String computeDurationString() {
    if (duration.inHours > 0) {
      return 'reminder ${duration.inHours} hours before';
    } else if (duration.inMinutes.remainder(60) > 0) {
      return 'reminder ${duration.inMinutes} minutes before';
    } else {
      return 'reminder ${duration.inSeconds} seconds before';
    }
  }
}
