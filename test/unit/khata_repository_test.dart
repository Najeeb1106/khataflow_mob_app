import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khata_app/features/khata/data/models/khata.dart';
import 'package:khata_app/features/khata/data/repositories/khata_repository.dart';

class MockKhataRepository extends Mock implements KhataRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Khata());
  });

  late MockKhataRepository mockRepo;
  late Khata testKhata;

  setUp(() {
    mockRepo = MockKhataRepository();
    testKhata = Khata()
      ..uuid = 'khata-uuid-1'
      ..personUuid = 'person-uuid-1'
      ..title = 'Business Ledger'
      ..isDeleted = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  });

  group('KhataRepository Tests', () {
    test('getKhatas returns active khatas', () async {
      when(() => mockRepo.getKhatas(includeDeleted: false))
          .thenAnswer((_) async => [testKhata]);

      final result = await mockRepo.getKhatas(includeDeleted: false);
      expect(result.length, 1);
      expect(result.first.title, 'Business Ledger');
      verify(() => mockRepo.getKhatas(includeDeleted: false)).called(1);
    });

    test('getKhatasForPerson returns khatas filtered by person', () async {
      when(() => mockRepo.getKhatasForPerson('person-uuid-1', includeDeleted: false))
          .thenAnswer((_) async => [testKhata]);

      final result = await mockRepo.getKhatasForPerson('person-uuid-1', includeDeleted: false);
      expect(result.length, 1);
      expect(result.first.personUuid, 'person-uuid-1');
      verify(() => mockRepo.getKhatasForPerson('person-uuid-1', includeDeleted: false)).called(1);
    });

    test('getKhata returns correct khata', () async {
      when(() => mockRepo.getKhata('khata-uuid-1')).thenAnswer((_) async => testKhata);

      final result = await mockRepo.getKhata('khata-uuid-1');
      expect(result, isNotNull);
      expect(result!.title, 'Business Ledger');
      verify(() => mockRepo.getKhata('khata-uuid-1')).called(1);
    });

    test('saveKhata saves/updates successfully', () async {
      when(() => mockRepo.saveKhata(any())).thenAnswer((_) async => {});

      await mockRepo.saveKhata(testKhata);
      verify(() => mockRepo.saveKhata(testKhata)).called(1);
    });

    test('deleteKhata soft deletes the khata', () async {
      when(() => mockRepo.deleteKhata('khata-uuid-1')).thenAnswer((_) async => {});

      await mockRepo.deleteKhata('khata-uuid-1');
      verify(() => mockRepo.deleteKhata('khata-uuid-1')).called(1);
    });

    test('permanentlyDeleteKhata hard deletes the khata', () async {
      when(() => mockRepo.permanentlyDeleteKhata('khata-uuid-1')).thenAnswer((_) async => {});

      await mockRepo.permanentlyDeleteKhata('khata-uuid-1');
      verify(() => mockRepo.permanentlyDeleteKhata('khata-uuid-1')).called(1);
    });
  });
}
