import 'package:eventide/eventide.dart';
import 'package:eventide_example_full_permission/calendar/logic/calendar_cubit.dart';
import 'package:eventide_example_full_permission/calendar/ui/views/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        title: 'Eventide - Full Permission Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}

final class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                            Icons.calendar_month,
                            color: Colors.blue.shade600,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Full Permission Mode',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This application demonstrates Eventide\'s full calendar access capabilities:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        context,
                        Icons.visibility,
                        'Read Events',
                        'View all events from all accessible calendars',
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        context,
                        Icons.create,
                        'Create Events',
                        'Add new events to any writable calendar',
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        context,
                        Icons.edit,
                        'Modify Events',
                        'Update existing events in writable calendars',
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        context,
                        Icons.delete,
                        'Delete Events',
                        'Remove events from writable calendars',
                        Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Requires calendar permissions. Perfect for full-featured calendar applications.',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
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
                    onPressed: () => _openCalendarApp(context),
                    icon: const Icon(Icons.calendar_view_month, size: 28),
                    label: const Text(
                      'Open Full Calendar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
                        'Calendar Features:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildSimpleFeature('📅 Month, Week, and Day views'),
                      _buildSimpleFeature('👁️ View all calendar events'),
                      _buildSimpleFeature('➕ Create events by long-pressing dates'),
                      _buildSimpleFeature('✏️ Edit existing events'),
                      _buildSimpleFeature('🗑️ Delete events'),
                      _buildSimpleFeature('📱 Multi-calendar support'),
                      _buildSimpleFeature('🎨 Color-coded calendars'),
                      _buildSimpleFeature('🔒 Respects calendar write permissions'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This demo requires calendar permissions to function properly.',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w500,
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

  void _openCalendarApp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => CalendarCubit(
            eventide: context.read<Eventide>(),
          )
            ..loadFullContent()
            ..loadAvailableAccounts(),
          child: const CalendarScreen(),
        ),
      ),
    );
  }
}
