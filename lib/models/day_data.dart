import 'dart:math' as math;

import 'ml_models.dart';
import 'profile.dart';

double _clamp(double v, double lo, double hi) => math.max(lo, math.min(hi, v));
double round1(double v) => (v * 10).round() / 10;
double round2(double v) => (v * 100).round() / 100;

String fmtClock(int minute) {
  final hh = minute ~/ 60;
  final mm = minute % 60;
  return '${hh < 10 ? '0' : ''}$hh:${mm < 10 ? '0' : ''}$mm';
}

/// One 5-minute sensor sample, straight from the CSV.
class RawRow {
  RawRow({
    required this.minute,
    required this.time,
    required this.hr,
    required this.spo2,
    required this.skin,
    required this.ambientTemp,
    required this.humidity,
    required this.wbgt,
    required this.pm25,
    required this.exertion,
    required this.sleepStage,
    required this.hrv,
    required this.respRate,
    required this.steps,
    required this.noise,
    required this.lat,
    required this.lon,
  });

  final int minute;
  final String time;
  final double hr;
  final double spo2;
  final double skin;
  final double ambientTemp;
  final double humidity;
  final double wbgt;
  final double pm25;
  final double exertion;
  final String sleepStage;
  final double hrv;
  final double respRate;
  final int steps;
  final double noise;
  final double lat;
  final double lon;
}

List<RawRow> parseCsv(String text) {
  final lines = text.trim().split(RegExp(r'\r?\n'));
  final headers = lines.first.split(',');
  int idx(String name) => headers.indexOf(name);
  final iMinute = idx('minute'),
      iTime = idx('time'),
      iHr = idx('heart_rate_bpm'),
      iSpo2 = idx('spo2_pct'),
      iSkin = idx('skin_temp_c'),
      iAmb = idx('ambient_temp_c'),
      iHum = idx('humidity_pct'),
      iWbgt = idx('wbgt_c'),
      iPm25 = idx('pm25_ugm3'),
      iAct = idx('activity_index'),
      iSleep = idx('sleep_stage'),
      iHrv = idx('hrv_ms'),
      iResp = idx('resp_rate_bpm'),
      iSteps = idx('steps'),
      iNoise = idx('noise_db'),
      iLat = idx('lat'),
      iLon = idx('lon');

  final rows = <RawRow>[];
  for (var i = 1; i < lines.length; i++) {
    final c = lines[i].split(',');
    rows.add(RawRow(
      minute: int.parse(c[iMinute]),
      time: c[iTime],
      hr: double.parse(c[iHr]),
      spo2: double.parse(c[iSpo2]),
      skin: double.parse(c[iSkin]),
      ambientTemp: double.parse(c[iAmb]),
      humidity: double.parse(c[iHum]),
      wbgt: double.parse(c[iWbgt]),
      pm25: double.parse(c[iPm25]),
      exertion: double.parse(c[iAct]),
      sleepStage: c[iSleep],
      hrv: double.parse(c[iHrv]),
      respRate: double.parse(c[iResp]),
      steps: int.parse(c[iSteps]),
      noise: double.parse(c[iNoise]),
      lat: double.parse(c[iLat]),
      lon: double.parse(c[iLon]),
    ));
  }
  return rows;
}

class HealthEvent {
  HealthEvent({
    required this.startMin,
    required this.endMin,
    required this.durationMin,
    required this.severity,
    required this.type,
  });

  final int startMin;
  final int endMin;
  final int durationMin;
  final int severity;
  final String type;
}

int tierOf(double psi, Profile p) {
  if (psi >= p.l3) return 3;
  if (psi >= p.l2) return 2;
  if (psi >= p.l1) return 1;
  return 0;
}

class _Run {
  _Run(this.startIdx, this.endIdx);
  final int startIdx;
  final int endIdx;
  int get startMin => startIdx * kStepMin;
  int get endMin => (endIdx + 1) * kStepMin;
  int get durationMin => (endIdx - startIdx + 1) * kStepMin;
}

List<_Run> _extractRuns(List<bool> arr, int minDwellMin) {
  final runs = <_Run>[];
  int? start;
  for (var i = 0; i < arr.length; i++) {
    final v = arr[i];
    if (v && start == null) start = i;
    final atEnd = i == arr.length - 1;
    if ((!v || atEnd) && start != null) {
      final end = (v && atEnd) ? i : i - 1;
      final dur = (end - start + 1) * kStepMin;
      if (dur >= minDwellMin) runs.add(_Run(start, end));
      start = null;
    }
  }
  return runs;
}

double _skinCoreGradient(
    Map<String, dynamic> ctc, double ambientC, double exertion) {
  double n(String k) => (ctc[k] as num).toDouble();
  final g = n('baselineGradientC') -
      n('ambientNarrowingPerC') * math.max(0, ambientC - n('ambientReferenceC')) +
      n('movementWideningPerLevel') * (exertion * 10);
  return math.max(0.5, g);
}

/// Everything the console shows for one simulated day, computed live from raw
/// CSV rows — mirrors the web console's `computeDay`.
class DayData {
  DayData({
    required this.prof,
    required this.hr,
    required this.spo2,
    required this.skin,
    required this.wbgt,
    required this.ambientTemp,
    required this.humidity,
    required this.pm25,
    required this.exertion,
    required this.sleepStage,
    required this.coreTemp,
    required this.psi,
    required this.tier,
    required this.anomaly,
    required this.vitalsRisk,
    required this.popRisk,
    required this.respiratory,
    required this.events,
    required this.hrv,
    required this.respRate,
    required this.steps,
    required this.noise,
    required this.lat,
    required this.lon,
    required this.stepsCum,
    required this.movingCum,
    required this.heatCum,
    required this.standCum,
    required this.hrExcess,
    required this.pm25DoseCum,
    required this.noiseDoseCum,
    required this.doseHistory,
    required this.acclimHistory,
    required this.cardioLive,
    required this.rhrHistory,
    required this.hourlySteps,
    required this.stats,
  });

  final Profile prof;
  final List<double> hr, spo2, skin, wbgt, ambientTemp, humidity, pm25, exertion;
  final List<String> sleepStage;
  final List<double> coreTemp, psi;
  final List<int> tier;
  final List<double> anomaly, vitalsRisk, popRisk;
  final List<bool> respiratory;
  final List<HealthEvent> events;
  final List<double> hrv, respRate, noise, lat, lon;
  final List<int> steps;
  final List<int> stepsCum, movingCum, heatCum, standCum;
  final List<double> hrExcess, pm25DoseCum, noiseDoseCum;
  final List<DoseDay> doseHistory;
  final List<AcclimDay> acclimHistory;
  final List<double> cardioLive;
  final List<AcclimDay> rhrHistory; // reuses AcclimDay shape: score = resting HR
  final List<int> hourlySteps;
  final DayStats stats;
}

class DayStats {
  DayStats({
    required this.avgHR,
    required this.minHR,
    required this.maxHR,
    required this.activityMinutes,
    required this.heatStressMinutes,
    required this.sleepQuality,
    required this.deepMinutes,
    required this.lightMinutes,
    required this.remMinutes,
    required this.totalSteps,
    required this.avgHRVsleep,
    required this.avgRespSleep,
    required this.heatAdaptScore,
    required this.todayPm25DoseRatio,
    required this.todayNoiseDosePct,
    required this.sleepEfficiency,
    required this.readiness,
    required this.rhrToday,
  });

  final double avgHR;
  final double minHR;
  final double maxHR;
  final int activityMinutes;
  final int heatStressMinutes;
  final int sleepQuality;
  final int deepMinutes;
  final int lightMinutes;
  final int remMinutes;
  final int totalSteps;
  final double avgHRVsleep;
  final double avgRespSleep;
  final double heatAdaptScore;
  final double todayPm25DoseRatio;
  final double todayNoiseDosePct;
  final double sleepEfficiency;
  final int readiness;
  final double rhrToday;
}

/// One day in the 14-day exposure-dose history (13 illustrative + 1 real today).
class DoseDay {
  DoseDay({
    required this.offset,
    required this.pm25Ratio,
    required this.noisePct,
    required this.illustrative,
  });
  final int offset; // days ago (0 = today)
  final double pm25Ratio;
  final double noisePct;
  final bool illustrative;
}

/// One day in the 14-day heat-acclimatization history.
class AcclimDay {
  AcclimDay({required this.offset, required this.score, required this.illustrative});
  final int offset;
  final double score;
  final bool illustrative;
}

DayData computeDay(List<RawRow> raw, Profile prof, MlModels models,
    {String scenarioKey = 'heatwave', double male = 0.5}) {
  final ctc = models.coreTempConstants;
  final coreR = math.pow((ctc['sensorNoiseStd_degC'] as num).toDouble(), 2).toDouble();
  final coreQ = (ctc['processNoiseVar_degC2'] as num).toDouble();
  final shiftHR = prof.hr0 - GenBaseline.hr0;
  final shiftSkin = prof.skin0 - GenBaseline.skin0;

  final hr = <double>[],
      spo2 = <double>[],
      skin = <double>[],
      wbgt = <double>[],
      ambientTemp = <double>[],
      humidity = <double>[],
      pm25 = <double>[],
      exertion = <double>[],
      coreTemp = <double>[],
      psi = <double>[],
      anomaly = <double>[],
      popRisk = <double>[],
      cardioLive = <double>[],
      vitalsRisk = <double>[],
      hrv = <double>[],
      respRate = <double>[],
      noise = <double>[],
      lat = <double>[],
      lon = <double>[],
      hrExcess = <double>[],
      pm25DoseCum = <double>[],
      noiseDoseCum = <double>[];
  var runningPm25Dose = 0.0, runningNoiseDose = 0.0;
  final sleepStage = <String>[];
  final steps = <int>[];
  final tier = <int>[];
  final abnormalHR = <bool>[],
      fatigue = <bool>[],
      dehydration = <bool>[],
      respiratory = <bool>[],
      suddenChange = <bool>[];

  // Population cardiovascular-risk reference: one number per profile.
  final cardioFit = models.cardioRisk;
  final cardioMean = cardioFit['mean'] as List;
  final cardioProb = models.predictProbability(
    cardioFit,
    [prof.cardioAge, (cardioMean[1] as num).toDouble(), prof.cardioBmi],
  );

  final iso = models.isolationForest;
  final isoP50 = (iso['scoreP50'] as num).toDouble();
  final isoP99 = (iso['scoreP99'] as num).toDouble();

  var x = prof.tc0; // core-temp filter state (estimate)
  var p = 0.05; // core-temp filter state (error covariance)
  for (var i = 0; i < kN; i++) {
    final r = raw[i];
    final thisHR = r.hr + shiftHR;
    final thisSkin = r.skin + shiftSkin;
    hr.add(thisHR);
    spo2.add(r.spo2);
    skin.add(thisSkin);
    wbgt.add(r.wbgt);
    ambientTemp.add(r.ambientTemp);
    humidity.add(r.humidity);
    pm25.add(r.pm25);
    exertion.add(r.exertion);
    sleepStage.add(r.sleepStage);
    hrv.add(r.hrv);
    respRate.add(r.respRate);
    steps.add(r.steps);
    noise.add(r.noise);
    lat.add(r.lat);
    lon.add(r.lon);

    // Core temperature: recursive (Kalman-style) filter — x and p carried
    // across timesteps, exactly as in the web console.
    final target = prof.tc0 + CoreTempKp.ke * r.exertion;
    final xPred = x + CoreTempKp.relax * (target - x);
    final pPred = p + coreQ;
    final z = thisSkin + _skinCoreGradient(ctc, r.ambientTemp, r.exertion);
    final k = pPred / (pPred + coreR);
    x = xPred + k * (z - xPred);
    p = (1 - k) * pPred;
    coreTemp.add(x);

    final thisPsi = _clamp(
      5 * (x - prof.tc0) / (39.5 - prof.tc0) +
          5 * (thisHR - prof.hr0) / (180 - prof.hr0),
      0,
      10,
    );
    psi.add(thisPsi);
    tier.add(tierOf(thisPsi, prof));

    // Isolation Forest anomaly, fed personal-baseline z-scores.
    final zHR = (thisHR - prof.hr0) / prof.hr0Std;
    final zRR = (r.respRate - prof.rr0) / prof.rr0Std;
    final zTC = (x - prof.tc0) / prof.tc0Std;
    final zSpO2 = (r.spo2 - prof.spo20) / prof.spo2Std;
    final isoRaw = models.isoAnomalyScore([zHR, zRR, zTC, zSpO2]);
    anomaly.add(_clamp((isoRaw - isoP50) / (isoP99 - isoP50) * 10, 0, 10));

    // Vitals risk classifier (supervised), live signals directly.
    vitalsRisk.add(models.predictProbability(
      models.vitalsRisk,
      [thisHR, r.respRate, x, r.spo2],
    ));
    popRisk.add(cardioProb);

    // Cardiovascular risk (LIVE) — logistic regression that moves with live HR.
    final liveModel = models.cardioRiskLive;
    if (liveModel != null) {
      cardioLive.add(models.predictProbability(
        liveModel,
        [prof.cardioAge, male, prof.cardioBmi, thisHR],
      ));
    } else {
      cardioLive.add(cardioProb);
    }

    final isSleep = r.sleepStage != 'Awake';
    final expectedHR = prof.hr0 + r.exertion * 90;
    abnormalHR.add((thisHR - expectedHR).abs() > 18);
    fatigue.add(!isSleep && r.exertion < 0.2 && zHR > 1.3);
    dehydration.add(thisPsi >= prof.l1 && r.wbgt > 30);
    respiratory.add(r.pm25 > 55 || r.spo2 < 95);
    final dHR = i >= 3 ? (thisHR - hr[i - 3]).abs() : 0.0;
    final dEx = i >= 3 ? (r.exertion - exertion[i - 3]).abs() : 1.0;
    suddenChange.add(i >= 3 && dHR > 22 && dEx < 0.15);

    // Heat-acclimatization signal: HR above what exertion alone predicts.
    hrExcess.add(thisHR - expectedHR);
    // Environmental exposure dose, integrated over time.
    runningPm25Dose += r.pm25 * (kStepMin / 60.0);
    final allowedHoursAtLevel = 8 / math.pow(2, (r.noise - 90) / 5);
    runningNoiseDose += (kStepMin / 60.0) / allowedHoursAtLevel * 100;
    pm25DoseCum.add(runningPm25Dose);
    noiseDoseCum.add(runningNoiseDose);
  }

  // ---- Events -----------------------------------------------------------
  final events = <HealthEvent>[];
  final mask1 = tier.map((v) => v >= 1).toList();
  for (final run in _extractRuns(mask1, 15)) {
    final slice = tier.sublist(run.startIdx, run.endIdx + 1);
    final c2 = slice.where((v) => v >= 2).length * kStepMin;
    final c3 = slice.where((v) => v >= 3).length * kStepMin;
    final sev = c3 >= 5 ? 3 : (c2 >= 10 ? 2 : 1);
    events.add(HealthEvent(
      startMin: run.startMin,
      endMin: run.endMin,
      durationMin: run.durationMin,
      severity: sev,
      type: 'Heat strain',
    ));
  }
  void addRuns(List<bool> arr, int dwell, int sev, String type) {
    for (final run in _extractRuns(arr, dwell)) {
      events.add(HealthEvent(
        startMin: run.startMin,
        endMin: run.endMin,
        durationMin: run.durationMin,
        severity: sev,
        type: type,
      ));
    }
  }

  addRuns(abnormalHR, 10, 1, 'Abnormal HR pattern');
  addRuns(fatigue, 20, 1, 'Fatigue accumulation');
  addRuns(dehydration, 20, 2, 'Dehydration risk');
  addRuns(respiratory, 15, 1, 'Respiratory distress');
  addRuns(suddenChange, 5, 2, 'Sudden change');
  events.sort((a, b) => a.startMin - b.startMin);

  // ---- Stats ------------------------------------------------------------
  final avgHR = hr.reduce((a, b) => a + b) / kN;
  final minHR = hr.reduce(math.min);
  final maxHR = hr.reduce(math.max);
  final activityMinutes = exertion.where((v) => v > 0.3).length * kStepMin;
  final heatStressMinutes = mask1.where((v) => v).length * kStepMin;

  var deepMinutes = 0, lightMinutes = 0, remMinutes = 0;
  for (var s = 0; s < 72; s++) {
    if (sleepStage[s] == 'Deep') {
      deepMinutes += kStepMin;
    } else if (sleepStage[s] == 'Light') {
      lightMinutes += kStepMin;
    } else if (sleepStage[s] == 'REM') {
      remMinutes += kStepMin;
    }
  }

  final sleepHRvals = hr.sublist(0, 72);
  final avgHRsleep = sleepHRvals.reduce((a, b) => a + b) / sleepHRvals.length;
  final sleepDurationHours = (deepMinutes + lightMinutes + remMinutes) / 60.0;
  final sleepQualityRaw = _clamp(
    models.predictValue(models.sleepQuality,
        [sleepDurationHours, avgHRsleep, activityMinutes.toDouble()]),
    0,
    10,
  );
  final sleepQuality = _clamp(sleepQualityRaw * 10, 0, 100).round();

  // Cumulative "so far today" running totals.
  final stepsCum = <int>[], movingCum = <int>[], heatCum = <int>[], standCum = <int>[];
  var runningSteps = 0, runningMoving = 0, runningHeat = 0;
  final standSeen = <int>{};
  for (var j = 0; j < kN; j++) {
    runningSteps += steps[j];
    if (exertion[j] > 0.3) runningMoving += kStepMin;
    if (mask1[j]) runningHeat += kStepMin;
    if (exertion[j] > 0.15 && sleepStage[j] == 'Awake') {
      standSeen.add((j * kStepMin) ~/ 60);
    }
    stepsCum.add(runningSteps);
    movingCum.add(runningMoving);
    heatCum.add(runningHeat);
    standCum.add(standSeen.length);
  }

  final sleepHRVvals = hrv.sublist(0, 72);
  final sleepRespVals = respRate.sublist(0, 72);
  final avgHRVsleep = sleepHRVvals.reduce((a, b) => a + b) / sleepHRVvals.length;
  final avgRespSleep = sleepRespVals.reduce((a, b) => a + b) / sleepRespVals.length;

  // Today's real heat-acclimatization point: mean HR-above-expected while
  // actually under heat exposure (WBGT >= 28°C).
  final heatIdx = <int>[];
  for (var k = 0; k < kN; k++) {
    if (wbgt[k] >= 28) heatIdx.add(k);
  }
  final heatAdaptScore = heatIdx.isEmpty
      ? 0.0
      : heatIdx.map((k) => hrExcess[k]).reduce((a, b) => a + b) / heatIdx.length;

  final todayPm25DoseRatio = pm25DoseCum[kN - 1] / (15 * 24); // vs WHO 24h guideline
  final todayNoiseDosePct = noiseDoseCum[kN - 1];
  final cal = models.calibration;
  final doseHistory = buildDoseHistory(
      cal, scenarioKey, prof.key, todayPm25DoseRatio, todayNoiseDosePct);
  final acclimHistory = buildAcclimHistory(scenarioKey, prof.key, heatAdaptScore);

  // Sleep efficiency: fraction of the ~6h in-bed window actually asleep.
  final inBedMin = 72 * kStepMin;
  final asleepMin = deepMinutes + lightMinutes + remMinutes;
  final sleepEfficiency = inBedMin > 0 ? asleepMin / inBedMin * 100 : 0.0;

  // Resting HR today: minimum HR during the overnight sleep window.
  final rhrToday = hr.sublist(0, 72).reduce(math.min);

  // Readiness (WHOOP/Oura-style transparent composite) — once per day.
  final peakPsi = psi.reduce(math.max);
  final readiness = _clamp(
    _clamp(avgHRVsleep / 100.0, 0, 1) * 35.0 +
        math.max(0, 1 - (rhrToday - 40) / 40) * 25.0 +
        math.max(0, 1 - (avgRespSleep - 10) / 10) * 15.0 +
        (sleepQuality / 100.0) * 25.0 -
        math.max(0, peakPsi - 5.0) * 2.0,
    0,
    100,
  );

  // 14-day resting-HR trend (13 illustrative seeded + today real).
  final rhrHistory = buildRhrHistory(scenarioKey, prof.key, rhrToday, prof.hr0);

  // Hourly step counts (24 buckets) for the activity bar chart.
  final hourlySteps = List<int>.filled(24, 0);
  for (var k = 0; k < kN; k++) {
    hourlySteps[(k * kStepMin) ~/ 60] += steps[k];
  }

  return DayData(
    prof: prof,
    hr: hr,
    spo2: spo2,
    skin: skin,
    wbgt: wbgt,
    ambientTemp: ambientTemp,
    humidity: humidity,
    pm25: pm25,
    exertion: exertion,
    sleepStage: sleepStage,
    coreTemp: coreTemp,
    psi: psi,
    tier: tier,
    anomaly: anomaly,
    vitalsRisk: vitalsRisk,
    popRisk: popRisk,
    respiratory: respiratory,
    events: events,
    hrv: hrv,
    respRate: respRate,
    steps: steps,
    noise: noise,
    lat: lat,
    lon: lon,
    stepsCum: stepsCum,
    movingCum: movingCum,
    heatCum: heatCum,
    standCum: standCum,
    hrExcess: hrExcess,
    pm25DoseCum: pm25DoseCum,
    noiseDoseCum: noiseDoseCum,
    doseHistory: doseHistory,
    acclimHistory: acclimHistory,
    cardioLive: cardioLive,
    rhrHistory: rhrHistory,
    hourlySteps: hourlySteps,
    stats: DayStats(
      avgHR: avgHR,
      minHR: minHR,
      maxHR: maxHR,
      activityMinutes: activityMinutes,
      heatStressMinutes: heatStressMinutes,
      sleepQuality: sleepQuality,
      deepMinutes: deepMinutes,
      lightMinutes: lightMinutes,
      remMinutes: remMinutes,
      totalSteps: runningSteps,
      avgHRVsleep: avgHRVsleep,
      avgRespSleep: avgRespSleep,
      heatAdaptScore: heatAdaptScore,
      todayPm25DoseRatio: todayPm25DoseRatio,
      todayNoiseDosePct: todayNoiseDosePct,
      sleepEfficiency: sleepEfficiency,
      readiness: readiness.round(),
      rhrToday: rhrToday,
    ),
  );
}

// ---- Derived, cursor-dependent read-outs --------------------------------

class ActivitySnapshot {
  ActivitySnapshot({
    required this.stepsSoFar,
    required this.exerciseMin,
    required this.heatMin,
    required this.standHours,
    required this.activeCalories,
    required this.hydrationTarget,
  });

  final int stepsSoFar;
  final int exerciseMin;
  final int heatMin;
  final int standHours;
  final int activeCalories;
  final int hydrationTarget;
}

ActivitySnapshot computeActivity(int i, DayData day) {
  final stepsSoFar = day.stepsCum[i];
  final exerciseMin = day.movingCum[i];
  final heatMin = day.heatCum[i];
  final activeCalories = (stepsSoFar * 0.045 + exerciseMin * 0.35).round();
  final hydrationTarget =
      _clamp((6 + (heatMin ~/ 45) + (exerciseMin ~/ 40)).toDouble(), 6, 14).round();
  return ActivitySnapshot(
    stepsSoFar: stepsSoFar,
    exerciseMin: exerciseMin,
    heatMin: heatMin,
    standHours: day.standCum[i],
    activeCalories: activeCalories,
    hydrationTarget: hydrationTarget,
  );
}

class HeroAction {
  const HeroAction(this.icon, this.text);
  final String icon;
  final String text;
}

class HeroInfo {
  const HeroInfo(this.sev, this.headline, this.body, this.actions);
  final int sev; // 0 ok, 1 advisory, 2 warning, 3 critical
  final String headline;
  final String body;
  final List<HeroAction> actions;
}

HeroInfo computeHero(int i, DayData day, Profile prof) {
  final tier = day.tier[i];
  final wbgt = day.wbgt[i];
  final respBad = day.respiratory[i];
  final sleepQ = day.stats.sleepQuality;
  final morning = (i * kStepMin) < 600;
  if (tier >= 3) {
    return const HeroInfo(3, 'Act now — heat strain is critical',
        "Your strain score is very high for these conditions. Stop what you're doing and cool down right away.", [
      HeroAction('home', 'Get somewhere cool immediately'),
      HeroAction('drop', 'Drink water now'),
      HeroAction('heart', 'Seek medical help if you feel dizzy or unwell'),
    ]);
  }
  if (tier >= 2) {
    return HeroInfo(2, 'Take it easy — strain is building',
        'Your body is working harder than usual in this heat. A break now helps avoid a bigger problem later.', [
      const HeroAction('umbrella', 'Take a shaded break'),
      const HeroAction('drop', 'Drink water'),
      HeroAction('home', wbgt >= 32 ? 'Consider heading indoors' : 'Slow down your activity'),
    ]);
  }
  if (tier >= 1 || wbgt >= 30) {
    return const HeroInfo(1, 'Getting warm — plan ahead',
        'Conditions are heating up. A short break now can prevent strain later.', [
      HeroAction('drop', 'Carry water with you'),
      HeroAction('umbrella', 'Carry an umbrella or hat for shade'),
      HeroAction('heart', 'Watch for tiredness or headache'),
    ]);
  }
  if (respBad) {
    return const HeroInfo(1, 'Air quality is poor right now',
        'Breathing may feel a little harder than usual outdoors.', [
      HeroAction('mask', 'Wear a mask outdoors'),
      HeroAction('home', 'Limit strenuous activity outside'),
      HeroAction('drop', 'Stay hydrated'),
    ]);
  }
  if (sleepQ < 55 && morning) {
    return const HeroInfo(1, "You didn't sleep well last night",
        'Your deep-sleep time was below usual last night — take it a little easier today.', [
      HeroAction('moon', 'Consider an early night tonight'),
      HeroAction('drop', 'Stay hydrated'),
      HeroAction('home', 'Pace yourself today'),
    ]);
  }
  return const HeroInfo(0, "You're doing fine",
      'No unusual strain detected. Conditions are comfortable right now.', [
    HeroAction('drop', 'Stay hydrated as usual'),
    HeroAction('check', 'Keep up your normal activity'),
    HeroAction('check', 'No action needed'),
  ]);
}

String _tempWord(double wbgt) =>
    wbgt >= 32 ? 'very hot' : wbgt >= 28 ? 'warm' : wbgt >= 22 ? 'mild' : 'cool';
String aqWord(double pm) =>
    pm > 90 ? 'severe' : pm > 55 ? 'unhealthy' : pm > 35 ? 'moderate' : 'good';

class EnvInfo {
  const EnvInfo(this.desc, this.measures);
  final String desc;
  final List<HeroAction> measures;
}

EnvInfo computeEnvironment(int i, DayData day) {
  final wbgt = day.wbgt[i];
  final ambientTemp = day.ambientTemp[i];
  final humidity = day.humidity[i];
  final pm = day.pm25[i];
  final tier = day.tier[i];
  final noise = day.noise[i];
  var desc = "It's ${_tempWord(wbgt)}${humidity >= 65 ? ' and humid' : ''} "
      "outside — about ${round1(ambientTemp)}°C.";
  if (pm > 35) desc += ' Air quality is ${aqWord(pm)}.';
  final measures = <HeroAction>[];
  if (wbgt >= 28) {
    measures.add(const HeroAction('drop', 'Carry water with you'));
    measures.add(const HeroAction('umbrella', 'Carry an umbrella or hat for sun protection'));
  }
  if (wbgt >= 32) measures.add(const HeroAction('home', 'Avoid direct sun 12–4pm'));
  if (pm > 55) measures.add(const HeroAction('mask', 'Wear a mask outdoors'));
  if (tier >= 2 && wbgt >= 32) {
    measures.add(const HeroAction('home', "Stay indoors if you can, given how you're feeling"));
  }
  if (noise >= 65) {
    measures.add(const HeroAction('waves', "It's noisy around you — consider ear protection if you're out for a while"));
  }
  if (measures.isEmpty) {
    measures.add(const HeroAction('check', 'Conditions are comfortable — no special precautions needed'));
  }
  return EnvInfo(desc, measures.take(3).toList());
}

class RecoveryInfo {
  const RecoveryInfo(this.icon, this.text);
  final String icon;
  final String text;
}

RecoveryInfo computeRecovery(DayData day, Profile prof) {
  final hrv = day.stats.avgHRVsleep;
  final resp = day.stats.avgRespSleep;
  final hrvLow = prof.hrv0 - 12;
  const respHigh = 18.5;
  if (hrv < hrvLow && resp > respHigh) {
    return const RecoveryInfo('heart',
        'Lower heart-rate variability and a faster breathing rate than usual overnight — consider an easier day and some extra rest.');
  }
  if (hrv < hrvLow) {
    return RecoveryInfo('heart',
        'Overnight HRV (${hrv.round()} ms) was a little lower than your usual range — nothing urgent, but ease into today.');
  }
  if (resp > respHigh) {
    return RecoveryInfo('heart',
        'Breathing rate overnight (${resp.toStringAsFixed(1)} breaths/min) was a touch higher than usual — worth keeping an eye on.');
  }
  return RecoveryInfo('check',
      'Overnight HRV (${hrv.round()} ms) and breathing rate (${resp.toStringAsFixed(1)} breaths/min) were both within your typical range.');
}

const Map<String, Map<int, String>> _eventCopy = {
  'Heat strain': {
    1: 'Getting warm — advised a shade break',
    2: 'Heat strain building — urged to cool down',
    3: 'Critical heat strain — immediate action advised',
  },
  'Abnormal HR pattern': {1: 'Unusual heart-rate pattern noticed'},
  'Fatigue accumulation': {1: 'Signs of tiredness without much activity'},
  'Dehydration risk': {2: 'Possible dehydration risk'},
  'Respiratory distress': {1: 'Air quality affecting breathing'},
  'Sudden change': {2: 'Sudden heart-rate change detected'},
};

String eventText(HealthEvent e) {
  final m = _eventCopy[e.type];
  return (m?[e.severity] ?? m?[1]) ?? e.type;
}

// ---- Deterministic seeded PRNG (mulberry32) for illustrative history --------

int _hashSeed(String s) {
  var h = 0;
  for (var i = 0; i < s.length; i++) {
    h = (0x1fffffff & (31 * h + s.codeUnitAt(i)));
  }
  return h;
}

double Function() _mulberry32(int seed) {
  var s = seed & 0xFFFFFFFF;
  return () {
    s = (s + 0x6D2B79F5) & 0xFFFFFFFF;
    final t0 = ((s ^ (s >>> 15)) * (1 | s)) & 0xFFFFFFFF;
    var t = (t0 + (((t0 ^ (t0 >>> 7)) * (61 | t0)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    t = t ^ t0;
    return ((t ^ (t >>> 14)) & 0xFFFFFFFF) / 4294967296.0;
  };
}

/// 14-day exposure-dose history: days 0..12 illustrative (seeded, bounded by
/// this build's real calibration stats), day 13 (today) is the real value.
List<DoseDay> buildDoseHistory(Map<String, dynamic> cal, String scenarioKey,
    String profileKey, double todayPm25Ratio, double todayNoisePct) {
  double c(String k) => (cal[k] as num).toDouble();
  final rng = _mulberry32(_hashSeed('dose:$scenarioKey:$profileKey'));
  final days = <DoseDay>[];
  for (var i = 0; i < 14; i++) {
    final spike = rng() < 0.15;
    final pm25 = spike
        ? c('pm25P95') * (0.7 + 0.3 * rng())
        : c('pm25CleanMedian') * 0.5 +
            (c('pm25PoorP75') - c('pm25CleanMedian') * 0.5) * rng();
    final pm25Ratio = _clamp(pm25 / 15, 0.1, 4.5);
    final noiseLevel = c('noiseDayMedianDb') + (rng() - 0.5) * 14;
    final noisePct =
        _clamp(math.pow(2, (noiseLevel - 90) / 5) * 100 * (0.4 + 0.6 * rng()), 3, 145)
            .toDouble();
    days.add(DoseDay(
        offset: 13 - i, pm25Ratio: pm25Ratio, noisePct: noisePct, illustrative: true));
  }
  days[13] = DoseDay(
      offset: 0,
      pm25Ratio: todayPm25Ratio,
      noisePct: todayNoisePct,
      illustrative: false);
  return days;
}

/// 14-day heat-acclimatization history: 13 illustrative (seeded to trend down =
/// adaptation), day 13 (today) is the real value.
List<AcclimDay> buildAcclimHistory(
    String scenarioKey, String profileKey, double todayScore) {
  final rng = _mulberry32(_hashSeed('acclim:$scenarioKey:$profileKey'));
  final slow = profileKey == 'vulnerable';
  final start = 9 + rng() * 3;
  final floor = slow ? 3.5 : 1.5;
  final days = <AcclimDay>[];
  for (var i = 0; i < 13; i++) {
    final progress = i / 12;
    final v = start -
        (start - floor) * math.pow(progress, slow ? 0.7 : 1.1) +
        (rng() - 0.5) * 1.6;
    days.add(AcclimDay(offset: 12 - i, score: v.toDouble(), illustrative: true));
  }
  days.add(AcclimDay(offset: 0, score: todayScore, illustrative: false));
  return days;
}

/// 14-day resting-HR trend: 13 illustrative (seeded, autoregressive drift around
/// the personal baseline) + today's real value. A rising trend without extra
/// activity is a classic early-illness / overtraining signal.
List<AcclimDay> buildRhrHistory(
    String scenarioKey, String profileKey, double todayRhr, double baseline) {
  final rng = _mulberry32(_hashSeed('rhr:$scenarioKey:$profileKey'));
  final days = <AcclimDay>[];
  var v = baseline - 4 + rng() * 3; // resting HR sits a little below waking HR0
  for (var i = 0; i < 13; i++) {
    // autoregressive drift so illustrative runs wander realistically
    v += (rng() - 0.5) * 2.4;
    v = _clamp(v, baseline - 10, baseline + 8);
    days.add(AcclimDay(offset: 13 - i, score: v, illustrative: true));
  }
  days.add(AcclimDay(offset: 0, score: todayRhr, illustrative: false));
  return days;
}

// ---- Ablation-based risk attribution ("Why this risk score, right now") -----

class RiskContribution {
  RiskContribution(this.feature, this.label, this.contribution);
  final String feature; // HR / RR / TEMP / SPO2
  final String label; // human label
  final double contribution; // fullProb - swappedProb
}

class RiskAttribution {
  RiskAttribution(this.fullProb, this.baselineProb, this.contributions);
  final double fullProb;
  final double baselineProb;
  final List<RiskContribution> contributions;
}

const Map<String, String> _riskFeatureLabels = {
  'HR': 'Heart rate',
  'RR': 'Breathing rate',
  'TEMP': 'Core temp',
  'SPO2': 'SpO₂',
};

/// Per-feature ablation: how much swapping one live signal back to its personal
/// baseline changes the vitals-risk probability, holding the others live.
RiskAttribution attributeRisk(int i, DayData day, MlModels models) {
  final prof = day.prof;
  final live = <double>[day.hr[i], day.respRate[i], day.coreTemp[i], day.spo2[i]];
  final baseline = <double>[prof.hr0, prof.rr0, prof.tc0, prof.spo20];
  final fullProb = models.predictProbability(models.vitalsRisk, live);
  final features = (models.vitalsRisk['features'] as List).cast<String>();
  final contribs = <RiskContribution>[];
  for (var k = 0; k < features.length; k++) {
    final swapped = List<double>.from(live);
    swapped[k] = baseline[k];
    final swappedProb = models.predictProbability(models.vitalsRisk, swapped);
    contribs.add(RiskContribution(
      features[k],
      _riskFeatureLabels[features[k]] ?? features[k],
      fullProb - swappedProb,
    ));
  }
  final baselineProb = models.predictProbability(models.vitalsRisk, baseline);
  return RiskAttribution(fullProb, baselineProb, contribs);
}
