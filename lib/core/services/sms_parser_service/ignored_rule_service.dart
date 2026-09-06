import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../base/logger/app_logger.dart';

/// Service to persist and evaluate user-defined rules for ignoring notification SMS
@singleton
class IgnoredRuleService {
  static const String _keyIgnoredKeywords = 'user_ignored_sms_keywords';
  static const String _keyIgnoredSenders = 'user_ignored_sms_senders';

  final Set<String> _ignoredKeywords = {};
  final Set<String> _ignoredSenders = {};
  bool _isInitialized = false;

  IgnoredRuleService() {
    init();
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keywordsList = prefs.getStringList(_keyIgnoredKeywords) ?? [];
      final sendersList = prefs.getStringList(_keyIgnoredSenders) ?? [];

      _ignoredKeywords.addAll(keywordsList.map((k) => k.toLowerCase().trim()));
      _ignoredSenders.addAll(sendersList.map((s) => s.toLowerCase().trim()));
      _isInitialized = true;
    } catch (e) {
      Log.e('Error loading ignored SMS rules', error: e);
    }
  }

  /// Check if an SMS matches any user-ignored keywords or senders
  bool isIgnored(String smsBody, {String? sender}) {
    final lowerBody = smsBody.toLowerCase();

    // Check sender
    if (sender != null && sender.isNotEmpty) {
      final lowerSender = sender.toLowerCase().trim();
      for (final s in _ignoredSenders) {
        if (lowerSender.contains(s)) return true;
      }
    }

    // Check keywords
    for (final kw in _ignoredKeywords) {
      if (kw.isNotEmpty && lowerBody.contains(kw)) {
        return true;
      }
    }

    return false;
  }

  /// Add a keyword to ignore (e.g. merchant name, promo text)
  Future<void> addIgnoredKeyword(String keyword) async {
    final cleaned = keyword.toLowerCase().trim();
    if (cleaned.isEmpty) return;

    _ignoredKeywords.add(cleaned);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyIgnoredKeywords, _ignoredKeywords.toList());
  }

  /// Add a sender address to ignore (e.g. 'AX-PROMO', 'VK-ALERTS')
  Future<void> addIgnoredSender(String sender) async {
    final cleaned = sender.toLowerCase().trim();
    if (cleaned.isEmpty) return;

    _ignoredSenders.add(cleaned);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyIgnoredSenders, _ignoredSenders.toList());
  }

  /// Remove an ignored keyword
  Future<void> removeIgnoredKeyword(String keyword) async {
    _ignoredKeywords.remove(keyword.toLowerCase().trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyIgnoredKeywords, _ignoredKeywords.toList());
  }

  /// Remove an ignored sender
  Future<void> removeIgnoredSender(String sender) async {
    _ignoredSenders.remove(sender.toLowerCase().trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyIgnoredSenders, _ignoredSenders.toList());
  }

  List<String> get ignoredKeywords => _ignoredKeywords.toList();
  List<String> get ignoredSenders => _ignoredSenders.toList();
}
