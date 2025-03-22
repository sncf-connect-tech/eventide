import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventide/eventide.dart';
import 'package:eventide_example/calendar_details.dart';
import 'package:eventide_example/logic/calendar_cubit.dart';
import 'package:eventide_example/forms/calendar_form.dart';
import 'package:eventide_example/logic/event_cubit.dart';
import 'package:value_state/value_state.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, Value<List<ETCalendar>>>(builder: (_, state) {
      return SafeArea(
        child: Stack(
          children: [
            CustomScrollView(slivers: [
              SliverAppBar(
                pinned: true,
                title: const Text('Calendar plugin example app'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Create calendar'),
                          content: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: CalendarForm(
                              onSubmit: (title, color) async {
                                await BlocProvider.of<CalendarCubit>(context)
                                    .createCalendar(title: title, color: color);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (state case Value(:final data?))
                SliverList(
                  delegate: SliverChildListDelegate(
                    data
                        .map((calendar) => SizedBox(
                              height: 50,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: InkWell(
                                  onTap: () async {
                                    try {
                                      await BlocProvider.of<EventCubit>(context).selectCalendar(calendar);
                                      if (context.mounted) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) => const CalendarDetails()),
                                        );
                                      }
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(content: Text('Error: ${error.toString()}')));
                                      }
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        color: calendar.color,
                                        width: 16,
                                        height: 16,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          calendar.title,
                                          maxLines: 3,
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      if (calendar.isWritable)
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            BlocProvider.of<CalendarCubit>(context).deleteCalendar(calendar.id);
                                          },
                                        ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.arrow_right),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state case Value(:final data?) when data.isEmpty) ...[
                      const Text('No calendars found'),
                      const SizedBox(height: 16),
                    ],
                    if (state case Value(:final error?)) ...[
                      Text('Error: ${error.toString()}'),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ]),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => BlocProvider.of<CalendarCubit>(context).fetchCalendars(onlyWritable: true),
                    child: const Text('Writable calendars'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => BlocProvider.of<CalendarCubit>(context).fetchCalendars(onlyWritable: false),
                    child: const Text('All calendars'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
