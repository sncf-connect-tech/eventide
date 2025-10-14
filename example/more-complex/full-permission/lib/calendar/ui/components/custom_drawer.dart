import 'package:eventide_example_full_permission/calendar/logic/calendar_cubit.dart';
import 'package:eventide_example_full_permission/calendar/ui/components/calendar_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:value_state/value_state.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(builder: (context, state) {
      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Calendars',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  final calendarCubit = BlocProvider.of<CalendarCubit>(context);

                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Create New Calendar'),
                      content: CalendarForm(
                        onSubmit: (title, color, accountName) async {
                          try {
                            await calendarCubit.createCalendar(
                              title: title,
                              color: color,
                              localAccountName: accountName,
                            );

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Calendar "$title" created successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error creating calendar: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const Divider(),
            if (state case Value(:final data?)) ...[
              if (data.calendars.isEmpty) ...[
                ListTile(
                  leading: Icon(Icons.info, color: Colors.blue),
                  title: Text('No available calendar'),
                ),
                ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Reload'),
                  onTap: () {
                    BlocProvider.of<CalendarCubit>(context).loadFullContent();
                  },
                ),
              ] else ...[
                ...data.calendars.keys.map((calendar) {
                  final eventCount = data.calendars[calendar]?.length ?? 0;
                  final isVisible = data.visibleCalendarIds.contains(calendar.id);

                  return CheckboxListTile(
                    value: isVisible,
                    onChanged: (bool? value) {
                      BlocProvider.of<CalendarCubit>(context).toggleCalendarVisibility(calendar.id);
                    },
                    secondary: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: calendar.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      calendar.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '$eventCount event${eventCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
              ]
            ] else ...[
              if (state.hasError)
                ListTile(
                  leading: Icon(Icons.error, color: Colors.red),
                  title: Text('Error loading calendars'),
                  subtitle: Text('Tap to retry'),
                  onTap: () {
                    BlocProvider.of<CalendarCubit>(context).loadFullContent();
                  },
                )
              else
                ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('Loading calendars...'),
                ),
            ],
          ],
        ),
      );
    });
  }
}
