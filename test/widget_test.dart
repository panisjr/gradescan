import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradescan/main.dart';
import 'package:gradescan/screens/main_navigation_screen.dart';
import 'package:gradescan/screens/home_screen.dart';

void main() {
  group('GradeScan App Tests', () {
    testWidgets('Splash screen displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const GradeScanApp());

      // Don't use pumpAndSettle because splash has infinite animations
      await tester.pump(const Duration(milliseconds: 500));

      // Check splash screen elements
      expect(find.text('GradeScan'), findsOneWidget);
      expect(find.text('Smart Answer Sheet Scanner'), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner_rounded), findsOneWidget);
    });

    testWidgets('App shows loading indicator on splash', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const GradeScanApp());

      // Wait for loading to appear
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('Main navigation screen has bottom navigation bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));

      await tester.pump();

      // Check bottom navigation items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Home screen displays welcome message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.pump();

      expect(find.text('Welcome back! 👋'), findsOneWidget);
      expect(find.text('GradeScan'), findsOneWidget);
    });

    testWidgets('Home screen displays stat cards', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.pump();

      expect(find.text('Total Scans'), findsOneWidget);
      expect(find.text('Answer Keys'), findsOneWidget);
      expect(find.text('Avg Score'), findsOneWidget);
      expect(find.text('Highest'), findsOneWidget);
    });

    testWidgets('Home screen displays quick actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.pump();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('New Answer Key'), findsOneWidget);
      expect(find.text('Start Scanning'), findsOneWidget);
      expect(find.text('Export Results'), findsOneWidget);
      expect(find.text('View All Keys'), findsOneWidget);
    });

    testWidgets('Home screen shows empty state for scans', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.pump();

      expect(find.text('Recent Scans'), findsOneWidget);
      expect(find.text('No scans yet'), findsOneWidget);
      expect(
        find.text('Start scanning answer sheets to see results here'),
        findsOneWidget,
      );
    });

    testWidgets('Bottom navigation switches screens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));

      await tester.pump();

      // Initially on Home
      expect(find.text('Welcome back! 👋'), findsOneWidget);

      // Tap on Scan tab
      await tester.tap(find.text('Scan'));
      await tester.pump();

      expect(find.text('Ready to Scan'), findsOneWidget);

      // Tap on History tab
      await tester.tap(find.text('History'));
      await tester.pump();

      expect(find.text('No scan history'), findsOneWidget);

      // Tap on Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pump();

      expect(find.text('Scanner Settings'), findsOneWidget);
    });

    testWidgets('Settings screen displays all sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));

      await tester.pump();

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pump();

      expect(find.text('Scanner Settings'), findsOneWidget);
      expect(find.text('Export Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Auto Flash'), findsOneWidget);
      expect(find.text('Sound Effects'), findsOneWidget);
      expect(find.text('Vibration'), findsOneWidget);
    });

    testWidgets(
      'Scan screen shows create answer key button when no keys exist',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: MainNavigationScreen()),
        );

        await tester.pump();

        // Navigate to Scan
        await tester.tap(find.text('Scan'));
        await tester.pump();

        expect(
          find.text('Create an answer key first to start scanning'),
          findsOneWidget,
        );
        expect(find.text('Create Answer Key'), findsOneWidget);
      },
    );

    testWidgets('Quick action shows snackbar when no answer keys', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      await tester.pump();

      // Tap on Start Scanning without answer keys
      await tester.tap(find.text('Start Scanning'));
      await tester.pump();

      expect(find.text('Please create an answer key first'), findsOneWidget);
    });
  });
}
