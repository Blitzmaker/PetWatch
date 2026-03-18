import 'dart:math' as math;

const String calorieCalculatorDisclaimer =
    'Der berechnete Kalorienbedarf ist ein Richtwert und sollte mit deiner Tierärztin oder deinem Tierarzt abgestimmt werden.';

double? calculateDogDailyKcal({
  required double? currentWeightKg,
  required double? targetWeightKg,
  required DateTime? birthdate,
  required String activityLevel,
  required bool isNeutered,
}) {
  final referenceWeight = targetWeightKg ?? currentWeightKg;
  if (referenceWeight == null || referenceWeight <= 0) {
    return null;
  }

  final rer = 70 * math.pow(referenceWeight, 0.75).toDouble();
  final ageInMonths = _ageInMonths(birthdate);
  final factor = _maintenanceFactor(
    ageInMonths: ageInMonths,
    activityLevel: activityLevel,
    isNeutered: isNeutered,
  );

  return (rer * factor).roundToDouble();
}

int? _ageInMonths(DateTime? birthdate) {
  if (birthdate == null) return null;
  final now = DateTime.now();
  var months = (now.year - birthdate.year) * 12 + now.month - birthdate.month;
  if (now.day < birthdate.day) months -= 1;
  return months < 0 ? 0 : months;
}

double _maintenanceFactor({
  required int? ageInMonths,
  required String activityLevel,
  required bool isNeutered,
}) {
  if (ageInMonths != null) {
    if (ageInMonths < 4) return 3;
    if (ageInMonths < 12) return 2;
    if (ageInMonths >= 84) {
      final seniorBase = isNeutered ? 1.2 : 1.4;
      if (activityLevel == 'HIGH') return seniorBase + 0.2;
      if (activityLevel == 'LOW') return math.max(1, seniorBase - 0.1).toDouble();
      return seniorBase;
    }
  }

  final base = isNeutered ? 1.6 : 1.8;
  switch (activityLevel) {
    case 'LOW':
      return math.max(1.2, base - 0.2).toDouble();
    case 'HIGH':
      return base + 0.4;
    case 'MEDIUM':
    default:
      return base;
  }
}
