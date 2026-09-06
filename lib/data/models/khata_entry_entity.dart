import 'package:objectbox/objectbox.dart';
import 'khata_contact_entity.dart';

@Entity()
class KhataEntryEntity {
  @Id()
  int id = 0;

  @Index()
  String uid;

  double amount;

  @Index()
  String type; // 'gave' (You gave / Maine diye) or 'got' (You got / Mujhe mile)

  @Index()
  int date; // Epoch ms

  int? dueDate; // Epoch ms (optional reminder date)

  @Index()
  String? transactionId; // Original Bank Transaction ID / UPI Ref / UTR

  String? platform; // Platform / Bank / App (e.g. GPay, PhonePe, Paytm, HDFC)

  String? notes;

  bool isSettled;

  final contact = ToOne<KhataContactEntity>();

  KhataEntryEntity({
    this.id = 0,
    required this.uid,
    required this.amount,
    required this.type,
    required this.date,
    this.dueDate,
    this.transactionId,
    this.platform,
    this.notes,
    this.isSettled = false,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date);
  DateTime? get dueDateTime =>
      dueDate != null ? DateTime.fromMillisecondsSinceEpoch(dueDate!) : null;

  bool get isGave => type.toLowerCase() == 'gave';
  bool get isGot => type.toLowerCase() == 'got';
}
