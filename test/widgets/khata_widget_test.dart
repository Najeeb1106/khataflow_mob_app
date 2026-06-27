import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khata_app/features/khata/presentation/screens/khata_detail_screen.dart';
import 'package:khata_app/features/khata/presentation/providers/khata_providers.dart';
import 'package:khata_app/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:khata_app/features/khata/data/models/khata.dart';
import 'package:khata_app/features/transactions/data/models/transaction.dart';
import 'package:khata_app/features/khata/data/repositories/khata_repository.dart';
import 'package:khata_app/features/transactions/data/repositories/transaction_repository.dart';

class MockKhataRepository extends Mock implements KhataRepository {}
class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockKhataRepository mockKhataRepo;
  late MockTransactionRepository mockTxRepo;
  late Khata testKhata;
  late Transaction testTx;

  setUpAll(() {
    registerFallbackValue(Khata());
    registerFallbackValue(Transaction());
  });

  setUp(() {
    mockKhataRepo = MockKhataRepository();
    mockTxRepo = MockTransactionRepository();
    testKhata = Khata()
      ..uuid = 'khata-1'
      ..personUuid = 'person-1'
      ..title = 'Business Ledger'
      ..isDeleted = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    testTx = Transaction()
      ..uuid = 'tx-1'
      ..khataUuid = 'khata-1'
      ..type = TransactionType.gave
      ..amount = 4500.0
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isDeleted = false;
  });

  group('KhataDetailScreen Widget Tests', () {
    testWidgets('renders khata header details and transactions list', (WidgetTester tester) async {
      when(() => mockKhataRepo.getKhata('khata-1')).thenAnswer((_) async => testKhata);
      when(() => mockTxRepo.getTransactionsForKhata('khata-1')).thenAnswer((_) async => [testTx]);

      final router = GoRouter(
        initialLocation: '/khata/khata-1',
        routes: [
          GoRoute(
            path: '/khata/:khataUuid',
            builder: (context, state) => KhataDetailScreen(khataUuid: state.pathParameters['khataUuid']!),
          ),
          GoRoute(
            path: '/statement/:khataUuid',
            builder: (context, state) => const Scaffold(body: Text('Statement Page')),
          ),
          GoRoute(
            path: '/transaction/advanced',
            builder: (context, state) => const Scaffold(body: Text('Add Tx Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            khataRepositoryProvider.overrideWithValue(mockKhataRepo),
            transactionRepositoryProvider.overrideWithValue(mockTxRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Settle initial load
      await tester.pumpAndSettle();

      // Verify page layout renders
      expect(find.text('Business Ledger'), findsOneWidget);
      expect(find.text('Outstanding Receivable'), findsOneWidget);
      expect(find.text('Rs. 4500'), findsNWidgets(2));

      // Tap Statement Button in appBar to trigger navigation
      await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Statement Page'), findsOneWidget);
    });
  });
}
