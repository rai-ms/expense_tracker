import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/di/injection.dart';
import '../../../core/services/receipt_service/receipt_service.dart';

/// Full-screen zoomable lightbox for inspecting, zooming, and sharing bill receipts
class ReceiptLightboxModal extends StatelessWidget {
  final String receiptPath;
  final String? title;
  final VoidCallback? onDelete;

  const ReceiptLightboxModal({
    super.key,
    required this.receiptPath,
    this.title,
    this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required String receiptPath,
    String? title,
    VoidCallback? onDelete,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ReceiptLightboxModal(
          receiptPath: receiptPath,
          title: title,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(receiptPath);
    final exists = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title ?? 'Receipt Photo',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (exists)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: 'Share Receipt',
              onPressed: () {
                sl<ReceiptService>().shareReceipt(receiptPath, caption: title);
              },
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.debitRed),
              tooltip: 'Delete Receipt',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.darkSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Remove Receipt?', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'Are you sure you want to remove this receipt photo from this transaction?',
                      style: TextStyle(color: AppColors.textSecondaryDark),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx); // close dialog
                          Navigator.pop(context); // close lightbox
                          onDelete?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.debitRed,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: exists
              ? InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
                          SizedBox(height: 12),
                          Text('Could not load image', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_not_supported_rounded, color: Colors.white38, size: 64),
                      SizedBox(height: 12),
                      Text('Receipt file not found', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
