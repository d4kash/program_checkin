import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/core/formatting/locale_formatters.dart';

void main() {
  test('formats numeric values for active locale', () {
    expect(LocaleFormatters('en').progress('80.4'), '80.4');
    expect(LocaleFormatters('de').progress('80.4'), '80,4');
  });
}
