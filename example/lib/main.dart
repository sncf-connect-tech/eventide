import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_calendar_connect_example/calendar_cubit.dart';
import 'package:flutter_calendar_connect_example/calendar_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider(
          create: (_) => CalendarCubit(),
          child: const CalendarScreen(),
        ),
      ),
    );
  }
}