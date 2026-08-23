/// A 4pt base scale. Named so layout reads as intent, not arithmetic.
abstract final class Insets {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 72.0;
}

abstract final class Radii {
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const pill = 999.0;
}

abstract final class Breakpoints {
  static const compact = 640.0;
  static const medium = 1024.0;
  static const expanded = 1440.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
}
