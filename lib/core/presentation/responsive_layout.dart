import 'package:material_ui/material_ui.dart';

/// Bootstrap's minimum widths, expressed in Flutter logical pixels.
abstract final class BootstrapBreakpoints {
  static const sm = 576.0;
  static const md = 768.0;
  static const lg = 992.0;
  static const xl = 1200.0;
  static const xxl = 1400.0;
}

/// Chooses a screen layout from the available width, not the current platform.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobileBuilder,
    required this.wideBuilder,
    this.breakpoint = BootstrapBreakpoints.md,
    super.key,
  });

  final WidgetBuilder mobileBuilder;
  final WidgetBuilder wideBuilder;
  final double breakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final builder = constraints.maxWidth < breakpoint
          ? mobileBuilder
          : wideBuilder;
      return builder(context);
    },
  );
}

/// Gives forms comfortable gutters on mobile and a readable width on desktop.
class ResponsiveFormLayout extends StatelessWidget {
  const ResponsiveFormLayout({
    required this.child,
    this.maxWidth = 640,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
    mobileBuilder: (_) =>
        Padding(padding: const EdgeInsets.all(16), child: child),
    wideBuilder: (_) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  );
}
