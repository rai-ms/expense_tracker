part of 'locale_bloc.dart';

/// Base class for Locale / Settings events
abstract class LocaleEvent extends BlocEvent {
  const LocaleEvent();
}

/// Load saved language from persistent storage
class LoadSavedLocaleEvent extends LocaleEvent {}

/// Change app language to a specific language code
class ChangeLocaleEvent extends LocaleEvent {
  final String languageCode;
  const ChangeLocaleEvent(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}
