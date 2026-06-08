class StoragePolicy {
  static const Set<String> plainPreferenceAllowList = {
    'locale_code',
    'theme_mode',
  };

  static const List<String> sensitiveNeedles = [
    'token',
    'secret',
    'password',
    'passcode',
    'authorization',
    'email',
    'phone',
    'user_id',
    'userid',
    'userIdentifier',
    'name',
    'note',
  ];

  static bool isPlainPreferenceAllowed(String key, String? value) {
    final normalizedKey = key.toLowerCase();
    if (!plainPreferenceAllowList.contains(key)) return false;
    if (value == null) return true;
    final normalizedValue = value.toLowerCase();
    return !sensitiveNeedles.any(
      (needle) =>
          normalizedKey.contains(needle.toLowerCase()) ||
          normalizedValue.contains(needle.toLowerCase()),
    );
  }

  static void assertPlainPreferenceAllowed(String key, String? value) {
    if (!isPlainPreferenceAllowed(key, value)) {
      throw StateError(
        'Plain preferences rejected a sensitive or unsupported key.',
      );
    }
  }
}
