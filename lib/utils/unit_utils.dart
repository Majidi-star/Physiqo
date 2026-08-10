class UnitUtils {
  // Conversions
  static double kgToLb(double kg) => kg * 2.20462;
  static double lbToKg(double lb) => lb / 2.20462;

  static double cmToInches(double cm) => cm * 0.393701;
  static double inchesToCm(double inches) => inches / 0.393701;

  // Format Helpers
  static String formatKgToLb(double kg) => kgToLb(kg).toStringAsFixed(1);
  static String formatCmToFtIn(double cm) {
    double totalInches = cmToInches(cm);
    int feet = (totalInches / 12).floor();
    int inches = (totalInches % 12).round();
    if (inches == 12) {
      feet += 1;
      inches = 0;
    }
    return '$feet\' $inches"';
  }

  // Parses 5' 10" string to cm
  static double parseFtInToCm(String ftIn) {
    try {
      final parts = ftIn.split("'");
      if (parts.length != 2) return 0.0;
      final feet = int.parse(parts[0].trim());
      final inchesStr = parts[1].replaceAll('"', '').trim();
      final inches = int.parse(inchesStr);
      final totalInches = (feet * 12) + inches;
      return inchesToCm(totalInches.toDouble());
    } catch (e) {
      return 0.0;
    }
  }
}
