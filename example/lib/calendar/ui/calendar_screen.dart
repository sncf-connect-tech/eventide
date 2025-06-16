import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventide/eventide.dart';
import 'package:eventide_example/event_list/ui/event_list.dart';
import 'package:eventide_example/calendar/logic/calendar_cubit.dart';
import 'package:eventide_example/calendar/ui/calendar_form.dart';
import 'package:eventide_example/event_list/logic/event_list_cubit.dart';
import 'package:value_state/value_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool onlyWritableCalendars = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CalendarCubit, Value<List<ETCalendar>>>(
          builder: (context, state) => Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: const Text('Eventide'),
                    actions: [
                      Row(
                        children: [
                          const Text('writable only'),
                          const SizedBox(width: 8),
                          Switch(
                            value: onlyWritableCalendars,
                            onChanged: (value) {
                              setState(() {
                                onlyWritableCalendars = value;
                              });
                              BlocProvider.of<CalendarCubit>(context).fetchCalendars(onlyWritable: value);
                            },
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () =>
                            BlocProvider.of<CalendarCubit>(context).fetchCalendars(onlyWritable: onlyWritableCalendars),
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
                                          await BlocProvider.of<EventListCubit>(context).selectCalendar(calendar);
                                          if (context.mounted) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(builder: (context) => const EventList()),
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
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Create calendar'),
              content: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CalendarForm(
                  onSubmit: (title, color) async {
                    await BlocProvider.of<CalendarCubit>(context).createCalendar(title: title, color: color);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
