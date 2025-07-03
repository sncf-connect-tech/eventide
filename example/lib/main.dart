import 'package:eventide/eventide.dart';
import 'package:eventide_example/permission_choice_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(MyApp());
}

final class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => Eventide(),
      child: MaterialApp(
        home: const PermissionChoiceScreen(),
      ),
    );
  }
}
