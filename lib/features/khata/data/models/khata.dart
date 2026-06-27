import 'package:isar/isar.dart';

part 'khata.g.dart';

@collection
class Khata {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String personUuid;

  late String title;
  String? notes;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Index()
  late bool isDeleted;
}
