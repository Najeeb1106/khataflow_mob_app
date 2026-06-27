import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata_app/core/services/pdf_service.dart';
import 'package:khata_app/features/people/data/models/person.dart';
import 'package:khata_app/features/khata/data/models/khata.dart';
import 'package:khata_app/features/transactions/data/models/transaction.dart';

void main() {
  late PdfService pdfService;
  late Person testPerson;
  late Khata testKhata;
  late Transaction testTx1;
  late Transaction testTx2;

  setUp(() {
    pdfService = PdfService();
    
    testPerson = Person()
      ..uuid = 'p-1'
      ..name = 'Zahid Khan'
      ..phone = '0333-1234567'
      ..isDeleted = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    testKhata = Khata()
      ..uuid = 'k-1'
      ..personUuid = 'p-1'
      ..title = 'Personal Ledger'
      ..isDeleted = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    testTx1 = Transaction()
      ..uuid = 't-1'
      ..khataUuid = 'k-1'
      ..type = TransactionType.gave
      ..amount = 12000.0
      ..notes = 'Credit payment for inventory'
      ..createdAt = DateTime.now().subtract(const Duration(days: 2))
      ..updatedAt = DateTime.now()
      ..isDeleted = false;

    testTx2 = Transaction()
      ..uuid = 't-2'
      ..khataUuid = 'k-1'
      ..type = TransactionType.received
      ..amount = 4500.0
      ..notes = 'Partial repayment'
      ..createdAt = DateTime.now().subtract(const Duration(days: 1))
      ..updatedAt = DateTime.now()
      ..isDeleted = false;
  });

  group('PdfService Unit Tests', () {
    test('generateStatement successfully compiles PDF document bytes', () async {
      final pdfBytes = await pdfService.generateStatement(
        person: testPerson,
        khata: testKhata,
        transactions: [testTx1, testTx2],
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, true);
    });
  });
}
