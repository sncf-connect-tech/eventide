import 'package:flutter/material.dart';
import 'package:eventide/eventide.dart';

/// 🗓️ Simple Eventide Plugin Example
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventide Simple Demo',
      home: CalendarDemo(),
    );
  }
}

class CalendarDemo extends StatefulWidget {
  const CalendarDemo({super.key});

  @override
  State<CalendarDemo> createState() => _CalendarDemoState();
}

class _CalendarDemoState extends State<CalendarDemo> {
  final Eventide eventide = Eventide();
  String status = 'Ready';

  // 📅 Retrieve calendars
  Future<void> getCalendars() async {
    try {
      setState(() => status = '🔄 Loading calendars...');
      final calendars = await eventide.retrieveCalendars();
      setState(() => status = '✅ ${calendars.length} calendar(s) found');
    } catch (e) {
      setState(() => status = '❌ Error: $e');
    }
  }

  // 🆕 Create a simple event
  Future<void> createEvent() async {
    try {
      setState(() => status = '🔄 Creating event...');

      // Get the first available calendar
      final calendars = await eventide.retrieveCalendars();
      if (calendars.isEmpty) {
        setState(() => status = '❌ No calendar available');
        return;
      }

      // Create an event for tomorrow at 2 PM
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final startDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0);
      final endDate = startDate.add(Duration(hours: 1));

      await eventide.createEvent(
        calendarId: calendars.first.id,
        title: 'Eventide Test',
        startDate: startDate,
        endDate: endDate,
        description: 'Event created with Eventide plugin',
      );

      setState(() => status = '✅ Event created for tomorrow at 2 PM');
    } catch (e) {
      setState(() => status = '❌ Error: $e');
    }
  }

  // 🌟 Open native interface
  Future<void> openNativeInterface() async {
    try {
      setState(() => status = '🔄 Opening native interface...');
      await eventide.createEventThroughNativePlatform(
        title: 'New Event',
        startDate: DateTime.now().add(Duration(hours: 1)),
        endDate: DateTime.now().add(Duration(hours: 2)),
      );
      setState(() => status = '✅ Native interface opened');
    } catch (e) {
      setState(() => status = '❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🗓️ Eventide Demo')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: getCalendars,
              child: Text('📅 View Calendars'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: createEvent,
              child: Text('🆕 Create Event'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: openNativeInterface,
              child: Text('🌟 Native Interface'),
            ),
          ],
        ),
      ),
    );
  }
}
