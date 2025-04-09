import 'package:eventide_example/event_list/logic/event_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eventide/eventide.dart';
import 'package:eventide_example/calendar/logic/calendar_cubit.dart';
import 'package:eventide_example/calendar/ui/calendar_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => Eventide(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => CalendarCubit(
              calendarPlugin: context.read<Eventide>(),
            )..fetchCalendars(onlyWritable: true),
          ),
          BlocProvider(
            create: (context) => EventListCubit(calendarPlugin: context.read<Eventide>()),
          ),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: CalendarScreen(),
          ),
        ),
      ),
    );
  }
}
