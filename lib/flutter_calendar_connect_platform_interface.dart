import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_calendar_connect_method_channel.dart';

abstract class FlutterCalendarConnectPlatform extends PlatformInterface {
  /// Constructs a FlutterCalendarConnectPlatform.
  FlutterCalendarConnectPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterCalendarConnectPlatform _instance = MethodChannelFlutterCalendarConnect();

  /// The default instance of [FlutterCalendarConnectPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterCalendarConnect].
  static FlutterCalendarConnectPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterCalendarConnectPlatform] when
  /// they register themselves.
  static set instance(FlutterCalendarConnectPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
