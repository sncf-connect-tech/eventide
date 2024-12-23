import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_calendar_connect_example/calendar_cubit.dart';
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
                  if (state is CalendarSuccess)
                    SliverList(
                      delegate: SliverChildListDelegate(state.calendars.map((calendar) => SizedBox(
                        height: 50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                color: calendar.hexColor.toRgbColor(),
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 32),
                              Text(calendar.title, maxLines: 3, overflow: TextOverflow.fade,),
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

extension StringHexToRgbColorExtension on String {
  Color toRgbColor() => Color.fromRGBO(
    int.tryParse(substring(0, 2), radix: 16) ?? 0,
    int.tryParse(substring(2, 4), radix: 16) ?? 0,
    int.tryParse(substring(4, 6), radix: 16) ?? 0,
    1.0,
  );
}

/*
state.buildWidget(
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
          child: const Text('Fetch calendars'),
        ),
        const SizedBox(height: 16),
        ...state.value.calendars.map((calendar) => SizedBox(
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
)
*/