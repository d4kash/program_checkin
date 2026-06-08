import 'package:equatable/equatable.dart';

class SessionTokens extends Equatable {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory SessionTokens.fromJson(Map<String, dynamic> json) {
    return SessionTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  SessionTokens refreshed(DateTime now) {
    return SessionTokens(
      accessToken: 'fake_access_token_refreshed',
      refreshToken: 'fake_refresh_token_refreshed',
      expiresAt: now.add(const Duration(hours: 1)),
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];
}
