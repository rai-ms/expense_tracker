import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../base/logger/app_logger.dart';

/// Service for capturing, compressing, storing, and managing bill & receipt attachments locally
@lazySingleton
class ReceiptService {
  final ImagePicker _picker = ImagePicker();

  ReceiptService();

  /// Captures or selects an image, compresses it to 85% JPEG, and stores it in app documents/receipts/
  Future<String?> pickAndSaveReceipt({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${const Uuid().v4()}.jpg';
      final savedFile = File('${receiptsDir.path}/$fileName');

      await File(pickedFile.path).copy(savedFile.path);

      Log.i('Receipt saved successfully at: ${savedFile.path}');
      return savedFile.path;
    } catch (e, stack) {
      Log.e('Failed to capture and save receipt', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Delete an attached receipt file from local disk safely
  Future<bool> deleteReceipt(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) return false;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        Log.i('Receipt deleted: $filePath');
        return true;
      }
      return false;
    } catch (e, stack) {
      Log.e('Error deleting receipt file: $filePath', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Share the receipt image via system share sheet
  Future<void> shareReceipt(String filePath, {String? caption}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        Log.w('Cannot share non-existent receipt file: $filePath');
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: caption ?? 'Receipt attachment from SpendWise',
        ),
      );
    } catch (e, stack) {
      Log.e('Error sharing receipt file', error: e, stackTrace: stack);
    }
  }
}
