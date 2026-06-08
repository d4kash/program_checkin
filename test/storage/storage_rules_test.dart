import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/core/storage/plain_preferences.dart';
import 'package:health_checkin/core/storage/secure_store.dart';

void main() {
  test('secure-store vs plain-preferences storage rules', () async {
    final secureStore = MemorySecureStore();
    final preferences = GuardedPlainPreferences(MemoryPlainPreferences());

    await secureStore.write('access_token', 'fake_access_token');
    await preferences.setString('locale_code', 'de');

    expect(
      (await secureStore.dumpForTests())['access_token'],
      'fake_access_token',
    );
    expect((await preferences.dumpForTests())['locale_code'], 'de');
    expect(
      () => preferences.setString('access_token', 'fake_access_token'),
      throwsStateError,
    );
    expect(
      () => preferences.setString('locale_code', 'fake_access_token'),
      throwsStateError,
    );
  });
}
