import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../controller/export_pdf_controller.dart';

class ExportPdfView
    extends WidgetView<ExportPdfView, ExportPdfControllerState> {
  const ExportPdfView(super.ctr, {super.key});

  @override
  Widget build(BuildContext context) {
    final periodFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Export PDF Statement',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: ctr.onSharePdf,
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          // Period Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: const Border(bottom: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Statement Range', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                    const SizedBox(height: 2),
                    Text(
                      '${periodFormat.format(ctr.startDate)} - ${periodFormat.format(ctr.endDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      initialDateRange: DateTimeRange(start: ctr.startDate, end: ctr.endDate),
                    );
                    if (picked != null) {
                      ctr.onDateRangePicked(picked.start, picked.end);
                    }
                  },
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),

          // PDF Interactive Viewer
          Expanded(
            child: ctr.isGenerating
                ? const Center(child: CircularProgressIndicator())
                : ctr.generatedPdf == null
                    ? const Center(child: Text('Failed to generate PDF'))
                    : PdfPreview(
                        build: (format) => ctr.generatedPdf!.save(),
                        allowPrinting: true,
                        allowSharing: true,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                      ),
          ),
        ],
      ),
    ),
  );
}
}
