import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportExportLog {
  final String uuid;
  final String khataTitle;
  final String personName;
  final DateTime exportedAt;
  final String format; // "PDF" / "Excel"

  ReportExportLog({
    required this.uuid,
    required this.khataTitle,
    required this.personName,
    required this.exportedAt,
    required this.format,
  });
}

class ReportHistoryNotifier extends StateNotifier<List<ReportExportLog>> {
  ReportHistoryNotifier() : super([]);

  void logExport({
    required String khataTitle,
    required String personName,
    String format = 'PDF',
  }) {
    final log = ReportExportLog(
      uuid: DateTime.now().millisecondsSinceEpoch.toString(),
      khataTitle: khataTitle,
      personName: personName,
      exportedAt: DateTime.now(),
      format: format,
    );
    state = [log, ...state];
  }
}

final reportHistoryProvider =
    StateNotifierProvider<ReportHistoryNotifier, List<ReportExportLog>>((ref) {
      return ReportHistoryNotifier();
    });
