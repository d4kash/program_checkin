import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('de')];
  static const delegate = _AppStringsDelegate();

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  static const _values = <String, Map<String, String>>{
    'en': {
      'appTitle': 'Program Check-in',
      'dashboard': 'Dashboard',
      'history': 'History',
      'checkIn': 'Check-in',
      'hello': 'Hello',
      'region': 'Region',
      'currentWeek': 'Current week',
      'nextDue': 'Next check-in due',
      'pendingTask': 'Weekly check-in pending',
      'startCheckIn': 'Start check-in',
      'refresh': 'Refresh',
      'retry': 'Retry',
      'loadingDashboard': 'Loading your program...',
      'emptyDashboard': 'No active program is available.',
      'dashboardRefreshFailed': 'Refresh failed. Showing your last saved view.',
      'progressValue': 'Progress value',
      'progressHint': 'Enter a number, for example 80.4',
      'adherence': 'Adherence',
      'completed': 'Completed as planned',
      'partial': 'Partially completed',
      'missed': 'Missed',
      'wellbeing': 'Wellbeing',
      'good': 'Good',
      'okay': 'Okay',
      'needsSupport': 'Needs support',
      'optionalNote': 'Optional note',
      'noteHint': 'Add context for yourself. This is never logged.',
      'summary': 'Summary',
      'submit': 'Submit',
      'submitting': 'Submitting...',
      'submitted': 'Check-in submitted',
      'continueText': 'Continue',
      'back': 'Back',
      'supportTitle': 'Support step',
      'supportBody':
          'You selected Needs support. In a real product this could show safe next steps or contact options. This demo keeps the domain generic.',
      'requiredField': 'This field is required.',
      'invalidProgress': 'Enter a valid numeric progress value.',
      'retrySubmit': 'Retry submit',
      'offlineRetry': 'Submit failed, but your draft is safe. Please retry.',
      'unauthorized': 'Session expired. Sensitive session data was cleared.',
      'recentProgress': 'Recent progress',
      'noValue': 'No value',
      'trend': 'Trend',
      'settings': 'Settings',
      'language': 'Language',
      'english': 'English',
      'german': 'German',
      'routeError': 'Route error',
      'invalidRouteData':
          'The route data was not valid. You can safely return to the dashboard.',
      'routeNotFound': 'This screen does not exist.',
      'backToDashboard': 'Back to dashboard',
      'sessionSafe': 'Secure local session active',
      'sessionExpired': 'Unauthenticated safe state',
      'expiresAt': 'Expires at',
      'viewHistory': 'View history',
      'progressStep': 'Progress',
      'adherenceStep': 'Adherence',
      'wellbeingStep': 'Wellbeing',
      'noteStep': 'Note',
    },
    'de': {
      'appTitle': 'Programm-Check-in',
      'dashboard': 'Übersicht',
      'history': 'Verlauf',
      'checkIn': 'Check-in',
      'hello': 'Hallo',
      'region': 'Region',
      'currentWeek': 'Aktuelle Woche',
      'nextDue': 'Nächster Check-in',
      'pendingTask': 'Wöchentlicher Check-in offen',
      'startCheckIn': 'Check-in starten',
      'refresh': 'Aktualisieren',
      'retry': 'Erneut versuchen',
      'loadingDashboard': 'Programm wird geladen...',
      'emptyDashboard': 'Kein aktives Programm verfügbar.',
      'dashboardRefreshFailed':
          'Aktualisierung fehlgeschlagen. Die letzte Ansicht bleibt sichtbar.',
      'progressValue': 'Fortschrittswert',
      'progressHint': 'Zahl eingeben, zum Beispiel 80,4',
      'adherence': 'Umsetzung',
      'completed': 'Wie geplant erledigt',
      'partial': 'Teilweise erledigt',
      'missed': 'Verpasst',
      'wellbeing': 'Wohlbefinden',
      'good': 'Gut',
      'okay': 'Okay',
      'needsSupport': 'Benötigt Unterstützung',
      'optionalNote': 'Optionale Notiz',
      'noteHint': 'Kontext für dich hinzufügen. Dies wird nie protokolliert.',
      'summary': 'Zusammenfassung',
      'submit': 'Senden',
      'submitting': 'Wird gesendet...',
      'submitted': 'Check-in gesendet',
      'continueText': 'Weiter',
      'back': 'Zurück',
      'supportTitle': 'Unterstützungsschritt',
      'supportBody':
          'Du hast Benötigt Unterstützung gewählt. In einem echten Produkt könnten hier sichere nächste Schritte erscheinen. Diese Demo bleibt allgemein.',
      'requiredField': 'Dieses Feld ist erforderlich.',
      'invalidProgress': 'Bitte einen gültigen numerischen Wert eingeben.',
      'retrySubmit': 'Senden erneut versuchen',
      'offlineRetry':
          'Senden fehlgeschlagen, aber dein Entwurf ist sicher. Bitte erneut versuchen.',
      'unauthorized':
          'Sitzung abgelaufen. Sensible Sitzungsdaten wurden gelöscht.',
      'recentProgress': 'Aktueller Verlauf',
      'noValue': 'Kein Wert',
      'trend': 'Trend',
      'settings': 'Einstellungen',
      'language': 'Sprache',
      'english': 'Englisch',
      'german': 'Deutsch',
      'routeError': 'Routenfehler',
      'invalidRouteData':
          'Die Routendaten waren ungültig. Du kannst sicher zur Übersicht zurückkehren.',
      'routeNotFound': 'Dieser Bildschirm existiert nicht.',
      'backToDashboard': 'Zur Übersicht',
      'sessionSafe': 'Sichere lokale Sitzung aktiv',
      'sessionExpired': 'Sicherer nicht angemeldeter Zustand',
      'expiresAt': 'Läuft ab um',
      'viewHistory': 'Verlauf ansehen',
      'progressStep': 'Fortschritt',
      'adherenceStep': 'Umsetzung',
      'wellbeingStep': 'Wohlbefinden',
      'noteStep': 'Notiz',
    },
  };

  String _t(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key]!;

  String get appTitle => _t('appTitle');
  String get dashboard => _t('dashboard');
  String get history => _t('history');
  String get checkIn => _t('checkIn');
  String get hello => _t('hello');
  String get region => _t('region');
  String get currentWeek => _t('currentWeek');
  String get nextDue => _t('nextDue');
  String get pendingTask => _t('pendingTask');
  String get startCheckIn => _t('startCheckIn');
  String get refresh => _t('refresh');
  String get retry => _t('retry');
  String get loadingDashboard => _t('loadingDashboard');
  String get emptyDashboard => _t('emptyDashboard');
  String get dashboardRefreshFailed => _t('dashboardRefreshFailed');
  String get progressValue => _t('progressValue');
  String get progressHint => _t('progressHint');
  String get adherence => _t('adherence');
  String get completed => _t('completed');
  String get partial => _t('partial');
  String get missed => _t('missed');
  String get wellbeing => _t('wellbeing');
  String get good => _t('good');
  String get okay => _t('okay');
  String get needsSupport => _t('needsSupport');
  String get optionalNote => _t('optionalNote');
  String get noteHint => _t('noteHint');
  String get summary => _t('summary');
  String get submit => _t('submit');
  String get submitting => _t('submitting');
  String get submitted => _t('submitted');
  String get continueText => _t('continueText');
  String get back => _t('back');
  String get supportTitle => _t('supportTitle');
  String get supportBody => _t('supportBody');
  String get requiredField => _t('requiredField');
  String get invalidProgress => _t('invalidProgress');
  String get retrySubmit => _t('retrySubmit');
  String get offlineRetry => _t('offlineRetry');
  String get unauthorized => _t('unauthorized');
  String get recentProgress => _t('recentProgress');
  String get noValue => _t('noValue');
  String get trend => _t('trend');
  String get settings => _t('settings');
  String get language => _t('language');
  String get english => _t('english');
  String get german => _t('german');
  String get routeError => _t('routeError');
  String get invalidRouteData => _t('invalidRouteData');
  String get routeNotFound => _t('routeNotFound');
  String get backToDashboard => _t('backToDashboard');
  String get sessionSafe => _t('sessionSafe');
  String get sessionExpired => _t('sessionExpired');
  String get expiresAt => _t('expiresAt');
  String get viewHistory => _t('viewHistory');
  String get progressStep => _t('progressStep');
  String get adherenceStep => _t('adherenceStep');
  String get wellbeingStep => _t('wellbeingStep');
  String get noteStep => _t('noteStep');

  String adherenceLabel(String value) {
    switch (value) {
      case 'completed':
        return completed;
      case 'partial':
        return partial;
      case 'missed':
        return missed;
      default:
        return value;
    }
  }

  String wellbeingLabel(String value) {
    switch (value) {
      case 'good':
        return good;
      case 'okay':
        return okay;
      case 'needs_support':
        return needsSupport;
      default:
        return value;
    }
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppStrings.supportedLocales.any(
      (item) => item.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
