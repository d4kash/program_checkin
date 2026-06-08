import 'package:health_checkin/core/clock/clock.dart';
import 'package:health_checkin/core/network/fake_api_client.dart';
import 'package:health_checkin/core/observability/observability.dart';
import 'package:health_checkin/core/storage/plain_preferences.dart';
import 'package:health_checkin/core/storage/secure_store.dart';
import 'package:health_checkin/features/checkin/data/checkin_draft_store.dart';
import 'package:health_checkin/features/program/data/fixture_loader.dart';
import 'package:health_checkin/features/program/data/program_repository.dart';
import 'package:health_checkin/features/session/data/session_repository.dart';

Map<String, dynamic> testFixture() => {
  'user': {
    'id': 'demo_user_123',
    'firstName': 'Maya',
    'email': 'maya@example.org',
    'phone': '+10000000000',
    'region': 'Region A',
  },
  'session': {
    'accessToken': 'fake_access_token',
    'refreshToken': 'fake_refresh_token',
    'expiresAt': '2026-06-02T12:30:00Z',
  },
  'program': {
    'id': 'program_001',
    'name': '12 Week Coaching Program',
    'currentWeek': 8,
    'nextCheckinDue': '2026-06-08',
    'taskStatus': 'pending',
  },
  'history': [
    {
      'id': 'c1',
      'date': '2026-05-11',
      'progressValue': 84,
      'adherence': 'completed',
      'wellbeing': 'good',
    },
    {
      'id': 'c2',
      'date': '2026-05-18',
      'progressValue': 83.2,
      'adherence': 'partial',
      'wellbeing': 'okay',
    },
    {
      'id': 'c3',
      'date': '2026-05-25',
      'progressValue': '82,7',
      'adherence': 'completed',
      'wellbeing': 'good',
    },
  ],
};

class TestHarness {
  TestHarness() {
    clock = FixedClock(DateTime.utc(2026, 6, 8, 9));
    secureStore = MemorySecureStore();
    plainPreferences = GuardedPlainPreferences(MemoryPlainPreferences());
    observability = InMemoryObservability(clock: clock);
    apiClient = FakeApiClient(clock: clock);
    loader = MemoryFixtureLoader(testFixture());
    programRepository = FixtureProgramRepository(
      fixtureLoader: loader,
      apiClient: apiClient,
      clock: clock,
      observability: observability,
    );
    sessionRepository = LocalSessionRepository(
      fixtureLoader: loader,
      apiClient: apiClient,
      secureStore: secureStore,
      clock: clock,
      observability: observability,
    );
    draftStore = CheckInDraftStore();
  }

  late FixedClock clock;
  late MemorySecureStore secureStore;
  late PlainPreferences plainPreferences;
  late InMemoryObservability observability;
  late FakeApiClient apiClient;
  late MemoryFixtureLoader loader;
  late FixtureProgramRepository programRepository;
  late LocalSessionRepository sessionRepository;
  late CheckInDraftStore draftStore;
}
