part of 'documents_bloc.dart';

/// Base class for Documents events
abstract class DocumentsEvent extends BlocEvent {
  const DocumentsEvent();
}

/// Load all documents
class LoadDocumentsEvent extends DocumentsEvent {}

/// Add a new document from a picked file
class AddDocumentEvent extends DocumentsEvent {
  final String uid;
  final String name;
  final String category;
  final String sourcePath; // Original picked file path
  final String? notes;

  const AddDocumentEvent({
    required this.uid,
    required this.name,
    required this.category,
    required this.sourcePath,
    this.notes,
  });

  @override
  List<Object?> get props => [uid, name, category, sourcePath, notes];
}

/// Delete a document by id
class DeleteDocumentEvent extends DocumentsEvent {
  final int documentId;
  const DeleteDocumentEvent(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

/// Update an existing document's metadata (name, category, notes)
class UpdateDocumentEvent extends DocumentsEvent {
  final int documentId;
  final String name;
  final String category;
  final String? notes;

  const UpdateDocumentEvent({
    required this.documentId,
    required this.name,
    required this.category,
    this.notes,
  });

  @override
  List<Object?> get props => [documentId, name, category, notes];
}

/// Filter documents by category
class FilterDocumentsEvent extends DocumentsEvent {
  final String category;
  const FilterDocumentsEvent(this.category);

  @override
  List<Object?> get props => [category];
}
