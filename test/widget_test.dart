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
}
