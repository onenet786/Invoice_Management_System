import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:invoice_managment_system/main.dart';
import 'package:invoice_managment_system/services/storage_service.dart';
import 'package:invoice_managment_system/providers/app_state_provider.dart';
import 'package:invoice_managment_system/views/settings/settings_screen.dart';

void main() {
  testWidgets('fresh install displays onboarding choices', (
    WidgetTester tester,
  ) async {
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

    expect(find.text('Welcome to Invoicey'), findsOneWidget);
    expect(find.text('Set up my company'), findsOneWidget);
    expect(find.text('Explore sample company'), findsOneWidget);
  });

  testWidgets('completed install displays login screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'invoice_first_run': false});
    final storageService = await StorageService.init();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStateProvider(storageService),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('INVOICEY'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('company setup is usable at 375px phone width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStateProvider(storageService),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up my company'));
    await tester.pumpAndSettle();
    expect(find.text('Set up your company'), findsOneWidget);
    expect(find.text('Create my workspace'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all main screens lay out at phone width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(411, 891);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStateProvider(storageService),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore sample company'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    for (final label in [
      'Dashboard',
      'Invoices',
      'Clients',
      'Inventory',
      'Settings',
    ]) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label overflowed');
    }
  });

  testWidgets('settings accepts a custom stored currency', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'invoice_first_run': false,
      'invoice_users':
          '[{"id":"u-1","name":"Admin","email":"admin@test.com","password":"secret","role":"admin"}]',
      'invoice_company':
          '{"name":"Test Company","logo":"","taxId":"TAX-1","address":"Pakistan","currency":"SAR"}',
      'invoice_clients': '[]',
      'invoice_products': '[]',
      'invoice_invoices': '[]',
    });
    final storageService = await StorageService.init();
    final provider = AppStateProvider(storageService);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SAR (Custom)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
