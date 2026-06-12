import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:invoice_managment_system/main.dart';
import 'package:invoice_managment_system/services/storage_service.dart';
import 'package:invoice_managment_system/providers/app_state_provider.dart';

void main() {
  testWidgets('App builds and displays login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppStateProvider(storageService),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Re-render
    await tester.pumpAndSettle();

    // Verify login elements exist
    expect(find.text('INVOICEY'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Google sign in initiates OTP verification view', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppStateProvider(storageService),
          ),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Sign in with Google"
    final googleBtn = find.text('Sign in with Google');
    expect(googleBtn, findsOneWidget);
    await tester.tap(googleBtn);
    await tester.pumpAndSettle();

    // Verify Google account chooser is displayed
    expect(find.text('Google Sign In'), findsOneWidget);
    expect(find.text('admin@invoice.com'), findsOneWidget);

    // Tap "admin@invoice.com" chip to fill
    await tester.tap(find.text('admin@invoice.com'));
    await tester.pumpAndSettle();

    // Tap "Sign In" button in dialog
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Sign In')));
    await tester.pumpAndSettle();

    // Verify transitioned to OTP Verification view
    expect(find.text('VERIFY EMAIL'), findsOneWidget);
    expect(find.text('admin@invoice.com'), findsOneWidget);
    expect(find.text('SIMULATED INBOX (no-reply@invoicey.com)'), findsOneWidget);
  });
}
