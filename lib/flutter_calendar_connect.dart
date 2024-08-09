
import 'flutter_calendar_connect_platform_interface.dart';

class FlutterCalendarConnect {
  Future<String?> getPlatformVersion() {
    return FlutterCalendarConnectPlatform.instance.getPlatformVersion();
  }
}
