import 'package:ethioserve/core/widgets/responsive_content_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// First test in the repo that simulates screen width directly (via
// tester.view.physicalSize/devicePixelRatio) - no existing pattern to
// follow elsewhere in mobile/test.
void main() {
  const childKey = Key('child');

  Widget wrap() => MaterialApp(
    home: Center(
      child: ResponsiveContentWidth(
        maxWidth: 640,
        child: Container(key: childKey, color: Colors.red),
      ),
    ),
  );

  testWidgets('lets content fill a narrow (phone-width) screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());

    final width = tester.getSize(find.byKey(childKey)).width;
    expect(width, 400);
  });

  testWidgets('caps content width on a wide (tablet-width) screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());

    final width = tester.getSize(find.byKey(childKey)).width;
    expect(width, 640);
  });
}
