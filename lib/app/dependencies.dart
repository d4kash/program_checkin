import 'package:health_checkin/core/clock/clock.dart';
import 'package:health_checkin/core/network/fake_api_client.dart';
import 'package:health_checkin/core/observability/observability.dart';
import 'package:health_checkin/core/storage/plain_preferences.dart';
import 'package:health_checkin/core/storage/secure_store.dart';
import 'package:health_checkin/features/checkin/data/checkin_draft_store.dart';
import 'package:health_checkin/features/program/data/fixture_loader.dart';
import 'package:health_checkin/features/program/data/program_repository.dart';
import 'package:health_checkin/features/session/data/session_repository.dart';

class AppDependencies {
  AppDependencies({
    required this.clock,
    required this.secureStore,
    required this.plainPreferences,
    required this.observability,
    required this.fakeApiClient,
    required this.programRepository,
    required this.sessionRepository,
    required this.checkInDraftStore,
  });

  factory AppDependencies.production() {
    final clock = SystemClock();
    final secureStore = MemorySecureStore();
    final plainPreferences = GuardedPlainPreferences(MemoryPlainPreferences());
    final observability = InMemoryObservability(clock: clock);
    final fakeApiClient = FakeApiClient(clock: clock);
    final loader = AssetFixtureLoader('assets/fixtures/program_fixture.json');
    final checkInDraftStore = CheckInDraftStore();
    final programRepository = FixtureProgramRepository(
      fixtureLoader: loader,
      apiClient: fakeApiClient,
      clock: clock,
      observability: observability,
    );
    final sessionRepository = LocalSessionRepository(
      fixtureLoader: loader,
      apiClient: fakeApiClient,
      secureStore: secureStore,
      clock: clock,
      observability: observability,
    );

    return AppDependencies(
      clock: clock,
      secureStore: secureStore,
      plainPreferences: plainPreferences,
      observability: observability,
      fakeApiClient: fakeApiClient,
      programRepository: programRepository,
      sessionRepository: sessionRepository,
      checkInDraftStore: checkInDraftStore,
    );
  }

  final Clock clock;
  final SecureStore secureStore;
  final PlainPreferences plainPreferences;
  final InMemoryObservability observability;
  final FakeApiClient fakeApiClient;
  final ProgramRepository programRepository;
  final SessionRepository sessionRepository;
  final CheckInDraftStore checkInDraftStore;
}
