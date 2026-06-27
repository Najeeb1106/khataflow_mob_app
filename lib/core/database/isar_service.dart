import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/people/data/models/person.dart';
import '../../features/khata/data/models/khata.dart';
import '../../features/transactions/data/models/transaction.dart';

import '../services/security_service.dart';

class IsarService {
  static Isar? _instance;

  static Isar get instance {
    if (_instance == null) {
      throw StateError("Isar has not been initialized. Call initialize() first.");
    }
    return _instance!;
  }

  static set instance(Isar mock) => _instance = mock;

  static Future<void> initialize() async {
    if (_instance != null) return;
    
    final dir = await getApplicationDocumentsDirectory();
    final encryptionKey = await SecurityService.getDatabaseKey();
    
    _instance = await Isar.open(
      [
        PersonSchema,
        KhataSchema,
        TransactionSchema,
      ],
      directory: dir.path,
      // Note: Isar v3.1.0+1 does not natively support database-level encryption in the open method.
      // The key is securely retrieved from flutter_secure_storage and prepared here.
      // Upgrading to Isar v4 with SQLite engine is required for raw database-at-rest encryption.
    );
  }
}
