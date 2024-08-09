import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'calendar_platform_interface.dart';

/// An implementation of [CalendarPlatform] that uses method channels.
class MethodChannelCalendar extends CalendarPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('calendar');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
