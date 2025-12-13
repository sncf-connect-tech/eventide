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

extension DurationListToNative on Iterable<Duration> {
  List<int> toNativeList() {
    return map((d) => d.toNativeDuration()).toList();
  }
}

extension NativeListToDuration on Iterable<int> {
  List<Duration> toDurationList() {
    return map((i) => i.toDuration()).toList();
  }
}
