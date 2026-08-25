import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

import '../models/day_data.dart';
import '../models/medical_profile.dart';
import '../models/ml_models.dart';
import '../models/profile.dart';

/// Holds all demo controls, the wearer's medical profile, and the computed day,
/// and notifies listeners on any change.
class ConsoleState extends ChangeNotifier {
  // Demo controls.
  String scenario = 'heatwave'; // 'normal' | 'heatwave'
  bool network = true; // online / offline (map tiles)
  int cursor = 156; // sample index 0..287 (156 = 13:00)
  bool playing = false;
  int waterGlasses = 0;

  // The wearer — drives the effective alert thresholds.
  MedicalProfile medical = const MedicalProfile();

  bool loading = true;
  Object? loadError;

  MlModels? _models;
  final Map<String, List<RawRow>> _raw = {};
  final Map<String, DayData> _dayCache = {};
  Timer? _timer;

  /// The effective wearer profile the pipeline runs on.
  Profile get profile => medical.effectiveProfile();

  MlModels? get models => _models;

  DayData? get day {
    if (_models == null) return null;
    final key = '$scenario/${medical.signature}';
    return _dayCache[key] ??=
        computeDay(_raw[scenario]!, profile, _models!, scenarioKey: scenario);
  }

  int get cursorMinute => cursor * kStepMin;
  String get cursorClock => fmtClock(cursorMinute);

  Future<void> load() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/data/day_normal.csv'),
        rootBundle.loadString('assets/data/day_heatwave.csv'),
        MlModels.load(),
      ]);
      _raw['normal'] = parseCsv(results[0] as String);
      _raw['heatwave'] = parseCsv(results[1] as String);
      _models = results[2] as MlModels;
      loading = false;
    } catch (e) {
      loadError = e;
      loading = false;
    }
    notifyListeners();
  }

  void setScenario(String s) {
    if (s == scenario) return;
    scenario = s;
    waterGlasses = 0;
    notifyListeners();
  }

  void setMedical(MedicalProfile m) {
    medical = m;
    _dayCache.clear(); // thresholds changed → recompute on next access
    notifyListeners();
  }

  void setAge(int age) => setMedical(medical.copyWith(age: age));
  void setGender(Gender g) => setMedical(medical.copyWith(gender: g));
  void setHeight(double cm) => setMedical(medical.copyWith(heightCm: cm));
  void setWeight(double kg) => setMedical(medical.copyWith(weightKg: kg));
  void toggleCondition(MedicalCondition c) => setMedical(medical.toggle(c));

  void setNetwork(bool online) {
    if (online == network) return;
    network = online;
    notifyListeners();
  }

  void setCursor(int i) {
    final clamped = i.clamp(0, kN - 1);
    if (clamped == cursor) return;
    cursor = clamped;
    notifyListeners();
  }

  void addGlass() {
    waterGlasses++;
    notifyListeners();
  }

  void resetWater() {
    waterGlasses = 0;
    notifyListeners();
  }

  void togglePlay() {
    playing ? pause() : play();
  }

  void play() {
    if (playing) return;
    playing = true;
    // If at the end, restart from midnight.
    if (cursor >= kN - 1) cursor = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (cursor >= kN - 1) {
        pause();
        return;
      }
      cursor++;
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    if (!playing) return;
    playing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Makes [ConsoleState] available to the subtree and rebuilds dependents when
/// it notifies. `ConsoleScope.of(context)` reads it.
class ConsoleScope extends InheritedNotifier<ConsoleState> {
  const ConsoleScope({
    super.key,
    required ConsoleState state,
    required super.child,
  }) : super(notifier: state);

  static ConsoleState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ConsoleScope>();
    assert(scope != null, 'No ConsoleScope found in context');
    return scope!.notifier!;
  }
}
