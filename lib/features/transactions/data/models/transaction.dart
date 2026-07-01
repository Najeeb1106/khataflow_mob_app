import 'package:isar/isar.dart';

part 'transaction.g.dart';

enum TransactionType { gave, received, borrowed, paid, adjustment }

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String khataUuid;

  @enumerated
  late TransactionType type;

  late double amount;
  String? notes;
  DateTime? dueDate;
  DateTime? reminderDate;
  DateTime? transactionDate;
  String? photoUrl;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Index()
  late bool isDeleted;
}
