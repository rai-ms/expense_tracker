import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/services/di/injection.dart';
import '../../../../core/services/pdf_export_service/pdf_export_service.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../ui/export_pdf_view.dart';

class ExportPdfController extends StatefulWidget {
  const ExportPdfController({super.key});

  @override
  State<ExportPdfController> createState() => ExportPdfControllerState();
}

class ExportPdfControllerState extends State<ExportPdfController>
    with _ExportPdfMixin {
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  bool isGenerating = false;
  pw.Document? generatedPdf;

  @override
  void initState() {
    super.initState();
    _generateStatement();
  }

  void _generateStatement() async {
    setState(() => isGenerating = true);
    final repo = sl<ITransactionRepository>();
    final txns = repo.getTransactionsByDateRange(startDate, endDate);
    final income = repo.getTotalIncome(start: startDate, end: endDate);
    final expense = repo.getTotalExpense(start: startDate, end: endDate);
    final breakdown = repo.getCategoryBreakdown(start: startDate, end: endDate);

    final doc = await PdfExportService.generateExpenseStatement(
      transactions: txns,
      totalIncome: income,
      totalExpense: expense,
      categoryBreakdown: breakdown,
      startDate: startDate,
      endDate: endDate,
    );

    if (mounted) {
      setState(() {
        generatedPdf = doc;
        isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExportPdfView(this);
  }
}

mixin _ExportPdfMixin on State<ExportPdfController> {
  ExportPdfControllerState get _state => this as ExportPdfControllerState;

  void onDateRangePicked(DateTime start, DateTime end) {
    _state.startDate = start;
    _state.endDate = end;
    _state._generateStatement();
  }

  void onSharePdf() {
    if (_state.generatedPdf != null) {
      PdfExportService.printOrSharePdf(
        _state.generatedPdf!,
        'SpendWise_Statement_${_state.startDate.month}_${_state.startDate.year}',
      );
    }
  }
}
