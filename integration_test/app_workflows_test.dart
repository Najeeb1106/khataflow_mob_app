import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khata_app/features/auth/presentation/screens/auth_screen.dart';
import 'package:khata_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:khata_app/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:khata_app/features/people/presentation/providers/people_providers.dart';
import 'package:khata_app/features/khata/presentation/providers/khata_providers.dart';
import 'package:khata_app/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:khata_app/features/people/data/models/person.dart';
import 'package:khata_app/features/khata/data/models/khata.dart';
import 'package:khata_app/features/transactions/data/models/transaction.dart';
import 'package:khata_app/features/people/data/repositories/person_repository.dart';
import 'package:khata_app/features/khata/data/repositories/khata_repository.dart';
import 'package:khata_app/features/transactions/data/repositories/transaction_repository.dart';
import 'package:khata_app/main.dart';

class MockPersonRepository extends Mock implements PersonRepository {}
class MockKhataRepository extends Mock implements KhataRepository {}
class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  group('E2E User Workflows Integration Tests', () {
    late MockPersonRepository mockPersonRepo;
    late MockKhataRepository mockKhataRepo;
    late MockTransactionRepository mockTxRepo;
    late Person testPerson;
    late Khata testKhata;
    late Transaction testTx;

    setUpAll(() {
      registerFallbackValue(Person());
      registerFallbackValue(Khata());
      registerFallbackValue(Transaction());
    });

    setUp(() {
      mockPersonRepo = MockPersonRepository();
      mockKhataRepo = MockKhataRepository();
      mockTxRepo = MockTransactionRepository();

      testPerson = Person()
        ..uuid = 'person-123'
        ..name = 'Adnan Malik'
        ..phone = '03217654321'
        ..isDeleted = false
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      testKhata = Khata()
        ..uuid = 'khata-123'
        ..personUuid = 'person-123'
        ..title = 'Retail Account'
        ..isDeleted = false
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      testTx = Transaction()
        ..uuid = 'tx-123'
        ..khataUuid = 'khata-123'
        ..type = TransactionType.gave
        ..amount = 3500.0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..isDeleted = false;
    });

    testWidgets('Offline User Flow: Login -> View Dashboard -> View Contacts', (WidgetTester tester) async {
      when(() => mockPersonRepo.getPeople(includeDeleted: false))
          .thenAnswer((_) async => [testPerson]);
      when(() => mockKhataRepo.getKhatasForPerson(any(), includeDeleted: any(named: 'includeDeleted')))
          .thenAnswer((_) async => [testKhata]);
      when(() => mockTxRepo.getTransactionsForKhata(any(), includeDeleted: any(named: 'includeDeleted')))
          .thenAnswer((_) async => [testTx]);

      // Mock dashboard provider returns
      final summary = DashboardSummary(
        totalReceivable: 3500.0,
        totalPayable: 0.0,
        netPosition: 3500.0,
      );

      final recentTx = {
        'transaction': testTx,
        'personName': 'Adnan Malik',
        'khataTitle': 'Retail Account',
      };

      final router = GoRouter(
        initialLocation: '/auth',
        routes: [
          GoRoute(
            path: '/auth',
            builder: (context, state) => const AuthScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseEnabledProvider.overrideWithValue(false),
            personRepositoryProvider.overrideWithValue(mockPersonRepo),
            khataRepositoryProvider.overrideWithValue(mockKhataRepo),
            transactionRepositoryProvider.overrideWithValue(mockTxRepo),
            dashboardSummaryProvider.overrideWith((ref) => summary),
            dashboardRecentTransactionsProvider.overrideWith((ref) => [recentTx]),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Auth Page: Click Continue Offline
      expect(find.text('Offline-Only Mode Active'), findsOneWidget);
      await tester.tap(find.text('Continue Offline'));
      await tester.pumpAndSettle();

      // 2. Dashboard Page: Verify balance calculations and recent activity item
      expect(find.text('Net Position'), findsOneWidget);
      expect(find.text('Rs. 3500'), findsOneWidget);
      expect(find.text('Adnan Malik'), findsOneWidget);
    });
  });
}
