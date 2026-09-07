import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/models/app_setting_entity.dart';
import '../../../data/models/bill_reminder_entity.dart';
import '../../../data/models/khata_contact_entity.dart';
import '../../../data/models/khata_entry_entity.dart';
import '../../../data/models/transaction_entity.dart';
import '../../../objectbox.g.dart';
import '../../base/base_service/base_service.dart';
import '../../base/logger/app_logger.dart';

/// ObjectBox database service managing local persistence and typed boxes
class ObjectBoxService extends BaseService<Future<void>, void> {
  static ObjectBoxService? _instance;
  Store? _store;
  bool _isInitialized = false;

  ObjectBoxService._();

  static ObjectBoxService get instance {
    _instance ??= ObjectBoxService._();
    return _instance!;
  }

  Store get store {
    if (!_isInitialized || _store == null) {
      throw Exception('ObjectBoxService not initialized.');
    }
    return _store!;
  }

  bool get isInitialized => _isInitialized;

  @override
  Future<void> init({void param}) async {
    if (_isInitialized) {
      Log.w('ObjectBoxService already initialized');
      return;
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docsDir.path, 'expense_tracker_objectbox');

      _store = await openStore(directory: dbPath);
      _isInitialized = true;
      Log.i('ObjectBoxService initialized successfully at: $dbPath');
    } catch (e, stackTrace) {
      Log.e('Failed to initialize ObjectBox', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Typed Box accessors
  Box<TransactionEntity> get transactionBox => store.box<TransactionEntity>();
  Box<KhataContactEntity> get khataContactBox => store.box<KhataContactEntity>();
  Box<KhataEntryEntity> get khataEntryBox => store.box<KhataEntryEntity>();
  Box<BillReminderEntity> get billReminderBox => store.box<BillReminderEntity>();
  Box<AppSettingEntity> get settingBox => store.box<AppSettingEntity>();

  // ===========================================================================
  // ⚡ Synchronous Key-Value Preferences stored natively in ObjectBox
  // ===========================================================================
  String? getSetting(String key, {String? defaultValue}) {
    final query = settingBox.query(AppSettingEntity_.key.equals(key)).build();
    final item = query.findFirst();
    query.close();
    return item?.value ?? defaultValue;
  }

  void setSetting(String key, String value) {
    final query = settingBox.query(AppSettingEntity_.key.equals(key)).build();
    final item = query.findFirst();
    query.close();

    if (item != null) {
      item.value = value;
      settingBox.put(item);
    } else {
      settingBox.put(AppSettingEntity(key: key, value: value));
    }
  }

  double getDoubleSetting(String key, {double defaultValue = 0.0}) {
    final str = getSetting(key);
    if (str == null) return defaultValue;
    return double.tryParse(str) ?? defaultValue;
  }

  void setDoubleSetting(String key, double value) {
    setSetting(key, value.toString());
  }

  int? getIntSetting(String key) {
    final str = getSetting(key);
    if (str == null) return null;
    return int.tryParse(str);
  }

  void setIntSetting(String key, int value) {
    setSetting(key, value.toString());
  }

  bool getBoolSetting(String key, {bool defaultValue = false}) {
    final str = getSetting(key);
    if (str == null) return defaultValue;
    return str == 'true';
  }

  void setBoolSetting(String key, bool value) {
    setSetting(key, value.toString());
  }

  List<String> getStringListSetting(String key) {
    final str = getSetting(key);
    if (str == null || str.isEmpty) return [];
    return str.split('|||');
  }

  void setStringListSetting(String key, List<String> list) {
    setSetting(key, list.join('|||'));
  }

  @override
  void dispose() {
    if (_isInitialized && _store != null) {
      _store!.close();
      _store = null;
      _isInitialized = false;
      Log.d('ObjectBoxService disposed');
    }
    super.dispose();
  }

  /// Clear all data
  void clearAll() {
    transactionBox.removeAll();
    khataContactBox.removeAll();
    khataEntryBox.removeAll();
    billReminderBox.removeAll();
    Log.i('ObjectBox: Cleared all collections.');
  }
}
