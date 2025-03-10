import 'package:flutter/foundation.dart';

extension NativeToDuration on int {
  Duration toDuration() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return Duration(seconds: abs());
      case TargetPlatform.android:
        return Duration(minutes: abs());
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}

extension DurationToNative on Duration {
  int toNativeDuration() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return inSeconds.abs();
      case TargetPlatform.android:
        return inMinutes.abs();
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}

extension DurationListToNative on List<Duration> {
  List<int> toNativeList() {
    return map((d) => d.toNativeDuration()).toList();
  }
}

extension NativeListToDuration on List<int> {
  List<Duration> toDurationList() {
    return map((i) => i.toDuration()).toList();
  }
}
