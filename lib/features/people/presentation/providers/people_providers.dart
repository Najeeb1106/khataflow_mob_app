import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/person.dart';
import '../../data/repositories/person_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return LocalPersonRepository();
});

class PeopleListNotifier extends StateNotifier<AsyncValue<List<Person>>> {
  final PersonRepository _repository;
  final Ref _ref;

  PeopleListNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadPeople();
  }

  Future<void> loadPeople() async {
    try {
      final people = await _repository.getPeople();
      state = AsyncValue.data(people);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _invalidateDashboard() {
    _ref.invalidate(dashboardSummaryProvider);
    _ref.invalidate(dashboardRecentTransactionsProvider);
  }

  Future<void> addPerson(Person person) async {
    try {
      await _repository.savePerson(person);
      await loadPeople();
      _invalidateDashboard();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updatePerson(Person person) async {
    try {
      await _repository.savePerson(person);
      await loadPeople();
      _invalidateDashboard();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deletePerson(String uuid) async {
    try {
      await _repository.deletePerson(uuid);
      await loadPeople();
      _invalidateDashboard();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final peopleListProvider = StateNotifierProvider<PeopleListNotifier, AsyncValue<List<Person>>>((ref) {
  final repository = ref.watch(personRepositoryProvider);
  return PeopleListNotifier(repository, ref);
});
