import '../../data/models/document_entity.dart';

abstract class IDocumentRepository {
  List<DocumentEntity> getAllDocuments();
  List<DocumentEntity> getByCategory(String category);
  int addDocument(DocumentEntity document);
  bool updateDocument(DocumentEntity document);
  bool deleteDocument(int id);

  const IDocumentRepository();
}
