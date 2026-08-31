import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ethioserve/app.dart';

void main() {
  testWidgets('app boots to the language selection screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EthioServeApp()));
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('አማርኛ'), findsOneWidget);
  });

  testWidgets('selecting a language navigates to home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EthioServeApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('What service do you need?'), findsOneWidget);
  });
}
