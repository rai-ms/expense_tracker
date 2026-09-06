import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/base/bloc_base/base_bloc.dart';
import '../../../../core/base/bloc_base/bloc_event.dart';
import '../../../../core/localization/app_language.dart';

part 'locale_event.dart';
part 'locale_state.dart';

@singleton
class LocaleBloc extends BaseBloc<LocaleEvent, LocaleData> {
  static const String _prefLanguageKey = 'selected_app_language_code';

  LocaleBloc() {
    on<LoadSavedLocaleEvent>(_onLoadSavedLocale);
    on<ChangeLocaleEvent>(_onChangeLocale);
  }

  Future<void> _onLoadSavedLocale(
    LoadSavedLocaleEvent event,
    dynamic emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefLanguageKey) ?? 'en';
      final language = AppLanguage.fromCode(savedCode);
      emitSuccess(data: LocaleData(currentLanguage: language));
    } catch (e) {
      emitSuccess(data: LocaleData(currentLanguage: AppLanguage.fromCode('en')));
    }
  }

  Future<void> _onChangeLocale(
    ChangeLocaleEvent event,
    dynamic emit,
  ) async {
    try {
      final language = AppLanguage.fromCode(event.languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLanguageKey, event.languageCode);
      emitSuccess(data: LocaleData(currentLanguage: language));
    } catch (e) {
      final language = AppLanguage.fromCode(event.languageCode);
      emitSuccess(data: LocaleData(currentLanguage: language));
    }
  }
}
