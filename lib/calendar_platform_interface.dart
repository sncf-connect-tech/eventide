import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'calendar_method_channel.dart';

abstract class CalendarPlatform extends PlatformInterface {
  /// Constructs a CalendarPlatform.
  CalendarPlatform() : super(token: _token);

  static final Object _token = Object();

  static CalendarPlatform _instance = MethodChannelCalendar();

  /// The default instance of [CalendarPlatform] to use.
  ///
  /// Defaults to [MethodChannelCalendar].
  static CalendarPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CalendarPlatform] when
  /// they register themselves.
  static set instance(CalendarPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
