import 'package:flutter/widgets.dart';

/// Breakpoints + helpers for mobile / tablet / desktop adaptive layouts.
enum DeviceType { mobile, tablet, desktop }

abstract class Breakpoints {
  static const double tablet = 720;
  static const double desktop = 1080;
}

extension ResponsiveContext on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;

  DeviceType get deviceType {
    final w = width;
    if (w >= Breakpoints.desktop) return DeviceType.desktop;
    if (w >= Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Picks a value based on the active breakpoint, falling back gracefully.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// Comfortable max content width so desktop pages don't stretch forever.
  double get contentMaxWidth => isDesktop ? 1120 : double.infinity;
}

/// Centers and constrains page content on wide screens.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: maxWidth ?? context.contentMaxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
