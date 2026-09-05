import 'day_data.dart';
import 'medical_profile.dart';

/// Overall, plain-language health status at a moment — driven by the wearer's
/// own warn/crit thresholds for heart rate, core temp, SpO₂ and strain.
class HealthStatus {
  HealthStatus({
    required this.level, // 0 normal · 2 warning · 3 critical
    required this.title,
    required this.message,
    required this.actions,
    required this.triggered,
  });

  final int level;
  final String title;
  final String message;
  final List<String> actions;
  final String triggered; // which signal drove it (or 'none')

  bool get isCritical => level >= 3;
  bool get isWarning => level == 2;
  bool get isNormal => level == 0;
}

int _metricLevel(double v, double warn, double crit, {bool lowerWorse = false}) {
  if (lowerWorse) {
    if (v <= crit) return 3;
    if (v <= warn) return 2;
  } else {
    if (v >= crit) return 3;
    if (v >= warn) return 2;
  }
  return 0;
}

/// Computes the overall status for sample [i] using the wearer's thresholds.
HealthStatus computeStatus(int i, DayData day, MedicalProfile m) {
  final strain = day.psi[i];
  final hr = day.hr[i];
  final temp = day.coreTemp[i];
  final spo2 = day.spo2[i];

  final levels = <String, int>{
    'strain': _metricLevel(strain, m.effStrainWarn, m.effStrainCrit),
    'temp': _metricLevel(temp, m.effTempWarn, m.effTempCrit),
    'hr': _metricLevel(hr, m.effHrWarn, m.effHrCrit),
    'spo2': _metricLevel(spo2, m.effSpo2Warn, m.effSpo2Crit, lowerWorse: true),
  };

  // Worst level; priority on ties: heat/strain, then SpO₂, then HR.
  const order = ['strain', 'temp', 'spo2', 'hr'];
  var worst = 'none';
  var worstLevel = 0;
  for (final k in order) {
    if (levels[k]! > worstLevel) {
      worstLevel = levels[k]!;
      worst = k;
    }
  }

  if (worstLevel == 0) {
    return HealthStatus(
      level: 0,
      title: "You're doing well",
      message: 'All your key signs are within the limits you set. Carry on as normal.',
      actions: const ['Stay hydrated', 'Keep up your normal activity'],
      triggered: 'none',
    );
  }

  final crit = worstLevel >= 3;
  switch (worst) {
    case 'strain':
    case 'temp':
      return HealthStatus(
        level: worstLevel,
        title: crit ? 'Act now — heat strain is critical' : 'Heat strain is building',
        message: crit
            ? 'Your body is overheating for these conditions. Stop and cool down right away.'
            : 'Your body is working harder than usual in this heat. A break now prevents a bigger problem.',
        actions: crit
            ? const ['Get somewhere cool now', 'Drink water', 'Get help if you feel dizzy']
            : const ['Take a shaded break', 'Drink water', 'Slow down'],
        triggered: worst,
      );
    case 'spo2':
      return HealthStatus(
        level: worstLevel,
        title: crit ? 'Low blood oxygen — act now' : 'Blood oxygen dipping',
        message: crit
            ? 'Your oxygen level has dropped below your safe limit. Rest and breathe slowly; seek help if it stays low.'
            : 'Your oxygen level is a little low. Slow down and breathe steadily.',
        actions: crit
            ? const ['Sit down and rest', 'Breathe slowly and deeply', 'Seek medical help if it persists']
            : const ['Ease your activity', 'Move to fresh air'],
        triggered: worst,
      );
    case 'hr':
    default:
      return HealthStatus(
        level: worstLevel,
        title: crit ? 'Heart rate very high' : 'Heart rate elevated',
        message: crit
            ? 'Your heart rate is above your critical limit. Stop, rest and cool down.'
            : 'Your heart is working hard. Ease off and give it a moment to settle.',
        actions: crit
            ? const ['Stop and rest now', 'Cool down and hydrate', 'Get help if it stays high']
            : const ['Slow your pace', 'Take a few deep breaths', 'Sip water'],
        triggered: worst,
      );
  }
}

// ---- Plain-language meanings for otherwise-technical numbers ----------------

({String label, String meaning}) bodyStress(double anomaly0to10) {
  if (anomaly0to10 >= 7) {
    return (
      label: 'High',
      meaning:
          'Your vital signs are behaving unusually together — a sign your body may be under stress. Rest, hydrate, and recheck shortly; get help if you feel unwell.'
    );
  }
  if (anomaly0to10 >= 4) {
    return (
      label: 'Noticeable',
      meaning:
          'An unusual mix of readings for you — could be early stress or exertion. Ease off and keep an eye on how you feel.'
    );
  }
  return (
    label: 'Low',
    meaning: 'Your vital signs are behaving normally together — nothing unusual right now.'
  );
}

({String label, String meaning}) vitalsRiskWord(double p) {
  if (p >= 0.6) {
    return (
      label: 'High',
      meaning: 'Your current vitals suggest you should stop, cool down and drink water.'
    );
  }
  if (p >= 0.4) {
    return (
      label: 'Elevated',
      meaning: 'Keep an eye on how you feel and take it a little easier.'
    );
  }
  return (label: 'Low', meaning: 'Your current vitals look reassuring.');
}

String hrGuidance(double hr, double baseline, double warn) {
  if (hr >= warn) return 'Working hard — slow down, cool off and sip water.';
  if (hr > baseline + 15) return 'A little elevated — ease your pace for a bit.';
  return 'In your normal range — no action needed.';
}

String hrvGuidance(double hrv, double hrv0) {
  if (hrv < hrv0 - 12) {
    return 'Lower than your usual — a sign to prioritise rest, hydration and an early night.';
  }
  if (hrv > hrv0 + 8) return 'Higher than usual — a good recovery sign.';
  return 'Around your normal — recovery looks steady.';
}

String spo2Guidance(double spo2, double warn) {
  if (spo2 <= warn) return 'Low — slow down, breathe deeply, move to fresh air.';
  return 'Healthy oxygen level.';
}

String coreTempGuidance(double temp, double warn) {
  if (temp >= warn) return 'Running hot — cool down and hydrate now.';
  return 'Normal body temperature.';
}
