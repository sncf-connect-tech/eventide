import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_calendar_connect/flutter_calendar_connect.dart';
import 'package:flutter_calendar_connect/flutter_calendar_connect_platform_interface.dart';
import 'package:flutter_calendar_connect/flutter_calendar_connect_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterCalendarConnectPlatform
    with MockPlatformInterfaceMixin
    implements FlutterCalendarConnectPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterCalendarConnectPlatform initialPlatform = FlutterCalendarConnectPlatform.instance;

  test('$MethodChannelFlutterCalendarConnect is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterCalendarConnect>());
  });

  test('getPlatformVersion', () async {
    FlutterCalendarConnect flutterCalendarConnectPlugin = FlutterCalendarConnect();
    MockFlutterCalendarConnectPlatform fakePlatform = MockFlutterCalendarConnectPlatform();
    FlutterCalendarConnectPlatform.instance = fakePlatform;

    expect(await flutterCalendarConnectPlugin.getPlatformVersion(), '42');
  });
}
