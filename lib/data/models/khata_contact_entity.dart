import 'package:objectbox/objectbox.dart';
import 'khata_entry_entity.dart';

@Entity()
class KhataContactEntity {
  @Id()
  int id = 0;

  @Index()
  String uid;

  String name;

  String? phoneNumber;

  int createdAt; // Timestamp ms

  int avatarColorValue; // Color int value

  @Backlink('contact')
  final entries = ToMany<KhataEntryEntity>();

  KhataContactEntity({
    this.id = 0,
    required this.uid,
    required this.name,
    this.phoneNumber,
    required this.createdAt,
    this.avatarColorValue = 0xFF6366F1,
  });

  /// Calculate net balance:
  /// You gave (Gave) = positive for you (they owe you)
  /// You got (Got) = negative for you (you owe them)
  double get netBalance {
    double total = 0.0;
    for (final entry in entries) {
      if (entry.isSettled) continue;
      if (entry.isGave) {
        total += entry.amount;
      } else if (entry.isGot) {
        total -= entry.amount;
      }
    }
    return total;
  }
}
