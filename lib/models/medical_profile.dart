import 'dart:math' as math;

import 'profile.dart';

enum Gender { male, female, other }

extension GenderLabel on Gender {
  String get label => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Other',
      };
}

/// A selectable medical condition. Each carries a [weight] — how strongly it
/// raises the wearer's overall risk (which uniformly tightens alert thresholds).
enum MedicalCondition {
  hypertension('Hypertension', 2, 'High blood pressure'),
  heartDisease('Heart disease', 3, 'Coronary / cardiac condition'),
  diabetes('Diabetes', 2, 'Type 1 or 2'),
  asthma('Asthma', 2, 'Reactive airways'),
  copd('COPD', 3, 'Chronic obstructive pulmonary disease'),
  kidneyDisease('Kidney disease', 2, 'Chronic kidney condition'),
  pregnancy('Pregnancy', 2, 'Heightened heat sensitivity'),
  obesity('Obesity', 1, 'Elevated BMI risk'),
  thyroid('Thyroid disorder', 1, 'Hypo/hyperthyroid'),
  anemia('Anaemia', 1, 'Low haemoglobin'),
  heatSensitive('Heat sensitivity', 2, 'Prior heat illness / medication');

  const MedicalCondition(this.label, this.weight, this.description);
  final String label;
  final int weight;
  final String description;
}

/// The wearer's editable medical profile. Demographics + conditions collapse to
/// a single risk score → a threshold multiplier that makes alerts fire earlier.
class MedicalProfile {
  const MedicalProfile({
    this.age = 34,
    this.gender = Gender.other,
    this.heightCm = 170,
    this.weightKg = 68,
    this.conditions = const {},
  });

  final int age;
  final Gender gender;
  final double heightCm;
  final double weightKg;
  final Set<MedicalCondition> conditions;

  double get bmi {
    final m = heightCm / 100.0;
    if (m <= 0) return 0;
    return weightKg / (m * m);
  }

  int get _ageFactor => age >= 70
      ? 3
      : age >= 60
          ? 2
          : age >= 45
              ? 1
              : 0;

  int get _bmiFactor => bmi >= 35
      ? 2
      : bmi >= 30
          ? 1
          : 0;

  /// Total risk score: conditions + age + BMI.
  int get riskScore =>
      conditions.fold<int>(0, (s, c) => s + c.weight) + _ageFactor + _bmiFactor;

  /// Threshold multiplier in [0.55, 1.0]: higher risk → lower → earlier alerts.
  double get thresholdMultiplier =>
      (1 - riskScore * 0.04).clamp(0.55, 1.0).toDouble();

  String get riskLevel {
    final s = riskScore;
    if (s >= 9) return 'High';
    if (s >= 6) return 'Elevated';
    if (s >= 3) return 'Moderate';
    return 'Low';
  }

  /// How many percent earlier alerts fire vs. a typical adult.
  int get earlierByPct => ((1 - thresholdMultiplier) * 100).round();

  bool get _highRisk => age >= 60 || riskScore >= 4;

  /// The effective wearer [Profile] the pipeline runs on — a base profile with
  /// PSI thresholds tightened by the risk multiplier and cardio demographics set.
  Profile effectiveProfile() {
    final base = _highRisk ? Profile.vulnerable : Profile.standard;
    final m = thresholdMultiplier;
    return base.copyWith(
      key: 'custom',
      label: 'Your profile',
      l1: base.l1 * m,
      l2: base.l2 * m,
      l3: base.l3 * m,
      cardioAge: age.toDouble(),
      cardioBmi: bmi.clamp(15, 45).toDouble(),
    );
  }

  /// Stable signature for caching the computed day.
  String get signature {
    final cs = (conditions.map((c) => c.name).toList()..sort()).join(',');
    return '$age|${gender.name}|${bmi.toStringAsFixed(1)}|$cs';
  }

  MedicalProfile copyWith({
    int? age,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    Set<MedicalCondition>? conditions,
  }) {
    return MedicalProfile(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      conditions: conditions ?? this.conditions,
    );
  }

  MedicalProfile toggle(MedicalCondition c) {
    final next = Set<MedicalCondition>.from(conditions);
    next.contains(c) ? next.remove(c) : next.add(c);
    return copyWith(conditions: next);
  }
}

/// BMI category label for display.
String bmiCategory(double bmi) {
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25) return 'Healthy';
  if (bmi < 30) return 'Overweight';
  return 'Obese';
}

double clampd(double v, double lo, double hi) => math.max(lo, math.min(hi, v));
