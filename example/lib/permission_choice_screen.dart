import 'package:eventide/eventide.dart';
import 'package:eventide_example/calendar/ui/calendar_screen.dart';
import 'package:eventide_example/calendar/ui/event_form.dart';
import 'package:eventide_example/calendar/logic/calendar_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class PermissionChoiceScreen extends StatelessWidget {
  const PermissionChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventide Permission Demo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_month,
                size: 120,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                'Choose Permission Scenario',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Test different iOS calendar permission scenarios:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Full permission scenario
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => CalendarCubit(
                              eventide: context.read<Eventide>(),
                            )..loadFullContent(),
                            child: const CalendarScreen(),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (e is ETPermissionException && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Full access denied. Please allow calendar permissions in settings.',
                            ),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.calendar_view_month),
                  label: const Text(
                    'Full Access Calendar\n(Read & Write)',
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Write-only permission scenario (iOS context)
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final eventide = context.read<Eventide>();

                    try {
                      // Retrieve the default calendar for write-only access
                      final defaultCalendar = await eventide.retrieveDefaultCalendar();

                      if (defaultCalendar == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No default calendar found'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Create Event (Write Only)'),
                            content: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: EventForm(
                                calendars: [defaultCalendar],
                                onSubmit: (selectedCalendar, title, description, isAllDay, startDate, endDate) async {
                                  try {
                                    await eventide.createEvent(
                                      title: title,
                                      description: description,
                                      isAllDay: isAllDay,
                                      startDate: startDate,
                                      endDate: endDate,
                                      calendarId: selectedCalendar.id,
                                    );

                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Event created successfully!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error creating event: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error retrieving default calendar: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Write Only Access\n(Create Event Only)',
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'iOS Permission Scenarios',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Full Access: Allows reading existing calendars and events, plus creating new ones\n'
                        '• Write Only: Only allows creating events in the default calendar, no reading access\n\n'
                        'Note: The Write Only scenario is specific to iOS. '
                        'Android typically requires full read/write access for calendar operations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
