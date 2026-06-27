import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khata_app/features/people/data/models/person.dart';
import 'package:khata_app/features/people/data/repositories/person_repository.dart';
import 'package:khata_app/features/people/presentation/providers/people_providers.dart';

class MockPersonRepository extends Mock implements PersonRepository {}

void main() {
  late MockPersonRepository mockRepo;
  late Person testPerson;

  setUp(() {
    mockRepo = MockPersonRepository();
    testPerson = Person()
      ..uuid = 'p-1'
      ..name = 'Saleem Khan'
      ..phone = '03001234567'
      ..isDeleted = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    registerFallbackValue(testPerson);
  });

  group('PeopleListNotifier Riverpod Tests', () {
    test('initial state is AsyncLoading and then updates to AsyncData', () async {
      when(() => mockRepo.getPeople(includeDeleted: any(named: 'includeDeleted')))
          .thenAnswer((_) async => [testPerson]);

      final container = ProviderContainer(
        overrides: [
          personRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Verify state starts as loading or resolves to data immediately because of constructor call
      final state = container.read(peopleListProvider);
      expect(state, isA<AsyncLoading<List<Person>>>());

      await container.read(peopleListProvider.notifier).loadPeople();
      final updatedState = container.read(peopleListProvider);
      expect(updatedState.asData!.value.first.name, 'Saleem Khan');
    });

    test('loadPeople sets AsyncError state on repository failure', () async {
      final exception = Exception('Database connection failed');
      when(() => mockRepo.getPeople(includeDeleted: any(named: 'includeDeleted')))
          .thenThrow(exception);

      final container = ProviderContainer(
        overrides: [
          personRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(peopleListProvider.notifier).loadPeople();
      final state = container.read(peopleListProvider);
      expect(state.hasError, true);
      expect(state.error, exception);
    });

    test('addPerson saves a contact and reloads listing', () async {
      when(() => mockRepo.savePerson(any())).thenAnswer((_) async => {});
      when(() => mockRepo.getPeople(includeDeleted: any(named: 'includeDeleted')))
          .thenAnswer((_) async => [testPerson]);

      final container = ProviderContainer(
        overrides: [
          personRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(peopleListProvider.notifier).addPerson(testPerson);
      verify(() => mockRepo.savePerson(testPerson)).called(1);
      
      final state = container.read(peopleListProvider);
      expect(state.asData!.value.length, 1);
    });
  });
}
