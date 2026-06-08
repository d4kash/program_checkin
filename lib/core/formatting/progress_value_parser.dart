class ProgressValueParser {
  const ProgressValueParser._();

  static double? tryParse(dynamic value) {
    if (value == null) return null;

    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    // Allows:
    // 80
    // 80.4
    // 80,4
    // Rejects mixed or repeated separators.
    final validNumberPattern = RegExp(r'^\d+([.,]\d+)?$');

    if (!validNumberPattern.hasMatch(raw)) {
      return null;
    }

    final normalized = raw.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  static bool isValidInput(dynamic value) => tryParse(value) != null;
}
