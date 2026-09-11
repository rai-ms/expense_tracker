import 'package:injectable/injectable.dart' hide Order;

import '../../core/services/objectbox_service/objectbox_service.dart';
import '../../domain/repositories/i_document_repository.dart';
import '../../objectbox.g.dart';
import '../models/document_entity.dart';

@LazySingleton(as: IDocumentRepository)
class DocumentRepositoryImpl implements IDocumentRepository {
  final ObjectBoxService _boxService;

  const DocumentRepositoryImpl(this._boxService);

  @override
  List<DocumentEntity> getAllDocuments() {
    final query = _boxService.documentBox.query()
      ..order(DocumentEntity_.addedAt, flags: Order.descending);
    final q = query.build();
    final results = q.find();
    q.close();
    return results;
  }

  @override
  List<DocumentEntity> getByCategory(String category) {
    final query = _boxService.documentBox
        .query(DocumentEntity_.category.equals(category))
      ..order(DocumentEntity_.addedAt, flags: Order.descending);
    final q = query.build();
    final results = q.find();
    q.close();
    return results;
  }

  @override
  int addDocument(DocumentEntity document) {
    return _boxService.documentBox.put(document);
  }

  @override
  bool updateDocument(DocumentEntity document) {
    _boxService.documentBox.put(document);
    return true;
  }

  @override
  bool deleteDocument(int id) {
    return _boxService.documentBox.remove(id);
  }
}
