import 'dart:io';
import 'package:flutter/material.dart' as flutter;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/khata_contact_entity.dart';
import '../../../data/models/transaction_entity.dart';
import '../../base/logger/app_logger.dart';

/// PDF export service for generating beautiful statements and Khata reports
class PdfExportService {
  /// Generate a PDF expense statement for a given date range and filter criteria
  static Future<pw.Document> generateExpenseStatement({
    required List<TransactionEntity> transactions,
    required double totalIncome,
    required double totalExpense,
    Map<String, double>? categoryBreakdown,
    DateTime? startDate,
    DateTime? endDate,
    String? periodLabel,
    String? filterSubtitle,
    String? userName,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final periodFormat = DateFormat('dd MMM yyyy');

    // Compute category breakdown if not provided
    final breakdown = categoryBreakdown ?? _computeCategoryBreakdown(transactions);

    final resolvedPeriod = periodLabel ??
        ((startDate != null && endDate != null)
            ? '${periodFormat.format(startDate)} - ${periodFormat.format(endDate)}'
            : 'All Time');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SpendWise Financial Statement',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Period: $resolvedPeriod',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    if (filterSubtitle != null && filterSubtitle.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Filters: $filterSubtitle',
                        style: pw.TextStyle(fontSize: 8.5, color: PdfColors.indigo700, fontStyle: pw.FontStyle.italic),
                      ),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated on:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text(
                      periodFormat.format(DateTime.now()),
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('SpendWise Smart Expense & Khata Tracker', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // KPI Summary Cards
          pw.Row(
            children: [
              _buildSummaryCard('Total Inflow', currencyFormat.format(totalIncome), PdfColors.green700, PdfColors.green50),
              pw.SizedBox(width: 12),
              _buildSummaryCard('Total Outflow', currencyFormat.format(totalExpense), PdfColors.red700, PdfColors.red50),
              pw.SizedBox(width: 12),
              _buildSummaryCard('Net Balance', currencyFormat.format(totalIncome - totalExpense), PdfColors.indigo700, PdfColors.indigo50),
            ],
          ),
          pw.SizedBox(height: 20),

          // Category Breakdown
          if (breakdown.isNotEmpty) ...[
            pw.Text('Spending by Category', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Category', 'Amount', '% of Total Outflow'],
              data: breakdown.entries.map((e) {
                final pct = totalExpense > 0 ? ((e.value / totalExpense) * 100).toStringAsFixed(1) : '0';
                return [e.key, currencyFormat.format(e.value), '$pct%'];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
            ),
            pw.SizedBox(height: 20),
          ],

          // Transaction Ledger Table
          pw.Text('Transaction History (${transactions.length} items)', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          pw.SizedBox(height: 8),
          if (transactions.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Center(child: pw.Text('No transactions match the selected criteria.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Merchant / Payee', 'Category', 'Bank / Platform', 'Type', 'Amount'],
              data: transactions.map((t) {
                final dateStr = dateFormat.format(t.dateTime);
                final desc = t.merchant ?? (t.isDebit ? 'Expense' : 'Income');
                final ref = t.platform ?? t.transactionId ?? '-';
                final isDebit = t.isDebit;
                final amt = (isDebit ? '- ' : '+ ') + currencyFormat.format(t.amount);
                return [dateStr, desc, t.category, ref, isDebit ? 'Debit' : 'Credit', amt];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            ),
        ],
      ),
    );

    return pdf;
  }

  static Map<String, double> _computeCategoryBreakdown(List<TransactionEntity> transactions) {
    final Map<String, double> map = {};
    for (final t in transactions) {
      if (!t.isIgnored && t.isDebit) {
        map[t.category] = (map[t.category] ?? 0.0) + t.amount;
      }
    }
    return map;
  }

  /// Generate a Khata contact statement
  static Future<pw.Document> generateKhataStatement({
    required KhataContactEntity contact,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');
    final dateFormat = DateFormat('dd MMM yyyy');

    final entries = contact.entries.toList()..sort((a, b) => b.date.compareTo(a.date));
    double totalGave = 0;
    double totalGot = 0;
    for (final e in entries) {
      if (e.isGave) totalGave += e.amount;
      if (e.isGot) totalGot += e.amount;
    }
    final net = totalGave - totalGot;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('KhataBook Ledger Statement', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
                  pw.SizedBox(height: 3),
                  pw.Text('Customer: ${contact.name} (${contact.phoneNumber ?? "No Phone"})', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.Text(dateFormat.format(DateTime.now()), style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (pw.Context context) => [
          // Balance Summary
          pw.Row(
            children: [
              _buildSummaryCard('Total Given (Maine Diye)', currencyFormat.format(totalGave), PdfColors.red700, PdfColors.red50),
              pw.SizedBox(width: 12),
              _buildSummaryCard('Total Received (Mujhe Mile)', currencyFormat.format(totalGot), PdfColors.green700, PdfColors.green50),
              pw.SizedBox(width: 12),
              _buildSummaryCard(
                net >= 0 ? 'Net to Receive' : 'Net to Pay',
                currencyFormat.format(net.abs()),
                net >= 0 ? PdfColors.green700 : PdfColors.red700,
                net >= 0 ? PdfColors.green50 : PdfColors.red50,
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Ledger Table
          pw.Text('Ledger Entries', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Type', 'Txn ID / Ref', 'Notes / Due Date', 'Status', 'You Gave', 'You Got'],
            data: entries.map((e) {
              final dateStr = dateFormat.format(e.dateTime);
              final typeStr = e.isGave ? 'Gave (Maine Diye)' : 'Got (Mujhe Mile)';
              final refParts = [
                if (e.platform != null && e.platform!.isNotEmpty) e.platform!,
                if (e.transactionId != null && e.transactionId!.isNotEmpty) e.transactionId!,
              ];
              final refStr = refParts.isEmpty ? '-' : refParts.join(' • ');
              final notesStr = e.notes ?? '-';
              final status = e.isSettled ? 'Settled' : 'Pending';
              final gaveAmt = e.isGave ? currencyFormat.format(e.amount) : '-';
              final gotAmt = e.isGot ? currencyFormat.format(e.amount) : '-';
              return [dateStr, typeStr, refStr, notesStr, status, gaveAmt, gotAmt];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSummaryCard(String title, String value, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: textColor.shade(0.3), width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  /// Show interactive PDF preview modal with print, save, and share actions
  static void showPdfPreviewModal({
    required flutter.BuildContext context,
    required pw.Document document,
    required String title,
    required String fileName,
  }) {
    flutter.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: flutter.Colors.transparent,
      builder: (ctx) {
        return flutter.Container(
          height: flutter.MediaQuery.of(context).size.height * 0.88,
          decoration: const flutter.BoxDecoration(
            color: flutter.Colors.white,
            borderRadius: flutter.BorderRadius.vertical(top: flutter.Radius.circular(24)),
          ),
          child: flutter.Column(
            children: [
              flutter.Container(
                margin: const flutter.EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4,
                decoration: flutter.BoxDecoration(
                  color: flutter.Colors.grey.shade300,
                  borderRadius: flutter.BorderRadius.circular(2),
                ),
              ),
              flutter.Expanded(
                child: PdfPreview(
                  build: (format) => document.save(),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  pdfFileName: '$fileName.pdf',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Print or share statement PDF
  static Future<void> printOrSharePdf(pw.Document document, String fileName) async {
    try {
      final bytes = await document.save();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '$fileName from SpendWise',
        ),
      );
    } catch (e, stack) {
      Log.e('Error sharing PDF', error: e, stackTrace: stack);
    }
  }
}
