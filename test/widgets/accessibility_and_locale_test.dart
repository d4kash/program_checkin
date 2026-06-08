import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/app/app.dart';
import 'package:health_checkin/app/dependencies.dart';
import 'package:health_checkin/app/localization/app_localizations.dart';
import 'package:health_checkin/core/clock/clock.dart';
import 'package:health_checkin/core/network/fake_api_client.dart';
import 'package:health_checkin/core/observability/observability.dart';
import 'package:health_checkin/core/storage/plain_preferences.dart';
import 'package:health_checkin/core/storage/secure_store.dart';
import 'package:health_checkin/features/checkin/data/checkin_draft_store.dart';
import 'package:health_checkin/features/checkin/presentation/widgets/accessible_choice_card.dart';
import 'package:health_checkin/features/program/data/fixture_loader.dart';
import 'package:health_checkin/features/program/data/program_repository.dart';
import 'package:health_checkin/features/program/domain/models.dart';
import 'package:health_checkin/features/session/data/session_repository.dart';

import '../helpers/test_fixture.dart';

const _localizationDelegates = <LocalizationsDelegate<dynamic>>[
  AppStrings.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

AppDependencies testDependencies() {
  final clock = FixedClock(DateTime.utc(2026, 6, 8, 9));
  final secureStore = MemorySecureStore();
  final preferences = GuardedPlainPreferences(MemoryPlainPreferences());
  final observability = InMemoryObservability(clock: clock);
  final api = FakeApiClient(clock: clock);
  final loader = MemoryFixtureLoader(testFixture());
  final programRepository = FixtureProgramRepository(
    fixtureLoader: loader,
    apiClient: api,
    clock: clock,
    observability: observability,
  );
  final sessionRepository = LocalSessionRepository(
    fixtureLoader: loader,
    apiClient: api,
    secureStore: secureStore,
    clock: clock,
    observability: observability,
  );

  return AppDependencies(
    clock: clock,
    secureStore: secureStore,
    plainPreferences: preferences,
    observability: observability,
    fakeApiClient: api,
    programRepository: programRepository,
    sessionRepository: sessionRepository,
    checkInDraftStore: CheckInDraftStore(),
  );
}

void main() {
  testWidgets('dashboard renders on a small viewport with large text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: ProgramCheckInApp(dependencies: testDependencies()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Maya'), findsOneWidget);
  });

testWidgets('custom selection control exposes semantics', (tester) async {
  final semanticsHandle = tester.ensureSemantics();

  try {
    const semanticsKey = ValueKey('completed_choice_semantics');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccessibleChoiceCard<Adherence>(
            semanticsKey: semanticsKey,
            value: Adherence.completed,
            groupValue: Adherence.completed,
            label: 'Completed as planned',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.pump();

    final node = tester.getSemantics(find.byKey(semanticsKey));

    expect(
      node,
      matchesSemantics(
        label: 'Completed as planned',
        hasSelectedState: true,
        isSelected: true,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
  } finally {
    semanticsHandle.dispose();
  }
});
  testWidgets('English and German labels update', (tester) async {
    Locale activeLocale = const Locale('en');

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            locale: activeLocale,
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: _localizationDelegates,
            home: Builder(
              builder: (context) {
                final strings = AppStrings.of(context);
                return Scaffold(
                  body: Column(
                    children: [
                      Text(strings.dashboard),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            activeLocale = const Locale('de');
                          });
                        },
                        child: const Text('switch'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);

    await tester.tap(find.text('switch'));
    await tester.pumpAndSettle();

    expect(find.text('Übersicht'), findsOneWidget);
  });
}

// void _noopAdherence(Adherence value) {}
