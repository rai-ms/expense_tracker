part of 'documents_bloc.dart';

/// State data for the Documents screen
class DocumentsData {
  final List<DocumentEntity> allDocuments;
  final List<DocumentEntity> filteredDocuments;
  final String activeFilter; // 'All', 'Salary', 'Insurance', 'Tax', 'Medical', 'Legal', 'Other'

  const DocumentsData({
    required this.allDocuments,
    required this.filteredDocuments,
    required this.activeFilter,
  });

  DocumentsData copyWith({
    List<DocumentEntity>? allDocuments,
    List<DocumentEntity>? filteredDocuments,
    String? activeFilter,
  }) {
    return DocumentsData(
      allDocuments: allDocuments ?? this.allDocuments,
      filteredDocuments: filteredDocuments ?? this.filteredDocuments,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

