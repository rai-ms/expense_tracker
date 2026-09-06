part of 'locale_bloc.dart';

/// State containing current active language metadata
class LocaleData {
  final AppLanguage currentLanguage;

  const LocaleData({required this.currentLanguage});

  Locale get locale => currentLanguage.locale;
  bool get isRtl => currentLanguage.isRtl;
}
