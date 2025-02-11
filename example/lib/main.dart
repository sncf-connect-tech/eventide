import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventide/eventide.dart';
import 'package:eventide_example/logic/calendar_cubit.dart';
import 'package:eventide_example/calendar_screen.dart';
import 'package:eventide_example/logic/event_cubit.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Eventide _calendarPlugin;
  
  MyApp({super.key}) : _calendarPlugin = Eventide();

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