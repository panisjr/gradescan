// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:gradescan/main.dart';

void main() {
  testWidgets('GradeScan landing page loads correctly', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GradeScanApp());

    // Verify that the app title is displayed
    expect(find.text('GradeScan'), findsWidgets);

    // Verify the main tagline is displayed
    expect(find.text('Scan. Grade. Export.'), findsOneWidget);

    // Verify key sections exist
    expect(find.text('FEATURES'), findsOneWidget);
    expect(find.text('HOW IT WORKS'), findsOneWidget);
    expect(find.text('BENEFITS'), findsOneWidget);
    expect(find.text('TESTIMONIALS'), findsOneWidget);
  });

  testWidgets('Navigation bar is present', (WidgetTester tester) async {
    await tester.pumpWidget(const GradeScanApp());

    // Check for navigation elements
    expect(find.text('Features'), findsWidgets);
    expect(find.text('Download App'), findsWidgets);
  });

  testWidgets('Feature cards are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const GradeScanApp());

    // Allow the widget to fully build
    await tester.pumpAndSettle();

    // Scroll to features section
    await tester.scrollUntilVisible(find.text('Smart Scanning'), 200.0);

    // Verify feature cards
    expect(find.text('Smart Scanning'), findsOneWidget);
    expect(find.text('Instant Grading'), findsOneWidget);
    expect(find.text('Excel Export'), findsOneWidget);
  });

  testWidgets('How it works steps are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const GradeScanApp());
    await tester.pumpAndSettle();

    // Scroll to How It Works section
    await tester.scrollUntilVisible(find.text('Three Simple Steps'), 200.0);

    // Verify the three steps
    expect(find.text('Scan'), findsWidgets);
    expect(find.text('Grade'), findsWidgets);
    expect(find.text('Export'), findsWidgets);
  });

  testWidgets('CTA section has download buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const GradeScanApp());
    await tester.pumpAndSettle();

    // Scroll to CTA section
    await tester.scrollUntilVisible(
      find.text('Ready to Transform Your Grading?'),
      200.0,
    );

    expect(find.text('Ready to Transform Your Grading?'), findsOneWidget);
    expect(find.text('Download for Android'), findsOneWidget);
    expect(find.text('Download for iOS'), findsOneWidget);
  });

  testWidgets('Stats section displays metrics', (WidgetTester tester) async {
    await tester.pumpWidget(const GradeScanApp());
    await tester.pumpAndSettle();

    // Scroll to Stats section
    await tester.scrollUntilVisible(find.text('50,000+'), 200.0);

    expect(find.text('50,000+'), findsOneWidget);
    expect(find.text('Sheets Scanned'), findsOneWidget);
    expect(find.text('99.5%'), findsOneWidget);
    expect(find.text('Accuracy Rate'), findsOneWidget);
  });
}
