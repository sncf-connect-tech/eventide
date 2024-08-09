import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_calendar_connect_example/calendar_cubit.dart';
import 'package:flutter_calendar_connect_example/calendar_state.dart';
import 'package:flutter_value_state/flutter_value_state.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (_, state) => state.buildWidget(
        onNoValue: (context, _) => Center(
          child: ElevatedButton(
            onPressed: BlocProvider.of<CalendarCubit>(context).fetchCalendars,
            child: const Text('Fetch calendars'),
          ),
        ),
        onValue: (context, state, _) => Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: BlocProvider.of<CalendarCubit>(context).fetchCalendars,
                child: const Text('Refetch calendars'),
              ),
              const SizedBox(height: 16),
              ...state.value.calendars.map((calendar) => Container(
                height: 50,
                child: Row(
                  children: [
                    Text(calendar.title),
                    const SizedBox(width: 16),
                    Text(calendar.id),
                  ],
                ),
              )),
            ],
          ),
        ),
        onWaiting: (_, __) => const Center(child: CircularProgressIndicator()),
        onError: (context, error) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}