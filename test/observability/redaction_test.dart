import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/core/observability/observability.dart';

void main() {
  test('allowlist builder drops unsafe fields', () {
    final safe = SafeAttributes.build({
      'route_name': 'check-in',
      'status_class': '2xx',
      'email': 'maya@example.org',
      'request_body': {'note': 'private'},
      'progress_value': 80.4,
      'token': 'fake_access_token',
    });

    expect(safe['route_name'], 'check-in');
    expect(safe['status_class'], '2xx');
    expect(safe.containsKey('email'), isFalse);
    expect(safe.containsKey('request_body'), isFalse);
    expect(safe.containsKey('progress_value'), isFalse);
    expect(safe.containsKey('token'), isFalse);
  });
}
