import 'package:eventide/eventide.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

final class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventide - Native Only Demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: NativeOnlyDemoPage(),
    );
  }
}

class NativeOnlyDemoPage extends StatelessWidget {
  final Eventide eventide = Eventide();

  NativeOnlyDemoPage({super.key});

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
                            Icons.smartphone,
                            color: Colors.purple.shade600,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Native Platform Mode',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This application demonstrates Eventide\'s native platform integration:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        context,
                        Icons.phone_android,
                        'Native UI',
                        'Uses the system\'s built-in event creation interface',
                        Colors.purple,
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        context,
                        Icons.no_accounts,
                        'No Permissions',
                        'No calendar permissions required from your app',
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildFeatureItem(
                        context,
                        Icons.security,
                        'User Control',
                        'User has full control over what gets saved',
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.purple.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Perfect when you want to let users create events without requesting sensitive calendar permissions.',
                                style: TextStyle(
                                  color: Colors.purple.shade800,
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
                    onPressed: () => _createEventThroughNativeUI(context),
                    icon: const Icon(Icons.smartphone, size: 28),
                    label: const Text(
                      'Open Native Event Creator',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
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
                        'How it works:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildSimpleFeature('📱 Opens system\'s native event creation UI'),
                      _buildSimpleFeature('🔒 No calendar permissions needed'),
                      _buildSimpleFeature('👤 User controls all data and privacy'),
                      _buildSimpleFeature('✅ Works on both iOS and Android'),
                      _buildSimpleFeature('🎨 Matches system UI design'),
                      _buildSimpleFeature('⚡ Instant access, no setup required'),
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

  void _createEventThroughNativeUI(BuildContext context) async {
    try {
      await eventide.createEventThroughNativePlatform();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully through native UI!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ETUserCanceledException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event creation was canceled by user'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ETPresentationException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not present native event creation UI'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
