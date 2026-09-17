import 'package:flutter/material.dart';

/// Caps phone-designed content at a comfortable reading/card width on wide
/// tablet screens instead of letting it stretch edge-to-edge - the first
/// breakpoint-style widget in this app (no existing convention to follow;
/// establishes one). No-op on phone widths, since `maxWidth` only kicks in
/// once the screen is wider than it.
class ResponsiveContentWidth extends StatelessWidget {
  const ResponsiveContentWidth({
    required this.child,
    this.maxWidth = 640,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
