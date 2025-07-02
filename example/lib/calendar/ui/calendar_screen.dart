import 'package:calendar_view/calendar_view.dart';
import 'package:eventide/eventide.dart';
import 'package:eventide_example/calendar/logic/calendar_cubit.dart';
import 'package:eventide_example/event_details/ui/event_details_screen.dart';
import 'package:eventide_example/calendar/ui/event_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:value_state/value_state.dart';

final class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<StatefulWidget> createState() => _CalendarScreenState();
}

final class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  late final EventController _controller;
  late final TabController _tabController;
  ETCalendar? selectedCalendar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = EventController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarCubit, CalendarState>(
      listener: (context, state) {
        state.when(failure: (error) {
          if (error is ETPermissionException) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Full access denied. Please grant calendar permissions in settings.',
                ),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'Back',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${error.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      },
      child: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          // Clear existing events to prevent duplicates
          _controller.removeWhere((event) => true);

          state.data?.forEach((calendar, events) {
            final mappedEvents = events
                .map((event) => CalendarEventData(
                      event: event,
                      title: event.title,
                      date: event.startDate,
                      color: calendar.color,
                      startTime: event.startDate,
                      endTime: event.endDate,
                    ))
                .toList();

            _controller.addAll(mappedEvents);
          });

          return Scaffold(
            bottomNavigationBar: BottomAppBar(
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.calendar_view_month),
                    text: 'Month',
                  ),
                  Tab(
                    icon: const Icon(Icons.calendar_view_week),
                    text: 'Week',
                  ),
                  Tab(
                    icon: const Icon(Icons.calendar_view_day),
                    text: 'Day',
                  ),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                MonthView(
                  controller: _controller,
                  onEventTap: (calendarEventData, date) {
                    if (state case Value(:final data?)) {
                      final event = calendarEventData.event;
                      if (event is ETEvent) {
                        final relatedCalendar = data.keys.singleWhere((calendar) => calendar.id == event.calendarId);

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EventDetailsScreen(
                              event: event,
                              isCalendarWritable: relatedCalendar.isWritable,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  onDateLongPress: (date) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Create event'),
                          content: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: EventForm(
                              calendars: [...?state.data?.keys],
                              onSubmit: (selectedCalendar, title, description, isAllDay, startDate, endDate) async {
                                await BlocProvider.of<CalendarCubit>(context).createEvent(
                                  calendar: selectedCalendar,
                                  title: title,
                                  description: description,
                                  isAllDay: isAllDay,
                                  startDate: startDate,
                                  endDate: endDate,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                WeekView(
                  controller: _controller,
                ),
                DayView(
                  controller: _controller,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
