import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/data/models/document_entity.dart';
import 'package:expense_tracker/presentation/modules/documents/bloc/document_category.dart';

void main() {
  group('Document Management & Entity Tests', () {
    test('DocumentEntity initializes properly with all fields', () {
      final now = DateTime.now();
      final doc = DocumentEntity(
        id: 1,
        uid: 'doc-uuid-1234',
        name: 'August 2026 Salary Slip',
        category: 'Salary',
        filePath: '/data/user/0/documents/salary_aug.pdf',
        fileType: 'pdf',
        addedAt: now.millisecondsSinceEpoch,
        notes: 'Monthly payslip from HR',
      );

      expect(doc.id, 1);
      expect(doc.uid, 'doc-uuid-1234');
      expect(doc.name, 'August 2026 Salary Slip');
      expect(doc.category, 'Salary');
      expect(doc.filePath, '/data/user/0/documents/salary_aug.pdf');
      expect(doc.fileType, 'pdf');
      expect(doc.addedAt, now.millisecondsSinceEpoch);
      expect(doc.addedAtDateTime.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(doc.notes, 'Monthly payslip from HR');
      expect(doc.isPdf, isTrue);
      expect(doc.isImage, isFalse);
    });

    test('DocumentEntity file extension detection works for images', () {
      final docJpg = DocumentEntity(
        uid: 'doc-jpg-1',
        name: 'Health Insurance Card',
        category: 'Insurance',
        filePath: '/docs/card.jpg',
        fileType: 'jpg',
        addedAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(docJpg.isPdf, isFalse);
      expect(docJpg.isImage, isTrue);

      final docPng = DocumentEntity(
        uid: 'doc-png-1',
        name: 'Hospital Bill',
        category: 'Medical',
        filePath: '/docs/bill.png',
        fileType: 'png',
        addedAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(docPng.isPdf, isFalse);
      expect(docPng.isImage, isTrue);
    });

    test('DocumentCategory defines all essential document categories', () {
      expect(DocumentCategory.all, containsAll([
        'All',
        'Salary',
        'Insurance',
        'Tax',
        'Medical',
        'Legal',
        'Other',
      ]));

      // Verify category metadata exists
      for (final cat in DocumentCategory.all) {
        if (cat == 'All') continue;
        final meta = DocumentCategory.get(cat);
        expect(meta['icon'], isA<IconData>());
        expect(meta['color'], isA<Color>());
      }
    });

    test('DocumentCategory fallback metadata works for unknown category', () {
      final meta = DocumentCategory.get('UnknownCustomCategory');
      expect(meta['icon'], Icons.folder_rounded);
      expect(meta['color'], const Color(0xFF64748B));
    });
  });
}
