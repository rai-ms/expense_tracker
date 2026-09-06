import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/localization/app_language.dart';
import 'package:expense_tracker/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('Supported languages list contains 12 Indian and International languages', () {
      expect(AppLanguage.supportedLanguages.length, 12);
      final codes = AppLanguage.supportedLanguages.map((l) => l.code).toList();
      expect(codes, containsAll(['en', 'hi', 'bn', 'ur', 'ar', 'kn', 'ml', 'ta', 'te', 'mr', 'gu', 'pa']));
    });

    test('Urdu and Arabic have isRtl set to true', () {
      final urdu = AppLanguage.fromCode('ur');
      final arabic = AppLanguage.fromCode('ar');
      final hindi = AppLanguage.fromCode('hi');

      expect(urdu.isRtl, isTrue);
      expect(arabic.isRtl, isTrue);
      expect(hindi.isRtl, isFalse);
    });

    test('Translations return correct strings for Hindi', () {
      final loc = AppLocalizations(const Locale('hi'));
      expect(loc.translate('dashboard'), 'डैशबोर्ड');
      expect(loc.translate('khata'), 'खाताबुक');
      expect(loc.translate('you_will_receive'), 'आपको मिलेंगे');
      expect(loc.translate('you_will_give'), 'आपको देने हैं');
    });

    test('Translations return correct strings for Bengali, Kannada, and Punjabi', () {
      final bnLoc = AppLocalizations(const Locale('bn'));
      expect(bnLoc.translate('dashboard'), 'ড্যাশবোর্ড');

      final knLoc = AppLocalizations(const Locale('kn'));
      expect(knLoc.translate('khata'), 'ಖಾತಾಬುಕ್');

      final paLoc = AppLocalizations(const Locale('pa'));
      expect(paLoc.translate('transactions'), 'ਲੈਣ-ਦੇਣ');
    });
  });
}
