import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventide/src/eventide_extensions.dart';
import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/eventide_platform_interface.dart';

void main() {
  group('ColorToValue tests', () {
    test('Color toValue', () {
      const color = Color(0xFF123456);
      expect(color.toValue(), 0xFF123456);
    });
  });

  group('CalendarToETCalendar tests', () {
    test('Calendar toETCalendar', () {
      final calendar = Calendar(
        id: '1',
        title: 'Test Calendar',
        color: 0xFF123456,
        isWritable: true,
        account: Account(name: 'Test Account', type: 'Test Type'),
      );
      final etCalendar = calendar.toETCalendar();
      expect(etCalendar.id, '1');
      expect(etCalendar.title, 'Test Calendar');
      expect(etCalendar.color, const Color(0xFF123456));
      expect(etCalendar.isWritable, true);
      expect(etCalendar.account.name, 'Test Account');
    });
  });

  group('EventToETEvent tests', () {
    test('Event toETEvent', () {
      final event = Event(
        id: '1',
        title: 'Test Event',
        isAllDay: false,
        startDate: DateTime(2023, 10, 1).millisecondsSinceEpoch,
        endDate: DateTime(2023, 10, 2).millisecondsSinceEpoch,
        calendarId: '1',
        description: 'Test Description',
        url: 'http://test.com',
        reminders: [10, 20],
      );
      final etEvent = event.toETEvent();
      expect(etEvent.id, '1');
      expect(etEvent.title, 'Test Event');
      expect(etEvent.isAllDay, false);
      expect(etEvent.startDate, DateTime(2023, 10, 1));
      expect(etEvent.endDate, DateTime(2023, 10, 2));
      expect(etEvent.calendarId, '1');
      expect(etEvent.description, 'Test Description');
      expect(etEvent.url, 'http://test.com');
      expect(etEvent.reminders, [Duration(minutes: 10), Duration(minutes: 20)]);
    });
  });

  group('ETEventCopy tests', () {
    test('ETEvent copyWithReminders', () {
      final etEvent = ETEvent(
        id: '1',
        title: 'Test Event',
        isAllDay: false,
        startDate: DateTime(2023, 10, 1),
        endDate: DateTime(2023, 10, 2),
        calendarId: '1',
        description: 'Test Description',
        url: 'http://test.com',
        reminders: [Duration(minutes: 10)],
      );
      final copiedEvent = etEvent.copyWithReminders([Duration(minutes: 20)]);
      expect(copiedEvent.reminders, [Duration(minutes: 20)]);
    });
  });

  group('AccountToETAccount tests', () {
    test('Account toETAccount', () {
      final account = Account(name: 'Test Account', type: 'Test Type');
      final etAccount = account.toETAccount();
      expect(etAccount.name, 'Test Account');
      expect(etAccount.type, 'Test Type');
    });
  });

  group('ETAccountToAccount tests', () {
    test('ETAccount toAccount', () {
      final etAccount = ETAccount(name: 'Test Account', type: 'Test Type');
      final account = etAccount.toAccount();
      expect(account.name, 'Test Account');
      expect(account.type, 'Test Type');
    });
  });

  group('CalendarListToETCalendar tests', () {
    test('List<Calendar> toETCalendarList', () {
      final calendars = [
        Calendar(
          id: '1',
          title: 'Test Calendar',
          color: 0xFF123456,
          isWritable: true,
          account: Account(name: 'Test Account', type: 'Test Type'),
        ),
      ];
      final etCalendars = calendars.toETCalendarList();
      expect(etCalendars.length, 1);
      expect(etCalendars.first.id, '1');
    });
  });

  group('EventListToETEvent tests', () {
    test('List<Event> toETEventList', () {
      final events = [
        Event(
          id: '1',
          title: 'Test Event',
          isAllDay: false,
          startDate: DateTime(2023, 10, 1).millisecondsSinceEpoch,
          endDate: DateTime(2023, 10, 2).millisecondsSinceEpoch,
          calendarId: '1',
          description: 'Test Description',
          url: 'http://test.com',
          reminders: [10, 20],
        ),
      ];
      final etEvents = events.toETEventList();
      expect(etEvents.length, 1);
      expect(etEvents.first.id, '1');
    });
  });

  group('NativeToDuration tests', () {
    test('int toDuration on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(10.toDuration(), Duration(seconds: 10));
      debugDefaultTargetPlatformOverride = null;
    });

    test('int toDuration on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(10.toDuration(), Duration(minutes: 10));
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('DurationToNative tests', () {
    test('Duration toNativeDuration on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(Duration(seconds: 10).toNativeDuration(), 10);
      debugDefaultTargetPlatformOverride = null;
    });

    test('Duration toNativeDuration on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(Duration(minutes: 10).toNativeDuration(), 10);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('DurationListToNative tests', () {
    test('List<Duration> toNativeList', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final durations = [Duration(minutes: 10), Duration(minutes: 20)];
      expect(durations.toNativeList(), [10, 20]);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('NativeListToDuration tests', () {
    test('List<int> toDurationList', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final durations = [10, 20];
      expect(durations.toDurationList(),
          [Duration(minutes: 10), Duration(minutes: 20)]);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
