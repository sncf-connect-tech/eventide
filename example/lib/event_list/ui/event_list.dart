import 'package:eventide_example/event_details/ui/event_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventide_example/event_list/ui/event_form.dart';
import 'package:eventide_example/event_list/logic/event_list_cubit.dart';
import 'package:eventide_example/event_list/logic/event_list_state.dart';
import 'package:value_state/value_state.dart';

class EventList extends StatelessWidget {
  const EventList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<EventListCubit, EventListState>(builder: (context, state) {
          return CustomScrollView(
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
                                    BlocProvider.of<EventListCubit>(context).createEvent(
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
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EventDetails(
                                event: event,
                                isCalendarWritable: state.data?.calendar.isWritable ?? false,
                              ),
                            ),
                          ),
                          child: Row(
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
          );
        }),
      ),
    );
  }
}

extension on DateTime {
  String toFormattedString() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

/*
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
*/
