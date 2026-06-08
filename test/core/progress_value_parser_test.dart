import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/core/formatting/progress_value_parser.dart';

void main() {
  group('ProgressValueParser', () {
    test('parses int, decimal dot, and decimal comma values', () {
      expect(ProgressValueParser.tryParse(80), 80);
      expect(ProgressValueParser.tryParse(80.4), 80.4);
      expect(ProgressValueParser.tryParse('80.4'), 80.4);
      expect(ProgressValueParser.tryParse('80,4'), 80.4);
    });
    test('rejects invalid progress values', () {
      expect(ProgressValueParser.tryParse('abc'), isNull);
      expect(ProgressValueParser.tryParse('80,4.5'), isNull);
      expect(ProgressValueParser.tryParse('80..4'), isNull);
      expect(ProgressValueParser.tryParse(''), isNull);
    });
  });
  test('parses mixed numeric progress values', () {
    expect(ProgressValueParser.tryParse(80), 80);
    expect(ProgressValueParser.tryParse(80.4), 80.4);
    expect(ProgressValueParser.tryParse('80,4'), 80.4);
    expect(ProgressValueParser.tryParse('not-a-number'), isNull);
  });
}
