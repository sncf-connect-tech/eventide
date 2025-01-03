import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_calendar_connect/flutter_calendar_connect.dart';
import 'package:flutter_calendar_connect_example/logic/calendar_cubit.dart';
import 'package:flutter_calendar_connect_example/calendar_screen.dart';
import 'package:flutter_calendar_connect_example/logic/event_cubit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FlutterCalendarConnect _calendarPlugin;
  
  MyApp({super.key}) : _calendarPlugin = FlutterCalendarConnect();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CalendarCubit(calendarPlugin: _calendarPlugin)..fetchCalendars(onlyWritable: false)),
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