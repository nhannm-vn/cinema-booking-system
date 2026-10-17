import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const none = BorderRadius.zero;
  static const xs = BorderRadius.all(Radius.circular(2));
  static const sm = BorderRadius.all(Radius.circular(4));
  static const xl = BorderRadius.all(Radius.circular(12));
  static const full = BorderRadius.all(Radius.circular(9999));
}
