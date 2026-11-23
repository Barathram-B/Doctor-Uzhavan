import 'package:flutter_test/flutter_test.dart';
import 'package:doctoruzhavan/main.dart';

void main() {
  testWidgets('App loads splash screen smoke test', (WidgetTester tester) async {
    // Build DoctorUzhavanApp
    await tester.pumpWidget(const DoctorUzhavanApp());
    expect(find.byType(DoctorUzhavanApp), findsOneWidget);
  });
}