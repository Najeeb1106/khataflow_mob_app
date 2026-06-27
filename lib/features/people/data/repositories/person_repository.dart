import 'package:isar/isar.dart';
import '../../../../core/database/isar_service.dart';
import '../models/person.dart';

abstract class PersonRepository {
  Future<List<Person>> getPeople({bool includeDeleted = false});
  Future<Person?> getPerson(String uuid);
  Future<void> savePerson(Person person);
  Future<void> deletePerson(String uuid);
  Future<void> permanentlyDeletePerson(String uuid);
}

class LocalPersonRepository implements PersonRepository {
  final Isar isar = IsarService.instance;

  @override
  Future<List<Person>> getPeople({bool includeDeleted = false}) async {
    if (includeDeleted) {
      return isar.persons.where().findAll();
    } else {
      return isar.persons.filter().isDeletedEqualTo(false).findAll();
    }
  }

  @override
  Future<Person?> getPerson(String uuid) async {
    return isar.persons.filter().uuidEqualTo(uuid).findFirst();
  }

  @override
  Future<void> savePerson(Person person) async {
    person.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.persons.put(person);
    });
  }

  @override
  Future<void> deletePerson(String uuid) async {
    final person = await getPerson(uuid);
    if (person != null) {
      person.isDeleted = true;
      person.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.persons.put(person);
      });
    }
  }

  @override
  Future<void> permanentlyDeletePerson(String uuid) async {
    final person = await getPerson(uuid);
    if (person != null) {
      await isar.writeTxn(() async {
        await isar.persons.delete(person.id);
      });
    }
  }
}
