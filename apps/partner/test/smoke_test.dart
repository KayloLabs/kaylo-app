import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/main.dart';

void main() {
  testWidgets('partner app boots with the shared theme and a home screen',
      (tester) async {
    await tester.pumpWidget(const KayloPartnerApp());
    await tester.pump();

    expect(find.text('Kaylo Partner'), findsOneWidget);
    expect(find.text('Jobs inbox coming next'), findsOneWidget);
  });
}
