import 'package:isar/isar.dart';

part 'person.g.dart';

@collection
class Person {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String name;
  String? phone;
  String? notes;
  
  late DateTime createdAt;
  late DateTime updatedAt;
  
  @Index()
  late bool isDeleted;
}
