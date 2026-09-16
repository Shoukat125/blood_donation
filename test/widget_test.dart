import 'package:flutter_test/flutter_test.dart';
import 'package:blood_donation_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BloodDonationApp());
    expect(find.byType(BloodDonationApp), findsOneWidget);
  });
}
