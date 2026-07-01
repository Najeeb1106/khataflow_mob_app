import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khata_app/features/transactions/data/models/transaction.dart';
import 'package:khata_app/features/transactions/data/repositories/transaction_repository.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Transaction());
  });

  late MockTransactionRepository mockRepo;
  late Transaction testTx;

  setUp(() {
    mockRepo = MockTransactionRepository();
    testTx = Transaction()
      ..uuid = 'tx-uuid-1'
      ..khataUuid = 'khata-uuid-1'
      ..amount = 5000.0
      ..type = TransactionType.gave
      ..isDeleted = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  });

  group('TransactionRepository Tests', () {
    test('getTransactions returns transactions list', () async {
      when(
        () => mockRepo.getTransactions(includeDeleted: false),
      ).thenAnswer((_) async => [testTx]);

      final result = await mockRepo.getTransactions(includeDeleted: false);
      expect(result.length, 1);
      expect(result.first.amount, 5000.0);
      verify(() => mockRepo.getTransactions(includeDeleted: false)).called(1);
    });

    test('getTransactionsForKhata returns transactions under khata', () async {
      when(
        () => mockRepo.getTransactionsForKhata(
          'khata-uuid-1',
          includeDeleted: false,
        ),
      ).thenAnswer((_) async => [testTx]);

      final result = await mockRepo.getTransactionsForKhata(
        'khata-uuid-1',
        includeDeleted: false,
      );
      expect(result.length, 1);
      expect(result.first.khataUuid, 'khata-uuid-1');
      verify(
        () => mockRepo.getTransactionsForKhata(
          'khata-uuid-1',
          includeDeleted: false,
        ),
      ).called(1);
    });

    test('getTransaction returns specific transaction', () async {
      when(
        () => mockRepo.getTransaction('tx-uuid-1'),
      ).thenAnswer((_) async => testTx);

      final result = await mockRepo.getTransaction('tx-uuid-1');
      expect(result, isNotNull);
      expect(result!.amount, 5000.0);
      verify(() => mockRepo.getTransaction('tx-uuid-1')).called(1);
    });

    test('saveTransaction saves or updates transaction', () async {
      when(() => mockRepo.saveTransaction(any())).thenAnswer((_) async => {});

      await mockRepo.saveTransaction(testTx);
      verify(() => mockRepo.saveTransaction(testTx)).called(1);
    });

    test('deleteTransaction soft deletes', () async {
      when(
        () => mockRepo.deleteTransaction('tx-uuid-1'),
      ).thenAnswer((_) async => {});

      await mockRepo.deleteTransaction('tx-uuid-1');
      verify(() => mockRepo.deleteTransaction('tx-uuid-1')).called(1);
    });

    test('permanentlyDeleteTransaction hard deletes', () async {
      when(
        () => mockRepo.permanentlyDeleteTransaction('tx-uuid-1'),
      ).thenAnswer((_) async => {});

      await mockRepo.permanentlyDeleteTransaction('tx-uuid-1');
      verify(
        () => mockRepo.permanentlyDeleteTransaction('tx-uuid-1'),
      ).called(1);
    });
  });
}
