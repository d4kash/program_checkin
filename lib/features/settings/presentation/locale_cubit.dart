import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_checkin/core/storage/plain_preferences.dart';

class LocaleState extends Equatable {
  const LocaleState(this.locale);

  final Locale locale;

  @override
  List<Object?> get props => [locale];
}

class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit(this._preferences) : super(const LocaleState(Locale('en')));

  static const _localeKey = 'locale_code';
  final PlainPreferences _preferences;

  Future<void> restore() async {
    final code = await _preferences.getString(_localeKey);
    if (code == 'de') {
      emit(const LocaleState(Locale('de')));
    }
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'de' ? 'de' : 'en';
    await _preferences.setString(_localeKey, code);
    emit(LocaleState(Locale(code)));
  }
}
