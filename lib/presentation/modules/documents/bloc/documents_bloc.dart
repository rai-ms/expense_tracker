import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/base/bloc_base/base_bloc.dart';
import '../../../../core/base/bloc_base/bloc_event.dart';
import '../../../../data/models/document_entity.dart';
import '../../../../domain/repositories/i_document_repository.dart';

part 'documents_event.dart';
part 'documents_state.dart';

@injectable
class DocumentsBloc extends BaseBloc<DocumentsEvent, DocumentsData> {
  final IDocumentRepository _documentRepository;

  DocumentsBloc(this._documentRepository) {
    on<LoadDocumentsEvent>(_onLoad);
    on<AddDocumentEvent>(_onAdd);
    on<UpdateDocumentEvent>(_onUpdate);
    on<DeleteDocumentEvent>(_onDelete);
    on<FilterDocumentsEvent>(_onFilter);
  }

  void _onLoad(LoadDocumentsEvent event, dynamic emit) {
    emitLoading();
    try {
      final all = _documentRepository.getAllDocuments();
      final activeFilter = state.data?.activeFilter ?? 'All';
      final filtered = _applyFilter(all, activeFilter);
      emitSuccess(
        data: DocumentsData(
          allDocuments: all,
          filteredDocuments: filtered,
          activeFilter: activeFilter,
        ),
      );
    } catch (e) {
      emitFailed(message: 'Failed to load documents: $e');
    }
  }

  Future<void> _onAdd(AddDocumentEvent event, dynamic emit) async {
    try {
      // Copy the picked file into app documents dir for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory(p.join(appDir.path, 'pdf_vault'));
      if (!vaultDir.existsSync()) {
        vaultDir.createSync(recursive: true);
      }

      final originalFile = File(event.sourcePath);
      final ext = p.extension(event.sourcePath).replaceFirst('.', '');
      final destFileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(event.sourcePath)}';
      final destPath = p.join(vaultDir.path, destFileName);

      await originalFile.copy(destPath);

      final doc = DocumentEntity(
        uid: event.uid,
        name: event.name,
        category: event.category,
        filePath: destPath,
        fileType: ext.toLowerCase(),
        addedAt: DateTime.now().millisecondsSinceEpoch,
        notes: event.notes,
      );

      _documentRepository.addDocument(doc);
      add(LoadDocumentsEvent());
    } catch (e) {
      emitFailed(message: 'Failed to add document: $e');
    }
  }

  void _onUpdate(UpdateDocumentEvent event, dynamic emit) {
    try {
      final all = _documentRepository.getAllDocuments();
      final doc = all.firstWhere((d) => d.id == event.documentId,
          orElse: () => throw Exception('Document not found'));
      doc.name = event.name;
      doc.category = event.category;
      doc.notes = event.notes;
      _documentRepository.updateDocument(doc);
      add(LoadDocumentsEvent());
    } catch (e) {
      emitFailed(message: 'Failed to update document: $e');
    }
  }

  Future<void> _onDelete(DeleteDocumentEvent event, dynamic emit) async {
    try {
      // Also remove the physical file from app storage
      final doc = state.data?.allDocuments
          .firstWhere((d) => d.id == event.documentId, orElse: () => throw Exception('Not found'));
      if (doc != null) {
        final file = File(doc.filePath);
        if (file.existsSync()) {
          await file.delete();
        }
      }
      _documentRepository.deleteDocument(event.documentId);
      add(LoadDocumentsEvent());
    } catch (e) {
      emitFailed(message: 'Failed to delete document: $e');
    }
  }

  void _onFilter(FilterDocumentsEvent event, dynamic emit) {
    final data = state.data;
    if (data == null) return;
    final filtered = _applyFilter(data.allDocuments, event.category);
    emitSuccess(
      data: data.copyWith(
        filteredDocuments: filtered,
        activeFilter: event.category,
      ),
    );
  }

  List<DocumentEntity> _applyFilter(
      List<DocumentEntity> all, String category) {
    if (category == 'All') return all;
    return all.where((d) => d.category == category).toList();
  }
}
