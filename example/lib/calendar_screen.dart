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
        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text('Calendar'),
            ),
            if (state is CalendarInitial)
              SliverFillRemaining(
                child: Center(
                  child: ElevatedButton(
                    onPressed: BlocProvider.of<CalendarCubit>(context).fetchCalendars,
                    child: const Text('Fetch calendars'),
                  ),
                ),
              ),
            if (state is CalendarSuccess)
              SliverList.separated(
                itemBuilder: (context, index) {
                  return ColoredBox(
                    color: state.calendars[index].hexColor.toRgbColor(),
                    child: SizedBox(
                      height: 50,
                      child: Row(
                        children: [
                          Text(state.calendars[index].title),
                          const SizedBox(width: 16),
                          Text(state.calendars[index].id),
                    
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              ),
            if (state is CalendarError)
              SliverFillRemaining(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                    onPressed: BlocProvider.of<CalendarCubit>(context).fetchCalendars,
                    child: const Text('Fetch calendars'),
                  )
                  ],
                ),
              ),
          ]
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