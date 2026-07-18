import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../features/people/data/models/person.dart';
import '../../features/khata/data/models/khata.dart';
import '../../features/transactions/data/models/transaction.dart';
import '../utils/phone_formatter.dart';

class PdfService {
  Future<Uint8List> generateStatement({
    required Person person,
    required Khata khata,
    required List<Transaction> transactions,
  }) async {
    final pdf = pw.Document();

    // Calculate balances and stats
    double closingBalance = 0.0;
    double totalLent = 0.0;
    double totalReceived = 0.0;
    int totalCount = transactions.length;

    // Sort transactions oldest first to calculate running balance correctly
    final sortedTxs = List<Transaction>.from(transactions)
      ..sort((a, b) {
        final dateA = a.transactionDate ?? a.createdAt;
        final dateB = b.transactionDate ?? b.createdAt;
        return dateA.compareTo(dateB);
      });

    double runningBalance = 0.0;
    final List<pw.TableRow> rows = [];

    // Table Header
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFF0F766E), // Teal 700
          borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
        ),
        children: [
          _buildHeaderCell('Given Date'),
          _buildHeaderCell('Due Date'),
          _buildHeaderCell('Type'),
          _buildHeaderCell('Notes'),
          _buildHeaderCell('Amount', alignRight: true),
          _buildHeaderCell('Balance', alignRight: true),
        ],
      ),
    );

    int rowIndex = 0;
    for (final tx in sortedTxs) {
      bool isPositive = false;
      if (tx.type == TransactionType.gave || tx.type == TransactionType.paid) {
        runningBalance += tx.amount;
        isPositive = true;
        totalLent += tx.amount;
      } else if (tx.type == TransactionType.received ||
          tx.type == TransactionType.borrowed) {
        runningBalance -= tx.amount;
        isPositive = false;
        totalReceived += tx.amount;
      } else if (tx.type == TransactionType.adjustment) {
        runningBalance += tx.amount;
        isPositive = tx.amount >= 0;
        if (isPositive) {
          totalLent += tx.amount;
        } else {
          totalReceived += tx.amount.abs();
        }
      }

      final txDate = tx.transactionDate ?? tx.createdAt;
      final dateStr = '${txDate.day}/${txDate.month}/${txDate.year}';
      final dueStr = tx.dueDate != null
          ? '${tx.dueDate!.day}/${tx.dueDate!.month}/${tx.dueDate!.year}'
          : '-';
      final typeStr = tx.type.name.toUpperCase();
      final notesStr = tx.notes ?? '-';
      final amountStr =
          '${isPositive ? "+" : "-"} PKR ${tx.amount.toStringAsFixed(0)}';
      final balanceStr = 'PKR ${runningBalance.toStringAsFixed(0)}';

      final amountColor = isPositive
          ? const PdfColor.fromInt(0xFF16A34A)
          : const PdfColor.fromInt(0xFFDC2626);
      final isEven = rowIndex % 2 == 0;

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven
                ? const PdfColor.fromInt(0xFFF8FAFC)
                : PdfColors.white,
            border: const pw.Border(
              bottom: pw.BorderSide(
                color: PdfColor.fromInt(0xFFE2E8F0),
                width: 0.5,
              ),
            ),
          ),
          children: [
            _buildTableCell(dateStr),
            _buildTableCell(dueStr),
            _buildTableCell(typeStr, isBold: true),
            _buildTableCell(notesStr),
            _buildTableCell(
              amountStr,
              color: amountColor,
              isBold: true,
              alignRight: true,
            ),
            _buildTableCell(balanceStr, isBold: true, alignRight: true),
          ],
        ),
      );
      rowIndex++;
    }

    closingBalance = runningBalance;
    final now = DateTime.now();
    final formattedTime =
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE2E8F0),
                  width: 0.5,
                ),
              ),
            ),
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by KhataFlow • Secure Local Ledger',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFF94A3B8),
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Top Accent Bar
            pw.Container(
              height: 5,
              color: const PdfColor.fromInt(0xFF0F766E),
              margin: const pw.EdgeInsets.only(bottom: 20),
            ),

            // Header Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('💸 ', style: pw.TextStyle(fontSize: 20)),
                        pw.Text(
                          'KhataFlow Statement',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'SECURE LOCAL LEDGER REPORT',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generation Time: $formattedTime',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromInt(0xFF334155),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'System Generated (Offline-First)',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColor.fromInt(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: const PdfColor.fromInt(0xFFE2E8F0), height: 1),
            pw.SizedBox(height: 20),

            // Customer & Account Details
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PREPARED FOR',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF64748B),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        person.name,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF1E293B),
                        ),
                      ),
                      if (person.phone != null && person.phone!.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          PhoneFormatter.format(person.phone),
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColor.fromInt(0xFF475569),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'LEDGER ACCOUNT',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF64748B),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        khata.title,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Balances Summary Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard(
                  'Total Tx Count',
                  '$totalCount',
                  leftAccentColor: const PdfColor.fromInt(0xFF94A3B8),
                ),
                _buildSummaryCard(
                  'Closing Balance',
                  'PKR ${closingBalance.abs().toStringAsFixed(0)}',
                  color: closingBalance >= 0
                      ? const PdfColor.fromInt(0xFF16A34A)
                      : const PdfColor.fromInt(0xFFDC2626),
                  leftAccentColor: closingBalance >= 0
                      ? const PdfColor.fromInt(0xFF16A34A)
                      : const PdfColor.fromInt(0xFFDC2626),
                ),
                _buildSummaryCard(
                  'Outstanding Position',
                  closingBalance >= 0 ? 'RECEIVABLE' : 'PAYABLE',
                  color: closingBalance >= 0
                      ? const PdfColor.fromInt(0xFF16A34A)
                      : const PdfColor.fromInt(0xFFDC2626),
                  leftAccentColor: closingBalance >= 0
                      ? const PdfColor.fromInt(0xFF16A34A)
                      : const PdfColor.fromInt(0xFFDC2626),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard(
                  'Total Lent (Gave)',
                  'PKR ${totalLent.toStringAsFixed(0)}',
                  leftAccentColor: const PdfColor.fromInt(0xFF16A34A),
                ),
                _buildSummaryCard(
                  'Total Collected',
                  'PKR ${totalReceived.toStringAsFixed(0)}',
                  leftAccentColor: const PdfColor.fromInt(0xFFDC2626),
                ),
                pw.Container(width: 160), // filler to match layout grid
              ],
            ),
            pw.SizedBox(height: 28),

            // Ledger Title
            pw.Row(
              children: [
                pw.Container(
                  width: 4,
                  height: 14,
                  color: const PdfColor.fromInt(0xFF0F766E),
                  margin: const pw.EdgeInsets.only(right: 8),
                ),
                pw.Text(
                  'Ledger Transactions',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Transaction Table
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(2.0), // Given Date
                1: pw.FlexColumnWidth(2.0), // Due Date
                2: pw.FlexColumnWidth(2.0), // Type
                3: pw.FlexColumnWidth(3.2), // Notes
                4: pw.FlexColumnWidth(2.4), // Amount
                5: pw.FlexColumnWidth(2.4), // Balance
              },
              children: rows,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          fontSize: 9.5,
        ),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    PdfColor color = const PdfColor.fromInt(0xFF1E293B),
    bool isBold = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildSummaryCard(
    String label,
    String value, {
    PdfColor? color,
    required PdfColor leftAccentColor,
  }) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC), // Slate 50 background
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFE2E8F0),
          width: 1,
        ), // Light border
      ),
      child: pw.Stack(
        alignment: pw.Alignment.centerLeft,
        children: [
          // Left accent colored bar
          pw.Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: pw.Container(width: 3, color: leftAccentColor),
          ),
          // Content with left offset
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFF64748B),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: color ?? const PdfColor.fromInt(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> shareStatementPdf({
    required Uint8List pdfBytes,
    required String filename,
    required String subject,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/$filename').create();
    await file.writeAsBytes(pdfBytes);

    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: subject);
  }
}
