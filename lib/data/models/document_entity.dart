import 'package:objectbox/objectbox.dart';

@Entity()
class DocumentEntity {
  @Id()
  int id = 0;

  @Index()
  String uid; // UUID

  String name; // Display name e.g. "June 2025 Salary Slip"

  @Index()
  String category; // 'Salary', 'Insurance', 'Tax', 'Medical', 'Legal', 'Other'

  String filePath; // Absolute local path of saved file (copied into app storage)

  String fileType; // 'pdf', 'jpg', 'png', 'jpeg'

  @Index()
  int addedAt; // Epoch ms

  String? notes; // Optional description

  DocumentEntity({
    this.id = 0,
    required this.uid,
    required this.name,
    required this.category,
    required this.filePath,
    required this.fileType,
    required this.addedAt,
    this.notes,
  });

  DateTime get addedAtDateTime => DateTime.fromMillisecondsSinceEpoch(addedAt);

  bool get isPdf => fileType.toLowerCase() == 'pdf';

  bool get isImage =>
      fileType.toLowerCase() == 'jpg' ||
      fileType.toLowerCase() == 'jpeg' ||
      fileType.toLowerCase() == 'png';
}
