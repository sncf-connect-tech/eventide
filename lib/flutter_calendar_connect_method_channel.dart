import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_calendar_connect_platform_interface.dart';

/// An implementation of [FlutterCalendarConnectPlatform] that uses method channels.
class MethodChannelFlutterCalendarConnect extends FlutterCalendarConnectPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_calendar_connect');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
