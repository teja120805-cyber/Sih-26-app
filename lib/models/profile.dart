/// Demo wearer profiles — personal baselines and alert thresholds, ported
/// verbatim from the web console's `PROFILES` object. These stand in for the
/// "14 days of your own data" a real device would learn per wearer.
class Profile {
  const Profile({
    required this.key,
    required this.label,
    required this.hr0,
    required this.hr0Std,
    required this.skin0,
    required this.skin0Std,
    required this.tc0,
    required this.tc0Std,
    required this.rr0,
    required this.rr0Std,
    required this.spo20,
    required this.spo2Std,
    required this.l1,
    required this.l2,
    required this.l3,
    required this.hrv0,
    required this.cardioAge,
    required this.cardioBmi,
  });

  final String key;
  final String label;
  final double hr0; // resting heart rate baseline
  final double hr0Std;
  final double skin0; // resting skin temp baseline
  final double skin0Std;
  final double tc0; // resting core temp baseline
  final double tc0Std;
  final double rr0; // resting respiratory rate
  final double rr0Std;
  final double spo20;
  final double spo2Std;
  final double l1; // PSI advisory threshold
  final double l2; // PSI warning threshold
  final double l3; // PSI critical threshold
  final double hrv0;
  final double cardioAge;
  final double cardioBmi;

  static const standard = Profile(
    key: 'standard',
    label: 'Typical adult',
    hr0: 71,
    hr0Std: 6,
    skin0: 33.2,
    skin0Std: 0.6,
    tc0: 37.0,
    tc0Std: 0.35,
    rr0: 15,
    rr0Std: 2.5,
    spo20: 97.5,
    spo2Std: 1.2,
    l1: 2.0,
    l2: 4.0,
    l3: 7.0,
    hrv0: 64,
    cardioAge: 34,
    cardioBmi: 23.5,
  );

  static const vulnerable = Profile(
    key: 'vulnerable',
    label: 'Higher-risk (elder / hypertensive)',
    hr0: 78,
    hr0Std: 8,
    skin0: 33.4,
    skin0Std: 0.7,
    tc0: 37.0,
    tc0Std: 0.4,
    rr0: 17,
    rr0Std: 3.0,
    spo20: 96.5,
    spo2Std: 1.5,
    l1: 1.4,
    l2: 2.8,
    l3: 5.0,
    hrv0: 50,
    cardioAge: 63,
    cardioBmi: 27.5,
  );

  static const all = <Profile>[standard, vulnerable];

  static Profile byKey(String key) =>
      all.firstWhere((p) => p.key == key, orElse: () => standard);
}

/// Core-temperature filter constants (KP) — literature/architecture-chosen,
/// not fitted, matching the web console.
class CoreTempKp {
  static const double relax = 0.045;
  static const double ke = 4.2;
}

/// Data-generation baselines the CSVs were produced at (used to re-center the
/// shared raw data onto each profile's baseline).
class GenBaseline {
  static const double hr0 = 71.0;
  static const double skin0 = 33.2;
}

const int kStepMin = 5; // sample spacing in minutes
const int kN = 288; // samples per simulated day (24h @ 5-min)
