import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../people/data/models/person.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../../../khata/data/models/khata.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class StatementPreviewScreen extends ConsumerStatefulWidget {
  final String khataUuid;
  const StatementPreviewScreen({super.key, required this.khataUuid});

  @override
  ConsumerState<StatementPreviewScreen> createState() =>
      _StatementPreviewScreenState();
}

class _StatementPreviewScreenState
    extends ConsumerState<StatementPreviewScreen> {
  Person? _person;
  Khata? _khata;
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final khataRepo = ref.read(khataRepositoryProvider);
    final personRepo = ref.read(personRepositoryProvider);
    final txRepo = ref.read(transactionRepositoryProvider);

    final k = await khataRepo.getKhata(widget.khataUuid);
    if (k != null) {
      _khata = k;
      _person = await personRepo.getPerson(k.personUuid);
      _transactions = await txRepo.getTransactionsForKhata(k.uuid);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_khata == null || _person == null) {
      return const Scaffold(
        body: Center(child: Text('Data not found for statement preview.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statement Preview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: PdfPreview(
        build: (format) async {
          return await PdfService().generateStatement(
            person: _person!,
            khata: _khata!,
            transactions: _transactions,
          );
        },
        allowSharing: true,
        allowPrinting: true,
        canDebug: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        previewPageMargin: const EdgeInsets.all(16),
      ),
    );
  }
}
