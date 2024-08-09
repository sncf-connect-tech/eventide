import 'package:flutter/material.dart';
import 'package:calendar_example/calendar_screen.dart';
import 'package:calendar_example/calendar_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Calendar plugin example app'),
        ),
        body: BlocProvider(
          create: (_) => CalendarCubit()..init(),
          child: const CalendarScreen(),
        ),
      ),
    );
  }
}