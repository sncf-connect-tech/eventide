extension NativeToDuration on int {
  Duration toDuration() => Duration(minutes: abs());
}

extension DurationToNative on Duration {
  int toNativeDuration() => inMinutes.abs();
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
