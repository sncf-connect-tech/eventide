import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:eventide/src/extensions/color_extensions.dart';
import 'package:eventide/src/extensions/duration_extensions.dart';

void main() {
  group('ColorToValue tests', () {
    test('Color toValue', () {
      const color = Color(0xFF123456);
      expect(color.toValue(), 0xFF123456);
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

    test('List<Duration> toNativeList', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final durations = [Duration(minutes: 10), Duration(minutes: 20)];
      expect(durations.toNativeList(), [10, 20]);
      debugDefaultTargetPlatformOverride = null;
    });

    test('List<int> toDurationList', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final durations = [10, 20];
      expect(durations.toDurationList(), [Duration(minutes: 10), Duration(minutes: 20)]);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
