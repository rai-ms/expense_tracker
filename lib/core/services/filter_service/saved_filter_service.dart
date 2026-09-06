import 'dart:convert';

import '../../../presentation/modules/transactions/models/saved_filter_preset.dart';
import '../objectbox_service/objectbox_service.dart';

class SavedFilterService {
  SavedFilterService._();

  static const String _savedFiltersKey = 'user_saved_filter_presets_json';

  static List<SavedFilterPreset> getSavedFilters() {
    if (!ObjectBoxService.instance.isInitialized) return [];
    final jsonStr = ObjectBoxService.instance.getSetting(_savedFiltersKey);
    if (jsonStr == null || jsonStr.trim().isEmpty) return [];

    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => SavedFilterPreset.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static void saveFilter(SavedFilterPreset preset) {
    if (!ObjectBoxService.instance.isInitialized) return;
    final list = getSavedFilters();
    final index = list.indexWhere((p) => p.id == preset.id);
    if (index >= 0) {
      list[index] = preset;
    } else {
      list.insert(0, preset);
    }
    _persist(list);
  }

  static void deleteFilter(String id) {
    if (!ObjectBoxService.instance.isInitialized) return;
    final list = getSavedFilters();
    list.removeWhere((p) => p.id == id);
    _persist(list);
  }

  static void _persist(List<SavedFilterPreset> list) {
    final encoded = jsonEncode(list.map((p) => p.toJson()).toList());
    ObjectBoxService.instance.setSetting(_savedFiltersKey, encoded);
  }
}
