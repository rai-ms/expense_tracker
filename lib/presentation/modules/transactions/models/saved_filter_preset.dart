import 'transaction_filter_criteria.dart';

class SavedFilterPreset {
  final String id;
  final String name;
  final TransactionFilterCriteria criteria;
  final DateTime createdAt;

  const SavedFilterPreset({
    required this.id,
    required this.name,
    required this.criteria,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'criteria': criteria.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedFilterPreset.fromJson(Map<String, dynamic> map) {
    return SavedFilterPreset(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? 'Untitled Filter',
      criteria: map['criteria'] != null
          ? TransactionFilterCriteria.fromJson(map['criteria'] as Map<String, dynamic>)
          : const TransactionFilterCriteria(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
