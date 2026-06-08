import 'package:intl/intl.dart';

import 'progress_value_parser.dart';

class LocaleFormatters {
  const LocaleFormatters(this.localeCode);

  final String localeCode;

  String date(DateTime date) => DateFormat.yMMMd(localeCode).format(date);

  String number(num value) =>
      NumberFormat.decimalPattern(localeCode).format(value);

  String progress(Object? value, {String missing = 'No value'}) {
    final parsed = ProgressValueParser.tryParse(value);
    if (parsed == null) return missing;
    final formatter = NumberFormat.decimalPattern(localeCode)
      ..minimumFractionDigits = parsed % 1 == 0 ? 0 : 1
      ..maximumFractionDigits = 1;
    return formatter.format(parsed);
  }
}
