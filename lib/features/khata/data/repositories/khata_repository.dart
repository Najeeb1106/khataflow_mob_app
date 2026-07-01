import 'package:isar/isar.dart';
import '../../../../core/database/isar_service.dart';
import '../models/khata.dart';

abstract class KhataRepository {
  Future<List<Khata>> getKhatas({bool includeDeleted = false});
  Future<List<Khata>> getKhatasForPerson(
    String personUuid, {
    bool includeDeleted = false,
  });
  Future<Khata?> getKhata(String uuid);
  Future<void> saveKhata(Khata khata);
  Future<void> deleteKhata(String uuid);
  Future<void> permanentlyDeleteKhata(String uuid);
}

class LocalKhataRepository implements KhataRepository {
  final Isar isar = IsarService.instance;

  @override
  Future<List<Khata>> getKhatas({bool includeDeleted = false}) async {
    if (includeDeleted) {
      return isar.khatas.where().findAll();
    } else {
      return isar.khatas.filter().isDeletedEqualTo(false).findAll();
    }
  }

  @override
  Future<List<Khata>> getKhatasForPerson(
    String personUuid, {
    bool includeDeleted = false,
  }) async {
    if (includeDeleted) {
      return isar.khatas.filter().personUuidEqualTo(personUuid).findAll();
    } else {
      return isar.khatas
          .filter()
          .personUuidEqualTo(personUuid)
          .isDeletedEqualTo(false)
          .findAll();
    }
  }

  @override
  Future<Khata?> getKhata(String uuid) async {
    return isar.khatas.filter().uuidEqualTo(uuid).findFirst();
  }

  @override
  Future<void> saveKhata(Khata khata) async {
    khata.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.khatas.put(khata);
    });
  }

  @override
  Future<void> deleteKhata(String uuid) async {
    final khata = await getKhata(uuid);
    if (khata != null) {
      khata.isDeleted = true;
      khata.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.khatas.put(khata);
      });
    }
  }

  @override
  Future<void> permanentlyDeleteKhata(String uuid) async {
    final khata = await getKhata(uuid);
    if (khata != null) {
      await isar.writeTxn(() async {
        await isar.khatas.delete(khata.id);
      });
    }
  }
}
