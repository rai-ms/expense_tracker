import 'dart:io';

import 'package:expense_tracker/core/services/receipt_service/receipt_service.dart';
import 'package:expense_tracker/data/models/khata_entry_entity.dart';
import 'package:expense_tracker/data/models/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptService Tests', () {
    late ReceiptService receiptService;
    late Directory tempDir;

    setUp(() async {
      receiptService = ReceiptService();
      tempDir = await Directory.systemTemp.createTemp('receipt_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('deleteReceipt returns false for null or empty path', () async {
      expect(await receiptService.deleteReceipt(null), isFalse);
      expect(await receiptService.deleteReceipt(''), isFalse);
      expect(await receiptService.deleteReceipt('   '), isFalse);
    });

    test('deleteReceipt returns false for non-existent file', () async {
      final fakePath = '${tempDir.path}/non_existent_receipt.jpg';
      expect(await receiptService.deleteReceipt(fakePath), isFalse);
    });

    test('deleteReceipt deletes an existing file and returns true', () async {
      final sampleFile = File('${tempDir.path}/sample_receipt.jpg');
      await sampleFile.writeAsString('sample receipt image bytes');
      expect(await sampleFile.exists(), isTrue);

      final result = await receiptService.deleteReceipt(sampleFile.path);
      expect(result, isTrue);
      expect(await sampleFile.exists(), isFalse);
    });
  });

  group('Entity Receipt Metadata Tests', () {
    test('TransactionEntity hasReceipt getter works correctly', () {
      final txnWithReceipt = TransactionEntity(
        uid: 'txn-1',
        amount: 450.0,
        type: 'debit',
        category: 'Food & Dining',
        date: DateTime.now().millisecondsSinceEpoch,
        receiptPath: '/data/user/0/com.spendwise/app_flutter/receipts/test.jpg',
      );
      expect(txnWithReceipt.hasReceipt, isTrue);
      expect(txnWithReceipt.receiptPath, isNotNull);

      final txnWithoutReceipt = TransactionEntity(
        uid: 'txn-2',
        amount: 250.0,
        type: 'debit',
        category: 'Shopping',
        date: DateTime.now().millisecondsSinceEpoch,
      );
      expect(txnWithoutReceipt.hasReceipt, isFalse);
      expect(txnWithoutReceipt.receiptPath, isNull);

      final txnWithEmptyPath = TransactionEntity(
        uid: 'txn-3',
        amount: 150.0,
        type: 'debit',
        category: 'Travel',
        date: DateTime.now().millisecondsSinceEpoch,
        receiptPath: '',
      );
      expect(txnWithEmptyPath.hasReceipt, isFalse);
    });

    test('KhataEntryEntity hasReceipt getter works correctly', () {
      final entryWithReceipt = KhataEntryEntity(
        uid: 'uid-123',
        amount: 500.0,
        type: 'gave',
        date: DateTime.now().millisecondsSinceEpoch,
        receiptPath: '/data/user/0/com.spendwise/app_flutter/receipts/bill.jpg',
      );
      expect(entryWithReceipt.hasReceipt, isTrue);

      final entryWithoutReceipt = KhataEntryEntity(
        uid: 'uid-456',
        amount: 1000.0,
        type: 'got',
        date: DateTime.now().millisecondsSinceEpoch,
      );
      expect(entryWithoutReceipt.hasReceipt, isFalse);
    });
  });
}
