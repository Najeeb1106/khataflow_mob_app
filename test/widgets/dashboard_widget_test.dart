import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khata_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:khata_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:khata_app/features/transactions/data/models/transaction.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    testWidgets('displays dashboard summary cards and transaction activity', (WidgetTester tester) async {
      final summary = DashboardSummary(
        totalReceivable: 15000.0,
        totalPayable: 5000.0,
        netPosition: 10000.0,
      );

      final recentTx = {
        'transaction': Transaction()
          ..uuid = 'tx-1'
          ..khataUuid = 'k-1'
          ..type = TransactionType.gave
          ..amount = 500.0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..isDeleted = false,
        'personName': 'Imran Khan',
        'khataTitle': 'Grocery Ledger',
      };

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/trash',
            builder: (context, state) => const Scaffold(body: Text('Trash Page')),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const Scaffold(body: Text('Notifications Page')),
          ),
          GoRoute(
            path: '/transaction/quick-add',
            builder: (context, state) => const Scaffold(body: Text('Quick Add Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardSummaryProvider.overrideWith((ref) => summary),
            dashboardRecentTransactionsProvider.overrideWith((ref) => [recentTx]),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Verify UI components and labels render correctly
      expect(find.text('KhataFlow'), findsOneWidget);
      expect(find.text('NET POSITION'), findsOneWidget);
      expect(find.text('Rs. 10000'), findsOneWidget);
      expect(find.text('Rs. 15000'), findsOneWidget);
      expect(find.text('Rs. 5000'), findsOneWidget);

      // Verify recent transaction item details
      expect(find.text('Imran Khan'), findsOneWidget);
      expect(find.text('Rs. 500'), findsOneWidget);

      // Click Quick Add to verify navigation
      await tester.tap(find.text('Quick Add'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Add Page'), findsOneWidget);
    });
  });
}
