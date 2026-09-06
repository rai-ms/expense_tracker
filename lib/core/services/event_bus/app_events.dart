import 'package:flutter/foundation.dart';

/// Global application event notifier for real-time synchronization across tabs and modals
class AppEvents {
  AppEvents._();

  /// Change notifier triggered whenever transactions, khata entries, or reminders change
  static final ValueNotifier<int> syncNotifier = ValueNotifier<int>(0);

  /// Notify all active screens, blocs, and widgets to reload latest ObjectBox data
  static void notifyDataChanged() {
    syncNotifier.value++;
  }
}
