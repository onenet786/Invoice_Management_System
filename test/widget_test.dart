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

    // Verify initial admin setup screen elements exist on first launch
    expect(find.text('Create Admin Account'), findsOneWidget);
    expect(find.text('Create & Login'), findsOneWidget);
  });

  testWidgets('Biometric login button shows up when enabled', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.invoice_first_run': false,
      'flutter.invoice_users': '[{"id":"u-1","name":"Super Admin","email":"admin@invoice.com","password":"admin","role":"admin"}]',
      'flutter.biometric_enabled': true,
    });
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

    // Verify biometric login button is displayed
    final bioBtn = find.text('Sign in with Biometrics / Thumb');
    expect(bioBtn, findsOneWidget);
  });
}
