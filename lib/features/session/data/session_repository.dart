import 'package:health_checkin/core/clock/clock.dart';
import 'package:health_checkin/core/network/fake_api_client.dart';
import 'package:health_checkin/core/observability/observability.dart';
import 'package:health_checkin/core/result/app_result.dart';
import 'package:health_checkin/core/storage/secure_store.dart';
import 'package:health_checkin/features/program/data/fixture_loader.dart';
import 'package:health_checkin/features/session/domain/session_models.dart';

abstract class SessionRepository {
  Future<SessionTokens?> restore();
  Future<AppResult<SessionTokens>> refresh({required String correlationId});
  Future<void> clear();
}

class LocalSessionRepository implements SessionRepository {
  LocalSessionRepository({
    required this.fixtureLoader,
    required this.apiClient,
    required this.secureStore,
    required this.clock,
    required this.observability,
  });

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresAtKey = 'expires_at';

  final FixtureLoader fixtureLoader;
  final FakeApiClient apiClient;
  final SecureStore secureStore;
  final Clock clock;
  final InMemoryObservability observability;

  @override
  Future<SessionTokens?> restore() async {
    final accessToken = await secureStore.read(_accessTokenKey);
    final refreshToken = await secureStore.read(_refreshTokenKey);
    final expiresAt = await secureStore.read(_expiresAtKey);
    if (accessToken != null && refreshToken != null && expiresAt != null) {
      return SessionTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.parse(expiresAt),
      );
    }
    final fixture = await fixtureLoader.load();
    final tokens = SessionTokens.fromJson(
      fixture['session'] as Map<String, dynamic>,
    );
    await _persist(tokens);
    return tokens;
  }

  @override
  Future<AppResult<SessionTokens>> refresh({
    required String correlationId,
  }) async {
    final result = await apiClient.request(endpoint: 'session_refresh');
    if (result is AppFailureResult<void>) {
      if (result.failure.isUnauthorized) {
        await clear();
      }
      observability.recordEvent(
        'session_refresh_failed',
        level: LogLevel.warning,
        attributes: {
          'correlation_id': correlationId,
          'failure_code': result.failure.code.name,
          'retryable': result.failure.retryable,
          'status_class': result.failure.statusClass,
        },
      );
      return AppFailureResult(result.failure);
    }
    final current = await restore();
    final refreshed =
        (current ??
                SessionTokens(
                  accessToken: 'fake_access_token',
                  refreshToken: 'fake_refresh_token',
                  expiresAt: clock.now(),
                ))
            .refreshed(clock.now());
    await _persist(refreshed);
    return AppSuccess(refreshed);
  }

  @override
  Future<void> clear() => secureStore.clear();

  Future<void> _persist(SessionTokens tokens) async {
    await secureStore.write(_accessTokenKey, tokens.accessToken);
    await secureStore.write(_refreshTokenKey, tokens.refreshToken);
    await secureStore.write(_expiresAtKey, tokens.expiresAt.toIso8601String());
  }
}
