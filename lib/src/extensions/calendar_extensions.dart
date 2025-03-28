import 'dart:ui';

import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/eventide_platform_interface.dart';
import 'package:eventide/src/extensions/account_extensions.dart';

extension CalendarToETCalendar on Calendar {
  ETCalendar toETCalendar() {
    return ETCalendar(
      id: id,
      title: title,
      color: Color(color),
      isWritable: isWritable,
      account: account.toETAccount(),
    );
  }
}

extension CalendarListToETCalendar on List<Calendar> {
  List<ETCalendar> toETCalendarList() {
    return map((c) => c.toETCalendar()).toList();
  }
}
