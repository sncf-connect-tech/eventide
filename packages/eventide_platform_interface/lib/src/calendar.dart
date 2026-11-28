import 'dart:ui';

import 'package:eventide_platform_interface/src/account.dart';

/// Represents a calendar.
///
/// [id] is a unique identifier for the calendar.
///
/// [title] is the title of the calendar.
///
/// [color] is the color of the calendar.
///
/// [isWritable] is a boolean to indicate if the calendar is writable.
///
/// [account] is the account/source of the calendar.
final class ETCalendar {
  final String id;
  final String title;
  final Color color;
  final bool isWritable;
  final ETAccount account;

  @override
  int get hashCode => Object.hash(id, title, color, isWritable, account);

  const ETCalendar({
    required this.id,
    required this.title,
    required this.color,
    required this.isWritable,
    required this.account,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is ETCalendar &&
          other.id == id &&
          other.title == title &&
          other.color == color &&
          other.isWritable == isWritable &&
          other.account == account;
}
