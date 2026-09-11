import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/di/injection.dart';
import '../../../../data/models/document_entity.dart';
import '../../../../domain/repositories/i_document_repository.dart';
import '../bloc/documents_bloc.dart';
import '../ui/documents_view.dart';
import '../ui/widgets/add_document_modal.dart';

class DocumentsController extends StatefulWidget {
  const DocumentsController({super.key});

  @override
  State<DocumentsController> createState() => DocumentsControllerState();
}

class DocumentsControllerState extends State<DocumentsController>
    with _DocumentsMixin {
  late final DocumentsBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = DocumentsBloc(sl<IDocumentRepository>());
    bloc.add(LoadDocumentsEvent());
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DocumentsView(this);
  }
}

mixin _DocumentsMixin on State<DocumentsController> {
  DocumentsControllerState get _state => this as DocumentsControllerState;

  void onAddDocument() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddDocumentModal(
        onSave:
            ({
              required String name,
              required String category,
              required String sourcePath,
              String? notes,
            }) {
              const uuid = Uuid();
              _state.bloc.add(
                AddDocumentEvent(
                  uid: uuid.v4(),
                  name: name,
                  category: category,
                  sourcePath: sourcePath,
                  notes: notes,
                ),
              );
            },
      ),
    );
  }

  Future<void> onPickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result.isNotEmpty && result.single.path != null) {
      final path = result.single.path!;
      final name = result.single.name.replaceAll(
        RegExp(r'\.[^.]+$'),
        '',
      ); // strip extension
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (_) => AddDocumentModal(
            initialName: name,
            initialPath: path,
            onSave:
                ({
                  required String name,
                  required String category,
                  required String sourcePath,
                  String? notes,
                }) {
                  const uuid = Uuid();
                  _state.bloc.add(
                    AddDocumentEvent(
                      uid: uuid.v4(),
                      name: name,
                      category: category,
                      sourcePath: sourcePath,
                      notes: notes,
                    ),
                  );
                },
          ),
        );
      }
    }
  }

  Future<void> onOpenDocument(String filePath) async {
    await OpenFile.open(filePath);
  }

  Future<void> onShareDocument(String filePath, String name) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath)], subject: name),
    );
  }

  void onDeleteDocument(int documentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
          'Are you sure you want to permanently delete this document?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _state.bloc.add(DeleteDocumentEvent(documentId));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void onEditDocument(DocumentEntity document) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddDocumentModal(
        existingDocument: document,
        onUpdate:
            ({
              required int id,
              required String name,
              required String category,
              String? notes,
            }) {
              _state.bloc.add(
                UpdateDocumentEvent(
                  documentId: id,
                  name: name,
                  category: category,
                  notes: notes,
                ),
              );
            },
      ),
    );
  }

  void onFilterChanged(String category) {
    _state.bloc.add(FilterDocumentsEvent(category));
  }
}
