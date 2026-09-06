import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/localization/app_language.dart';
import 'package:expense_tracker/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('Supported languages list contains 14 Indian, Hinglish, and International languages', () {
      expect(AppLanguage.supportedLanguages.length, 14);
      final codes = AppLanguage.supportedLanguages.map((l) => l.code).toList();
      expect(codes, containsAll(['en', 'hinglish', 'hi', 'bho', 'bn', 'ur', 'ar', 'kn', 'ml', 'ta', 'te', 'mr', 'gu', 'pa']));
    });

    test('Urdu and Arabic have isRtl set to true', () {
      final urdu = AppLanguage.fromCode('ur');
      final arabic = AppLanguage.fromCode('ar');
      final hindi = AppLanguage.fromCode('hi');
      final hinglish = AppLanguage.fromCode('hinglish');
      final bhojpuri = AppLanguage.fromCode('bho');

      expect(urdu.isRtl, isTrue);
      expect(arabic.isRtl, isTrue);
      expect(hindi.isRtl, isFalse);
      expect(hinglish.isRtl, isFalse);
      expect(bhojpuri.isRtl, isFalse);
    });

    test('English translations have clean English words with no Hindi words', () {
      final enLoc = AppLocalizations(const Locale('en'));
      expect(enLoc.translate('you_gave'), 'You Gave');
      expect(enLoc.translate('you_got'), 'You Got');
      expect(enLoc.translate('income'), 'Income');
      expect(enLoc.translate('expense'), 'Expense');
      expect(enLoc.translate('total_balance'), 'Total Balance');
    });

    test('Translations return correct strings for Hinglish and Bhojpuri', () {
      final hinglishLoc = AppLocalizations(const Locale('hinglish'));
      expect(hinglishLoc.translate('you_gave'), 'Maine Diye');
      expect(hinglishLoc.translate('you_got'), 'Mujhe Mile');
      expect(hinglishLoc.translate('total_expense'), 'Total Kharcha (Paisa Gaya)');
      expect(hinglishLoc.translate('sync_sms'), 'SMS Sync Karo');

      final bhoLoc = AppLocalizations(const Locale('bho'));
      expect(bhoLoc.translate('you_gave'), 'हम दिहनी (Maine Diye)');
      expect(bhoLoc.translate('you_got'), 'हमरा मिलल (Mujhe Mile)');
      expect(bhoLoc.translate('total_expense'), 'कुल खर्चा');
      expect(bhoLoc.translate('view_all'), 'सगरी देखीं');
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

