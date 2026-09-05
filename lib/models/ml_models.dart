import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

/// Parses `assets/data/models.json` (the exact fitted weights the web console
/// reads inline) and reproduces its dependency-free inference:
///   * Isolation Forest anomaly score (Liu, Ting & Zhou 2008),
///   * Random-Forest / Logistic classifiers (`predictProbability`),
///   * Random-Forest / Ridge regressors (`predictValue`).
///
/// Every exported tree is `{f,t,l,r}` for an internal node and `{leaf,v}` /
/// `{leaf,n}` for a terminal — walked identically to the JS in `index.html`.
class MlModels {
  MlModels._(this._root);

  final Map<String, dynamic> _root;

  static Future<MlModels> load() async {
    final text = await rootBundle.loadString('assets/data/models.json');
    final json = jsonDecode(text) as Map<String, dynamic>;
    return MlModels._(json);
  }

  Map<String, dynamic> get isolationForest =>
      _root['isolationForest'] as Map<String, dynamic>;
  Map<String, dynamic> get vitalsRisk =>
      _root['vitalsRisk'] as Map<String, dynamic>;
  Map<String, dynamic> get cardioRisk =>
      _root['cardioRisk'] as Map<String, dynamic>;
  Map<String, dynamic>? get cardioRiskLive =>
      _root['cardioRiskLive'] as Map<String, dynamic>?;
  Map<String, dynamic> get sleepQuality =>
      _root['sleepQuality'] as Map<String, dynamic>;
  Map<String, dynamic> get coreTempConstants =>
      _root['coreTempConstants'] as Map<String, dynamic>;
  Map<String, dynamic> get calibration =>
      _root['calibration'] as Map<String, dynamic>;

  double _num(dynamic v) => (v as num).toDouble();

  // ---- Isolation Forest -------------------------------------------------

  /// Expected-path-length normaliser c(n), same as at export time.
  static double cFactor(num n) {
    if (n <= 1) return 0;
    return 2 * (math.log(n - 1) + 0.5772156649) - 2 * (n - 1) / n;
  }

  double _isoPathLength(Map node, List<double> x, int depth) {
    var cur = node;
    var d = depth;
    // Internal nodes are {f,t,l,r}; terminals carry a `leaf` key (value 1).
    while (cur['leaf'] == null) {
      final f = (cur['f'] as num).toInt();
      final t = (cur['t'] as num).toDouble();
      cur = (x[f] <= t ? cur['l'] : cur['r']) as Map;
      d++;
    }
    return d + cFactor((cur['n'] as num));
  }

  /// s(x) = 2^(-E[h(x)]/c(maxSamples)) — feed personal-baseline z-scores.
  double isoAnomalyScore(List<double> x) {
    final trees = isolationForest['trees'] as List;
    var total = 0.0;
    for (final t in trees) {
      total += _isoPathLength(t as Map, x, 0);
    }
    final eh = total / trees.length;
    return math.pow(2, -eh / _num(isolationForest['cFactor'])).toDouble();
  }

  // ---- Generic forest / linear walk ------------------------------------

  double _walkTreeValue(Map node, List<double> z) {
    var cur = node;
    // Internal nodes are {f,t,l,r}; terminals carry a `leaf` key (value 1).
    while (cur['leaf'] == null) {
      final f = (cur['f'] as num).toInt();
      final t = (cur['t'] as num).toDouble();
      cur = (z[f] <= t ? cur['l'] : cur['r']) as Map;
    }
    return (cur['v'] as num).toDouble();
  }

  double _forestValue(List trees, List<double> z) {
    var total = 0.0;
    for (final t in trees) {
      total += _walkTreeValue(t as Map, z);
    }
    return total / trees.length;
  }

  List<double> _standardize(List<double> raw, Map<String, dynamic> m) {
    final mean = m['mean'] as List;
    final std = m['std'] as List;
    return List<double>.generate(
      raw.length,
      (k) => (raw[k] - _num(mean[k])) / _num(std[k]),
    );
  }

  /// Classifier: probability of the positive class. Reads either exported
  /// shape ("rf" forest, or logistic weights/bias).
  double predictProbability(Map<String, dynamic> m, List<double> raw) {
    final z = _standardize(raw, m);
    if (m['kind'] == 'rf') return _forestValue(m['trees'] as List, z);
    var s = _num(m['bias']);
    final w = m['weights'] as List;
    for (var k = 0; k < z.length; k++) {
      s += _num(w[k]) * z[k];
    }
    return 1 / (1 + math.exp(-s));
  }

  /// Regressor: predicted value, de-standardized back into real units.
  double predictValue(Map<String, dynamic> m, List<double> raw) {
    final z = _standardize(raw, m);
    double rawOut;
    if (m['kind'] == 'rf') {
      rawOut = _forestValue(m['trees'] as List, z);
    } else {
      rawOut = _num(m['bias']);
      final w = m['weights'] as List;
      for (var k = 0; k < z.length; k++) {
        rawOut += _num(w[k]) * z[k];
      }
    }
    return rawOut * _num(m['targetStd']) + _num(m['targetMean']);
  }
}
