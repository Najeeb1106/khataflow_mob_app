import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/khata.dart';
import '../../data/repositories/khata_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final khataRepositoryProvider = Provider<KhataRepository>((ref) {
  return LocalKhataRepository();
});

class KhataListNotifier extends StateNotifier<AsyncValue<List<Khata>>> {
  final KhataRepository _repository;
  final String _personUuid;
  final Ref _ref;

  KhataListNotifier(this._repository, this._personUuid, this._ref)
    : super(const AsyncValue.loading()) {
    loadKhatas();
  }

  Future<void> loadKhatas() async {
    try {
      final khatas = await _repository.getKhatasForPerson(_personUuid);
      state = AsyncValue.data(khatas);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _invalidateDashboard() {
    _ref.invalidate(dashboardSummaryProvider);
    _ref.invalidate(dashboardRecentTransactionsProvider);
  }

  Future<void> addKhata(Khata khata) async {
    try {
      await _repository.saveKhata(khata);
      await loadKhatas();
      _invalidateDashboard();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateKhata(Khata khata) async {
    try {
      await _repository.saveKhata(khata);
      await loadKhatas();
      _invalidateDashboard();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteKhata(String uuid) async {
    try {
      await _repository.deleteKhata(uuid);
      await loadKhatas();
      _invalidateDashboard();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final khatasForPersonProvider =
    StateNotifierProvider.family<
      KhataListNotifier,
      AsyncValue<List<Khata>>,
      String
    >((ref, personUuid) {
      final repository = ref.watch(khataRepositoryProvider);
      return KhataListNotifier(repository, personUuid, ref);
    });
