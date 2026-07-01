import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khata_app/features/people/data/models/person.dart';
import 'package:khata_app/features/people/data/repositories/person_repository.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Person());
  });

  late MockPersonRepository mockRepo;
  late Person testPerson;

  setUp(() {
    mockRepo = MockPersonRepository();
    testPerson = Person()
      ..uuid = 'test-uuid-1'
      ..name = 'Alice Smith'
      ..phone = '03215551234'
      ..isDeleted = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  });

  group('PersonRepository Tests', () {
    test(
      'getPeople returns active persons when includeDeleted is false',
      () async {
        when(
          () => mockRepo.getPeople(includeDeleted: false),
        ).thenAnswer((_) async => [testPerson]);

        final result = await mockRepo.getPeople(includeDeleted: false);
        expect(result.length, 1);
        expect(result.first.name, 'Alice Smith');
        verify(() => mockRepo.getPeople(includeDeleted: false)).called(1);
      },
    );

    test('getPerson returns the correct person', () async {
      when(
        () => mockRepo.getPerson('test-uuid-1'),
      ).thenAnswer((_) async => testPerson);

      final result = await mockRepo.getPerson('test-uuid-1');
      expect(result, isNotNull);
      expect(result!.name, 'Alice Smith');
      verify(() => mockRepo.getPerson('test-uuid-1')).called(1);
    });

    test('savePerson persists person successfully', () async {
      when(() => mockRepo.savePerson(any())).thenAnswer((_) async => {});

      await mockRepo.savePerson(testPerson);
      verify(() => mockRepo.savePerson(testPerson)).called(1);
    });

    test('deletePerson soft deletes the person', () async {
      when(
        () => mockRepo.deletePerson('test-uuid-1'),
      ).thenAnswer((_) async => {});

      await mockRepo.deletePerson('test-uuid-1');
      verify(() => mockRepo.deletePerson('test-uuid-1')).called(1);
    });

    test('permanentlyDeletePerson hard deletes the person', () async {
      when(
        () => mockRepo.permanentlyDeletePerson('test-uuid-1'),
      ).thenAnswer((_) async => {});

      await mockRepo.permanentlyDeletePerson('test-uuid-1');
      verify(() => mockRepo.permanentlyDeletePerson('test-uuid-1')).called(1);
    });
  });
}
