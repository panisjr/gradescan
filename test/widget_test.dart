import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradescan/screens/main_navigation_screen.dart';
import 'package:gradescan/screens/home_screen.dart';
import 'package:gradescan/screens/scan_screen.dart';
import 'package:gradescan/screens/history_screen.dart';
import 'package:gradescan/screens/settings_screen.dart';

void main() {
  group('GradeScan App Tests', () {
    testWidgets('Main navigation has all tabs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Home screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();

      expect(find.text('Welcome back! 👋'), findsOneWidget);
      expect(find.text('GradeScan'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Recent Scans'), findsOneWidget);
    });

    testWidgets('Home screen shows stat cards', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();

      expect(find.text('Total Scans'), findsOneWidget);
      expect(find.text('Answer Keys'), findsOneWidget);
      expect(find.text('Avg Score'), findsOneWidget);
      expect(find.text('Highest'), findsOneWidget);
    });

    testWidgets('Home screen shows quick action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();

      expect(find.text('New Answer Key'), findsOneWidget);
      expect(find.text('Start Scanning'), findsOneWidget);
      expect(find.text('Export Results'), findsOneWidget);
      expect(find.text('View All Keys'), findsOneWidget);
    });

    testWidgets('Scan screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScanScreen()));
      await tester.pump();

      expect(find.text('Ready to Scan'), findsOneWidget);
      expect(find.text('Create Answer Key'), findsOneWidget);
    });

    testWidgets('History screen shows empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
      await tester.pump();

      expect(find.text('No scan history'), findsOneWidget);
    });

    testWidgets('Settings screen displays all sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();

      expect(find.text('Scanner Settings'), findsOneWidget);
      expect(find.text('Export Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('Navigation switches between tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
      await tester.pump();

      // Home is default
      expect(find.text('Welcome back! 👋'), findsOneWidget);

      // Go to Scan
      await tester.tap(find.text('Scan'));
      await tester.pump();
      expect(find.text('Ready to Scan'), findsOneWidget);

      // Go to History
      await tester.tap(find.text('History'));
      await tester.pump();
      expect(find.text('No scan history'), findsOneWidget);

      // Go to Settings
      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(find.text('Scanner Settings'), findsOneWidget);

      // Go back to Home
      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(find.text('Welcome back! 👋'), findsOneWidget);
    });
  });
}
