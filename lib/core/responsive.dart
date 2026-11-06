import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Layout sizes for phones and tablets. On a wide screen the content keeps a
/// readable width and sits in the middle instead of stretching edge to edge.
class Responsive {
  Responsive._();

  /// Screens at least this wide (in logical pixels) get the tablet layout.
  static const double tabletBreakpoint = 700;

  /// Widest a list of cards may grow.
  static const double maxContentWidth = 880;

  /// Widest a form or bottom sheet may grow.
  static const double maxFormWidth = 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Side padding that centres the content and caps it at [maxWidth].
  static double sidePadding(
    BuildContext context, {
    double min = 16,
    double maxWidth = maxContentWidth,
  }) {
    final width = MediaQuery.sizeOf(context).width - (isTablet(context) ? railWidth : 0);
    return math.max(min, (width - maxWidth) / 2);
  }

  /// Width of the side navigation shown on tablets.
  static const double railWidth = 96;
}
