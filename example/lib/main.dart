import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_calendar/easy_calendar.dart';
import 'package:easy_calendar_example/logic/calendar_cubit.dart';
import 'package:easy_calendar_example/calendar_screen.dart';
import 'package:easy_calendar_example/logic/event_cubit.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final EasyCalendar _calendarPlugin;
  
  MyApp({super.key}) : _calendarPlugin = EasyCalendar();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CalendarCubit(calendarPlugin: _calendarPlugin)..fetchCalendars(onlyWritable: true)),
        BlocProvider(create: (_) => EventCubit(calendarPlugin: _calendarPlugin)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: CalendarScreen(),
        ),
      ),
    );
  }
}