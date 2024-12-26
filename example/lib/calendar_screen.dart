import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_calendar_connect_example/calendar_cubit.dart';
import 'package:flutter_calendar_connect_example/calendar_form.dart';
import 'package:flutter_calendar_connect_example/calendar_state.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (_, state) {
        return SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    pinned: true,
                    title: Text('Calendar plugin example app'),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CalendarForm(
                        onSubmit: (title, color) async {
                          await BlocProvider.of<CalendarCubit>(context).createCalendar(title: title, color: color.value);
                        },
                      ),
                    ),
                  ),
                  if (state is CalendarSuccess)
                    SliverList(
                      delegate: SliverChildListDelegate(state.calendars.map((calendar) => SizedBox(
                        height: 50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                color: Color(calendar.color),
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Text(calendar.title, maxLines: 3, overflow: TextOverflow.fade,)),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  final hasBeenCreated = await BlocProvider.of<CalendarCubit>(context).createOrUpdateEvent(
                                    calendarId: calendar.id,
                                  );

                                  if (hasBeenCreated && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created')));
                                  }
                                },
                                child: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state is CalendarNoValue) ...[
                          const Text('No calendars found'),
                          const SizedBox(height: 16),
                        ],
                        if (state is CalendarError) ...[
                          Text('Error: ${state.message}'),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ]
              ),
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
                    const SizedBox(height: 16),
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
      }
    );
  }
}