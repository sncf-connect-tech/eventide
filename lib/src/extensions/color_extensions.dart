import 'dart:ui';

extension ColorToValue on Color {
  int toValue() => _floatToInt8(a) << 24 | _floatToInt8(r) << 16 | _floatToInt8(g) << 8 | _floatToInt8(b) << 0;

  int _floatToInt8(double x) => (x * 255.0).round() & 0xff;
}
