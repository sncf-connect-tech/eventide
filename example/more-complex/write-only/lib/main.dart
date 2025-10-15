import 'package:eventide/eventide.dart';
import 'package:eventide_example_write_only/event_form.dart';
import 'package:flutter/material.dart';
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
    return MaterialApp(
      title: 'Eventide - Write Only Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: WriteOnlyDemoPage(),
    );
  }
}

class WriteOnlyDemoPage extends StatelessWidget {
  final Eventide eventide = Eventide();

  WriteOnlyDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Write-Only Mode',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This application demonstrates Eventide\'s write-only access mode:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        context,
                        Icons.add_circle_outline,
                        'Event Creation',
                        'You can create new events in the default calendar',
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        context,
                        Icons.block,
                        'No Reading',
                        'The application cannot read existing events',
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        context,
                        Icons.security,
                        'Limited Access',
                        'Minimal permissions for enhanced security',
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Perfect for applications that only need to create events without accessing existing calendar data.',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateEventDialog(context),
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                    label: const Text(
                      'Create New Event',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Features:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildSimpleFeature('✅ Simple event creation'),
                      _buildSimpleFeature('✅ All-day event support'),
                      _buildSimpleFeature('✅ Timezone management'),
                      _buildSimpleFeature('✅ Multi-timezone events'),
                      _buildSimpleFeature('❌ Reading existing events'),
                      _buildSimpleFeature('❌ Modifying events'),
                      _buildSimpleFeature('❌ Deleting events'),
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

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  void _showCreateEventDialog(BuildContext context) async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create Event'),
          content: SizedBox(
            width: double.maxFinite,
            child: EventForm(
              calendars: [],
              onSubmit: (_, title, description, isAllDay, startDate, endDate) async {
                try {
                  await eventide.createEventInDefaultCalendar(
                    title: title,
                    description: description,
                    isAllDay: isAllDay,
                    startDate: startDate,
                    endDate: endDate,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event created successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
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
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing calendar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
