import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_calendar_example/forms/event_form.dart';
import 'package:easy_calendar_example/logic/event_cubit.dart';
import 'package:easy_calendar_example/logic/event_state.dart';
import 'package:value_state/value_state.dart';

class CalendarDetails extends StatelessWidget {
  const CalendarDetails({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventCubit, EventState>(
      listener: (context, state) {
        if (state case Value(:final error?)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.toString()),
          ));
        }
      },
      builder: (context, state) {
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
                                    onSubmit: (title, description, startDate, endDate) {
                                      BlocProvider.of<EventCubit>(context).createEvent(
                                        title: title,
                                        description: description,
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
                      for (final event in data.events)
                        SizedBox(
                          height: 50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(event.title,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (event.description != null)
                                        Text(event.description!,
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
                                if (event.reminders != null)
                                  Text('${event.reminders!.length}'),
                                if (state.data?.calendar.isWritable ?? false)
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      BlocProvider.of<EventCubit>(context).createReminder(Random().nextInt(30), event.id);
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
      }
    );
  }
}

extension on DateTime {
  String toFormattedString() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}