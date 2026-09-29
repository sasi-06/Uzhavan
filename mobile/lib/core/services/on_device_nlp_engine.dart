import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Prediction result from the On-Device Neural NLP model.
class NlpPrediction {
  const NlpPrediction({
    required this.intent,
    required this.confidence,
    required this.slots,
    this.isNeural = false,
  });

  final String intent;
  final double confidence;
  final Map<String, dynamic> slots;
  final bool isNeural;

  String? get machineType => slots['machineType'] as String?;
  double? get areaAcres => slots['areaAcres'] as double?;
  DateTime? get preferredDate => slots['preferredDate'] as DateTime?;
  int? get ownerIndex => slots['ownerIndex'] as int?;

  @override
  String toString() =>
      'NlpPrediction(intent: $intent, confidence: ${(confidence * 100).toStringAsFixed(1)}%, slots: $slots, neural: $isNeural)';
}

/// Uzhavan On-Device Neural NLP Engine.
/// Runs a custom-trained Multilayer Perceptron (MLP) Neural Network 100% locally on the device.
/// 0 external APIs, 0 cloud server calls, 0 network latency, 100% offline capable.
class OnDeviceNlpEngine {
  OnDeviceNlpEngine._();
  static final OnDeviceNlpEngine instance = OnDeviceNlpEngine._();

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Map<String, int> _vocab = {};
  List<double> _idf = [];
  List<String> _classes = [];
  List<List<double>> _w1 = []; // [n_features, 64]
  List<double> _b1 = [];       // [64]
  List<List<double>> _w2 = []; // [64, n_classes]
  List<double> _b2 = [];       // [n_classes]
  int _nFeatures = 0;
  int _nHidden = 64;

  /// Loads the trained neural network weights and vocabulary from local assets.
  Future<bool> loadModel({String assetPath = 'assets/models/uzhavan_ai_model.json'}) async {
    if (_isLoaded) return true;
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final data = json.decode(jsonString) as Map<String, dynamic>;

      _nFeatures = data['n_features'] as int? ?? 1200;
      _nHidden = data['n_hidden'] as int? ?? 64;
      _classes = List<String>.from(data['classes'] as List);

      // Load vocabulary
      final rawVocab = data['vocabulary'] as Map<String, dynamic>;
      _vocab = rawVocab.map((k, v) => MapEntry(k, (v as num).toInt()));

      // Load IDF
      _idf = (data['idf'] as List).map((v) => (v as num).toDouble()).toList();

      // Load Layer 1 weights & bias
      _w1 = (data['weights_layer_1'] as List)
          .map((row) => (row as List).map((v) => (v as num).toDouble()).toList())
          .toList();
      _b1 = (data['bias_layer_1'] as List).map((v) => (v as num).toDouble()).toList();

      // Load Layer 2 weights & bias
      _w2 = (data['weights_layer_2'] as List)
          .map((row) => (row as List).map((v) => (v as num).toDouble()).toList())
          .toList();
      _b2 = (data['bias_layer_2'] as List).map((v) => (v as num).toDouble()).toList();

      _isLoaded = true;
      debugPrint('⚡ [OnDeviceNlpEngine] Successfully loaded offline neural model (${_classes.length} classes, $_nFeatures features)');
      return true;
    } catch (e) {
      debugPrint('⚠️ [OnDeviceNlpEngine] Failed to load neural model asset: $e');
      return false;
    }
  }

  /// Evaluates input text through the on-device neural network and extracts slot entities.
  NlpPrediction predict(String text) {
    final cleanText = text.trim().toLowerCase();
    if (cleanText.isEmpty) {
      return const NlpPrediction(intent: 'unknown', confidence: 0.0, slots: {});
    }

    // Always run slot/entity extraction
    final slots = extractSlots(text);

    // If neural model is loaded, run mathematical forward pass
    if (_isLoaded && _vocab.isNotEmpty) {
      final neuralResult = _runForwardPass(cleanText);
      if (neuralResult != null) {
        return NlpPrediction(
          intent: neuralResult.key,
          confidence: neuralResult.value,
          slots: slots,
          isNeural: true,
        );
      }
    }

    // Fallback heuristic inference if model is not yet loaded
    final fallbackIntent = _heuristicFallback(cleanText, slots);
    return NlpPrediction(
      intent: fallbackIntent,
      confidence: 0.75,
      slots: slots,
      isNeural: false,
    );
  }

  /// Runs tokenization, TF-IDF vectorization, and 2-layer Neural MLP forward pass.
  MapEntry<String, double>? _runForwardPass(String text) {
    // 1. Tokenize into words and bigrams
    final words = text.split(RegExp(r'[\s,\.!?]+')).where((w) => w.isNotEmpty).toList();
    final tokens = <String>[];
    for (var i = 0; i < words.length; i++) {
      tokens.add(words[i]);
      if (i + 1 < words.length) {
        tokens.add('${words[i]} ${words[i + 1]}');
      }
    }

    // 2. Count term frequencies for vocabulary matches
    final tfMap = <int, int>{};
    for (final tok in tokens) {
      final idx = _vocab[tok];
      if (idx != null && idx < _nFeatures) {
        tfMap[idx] = (tfMap[idx] ?? 0) + 1;
      }
    }

    if (tfMap.isEmpty) return null;

    // 3. Compute TF-IDF sparse vector with sublinear tf: 1 + ln(count)
    final xSparse = <int, double>{};
    double normSq = 0.0;
    tfMap.forEach((idx, count) {
      final tf = 1.0 + math.log(count);
      final idf = (idx < _idf.length) ? _idf[idx] : 1.0;
      final val = tf * idf;
      xSparse[idx] = val;
      normSq += val * val;
    });

    // L2 normalize
    final norm = math.sqrt(normSq);
    if (norm > 0) {
      xSparse.updateAll((idx, val) => val / norm);
    }

    // 4. Hidden Layer: h = ReLU(W1 * x + b1)
    final h = List<double>.filled(_nHidden, 0.0);
    for (var j = 0; j < _nHidden; j++) {
      double sum = (j < _b1.length) ? _b1[j] : 0.0;
      xSparse.forEach((idx, val) {
        if (idx < _w1.length && j < _w1[idx].length) {
          sum += val * _w1[idx][j];
        }
      });
      h[j] = math.max(0.0, sum); // ReLU activation
    }

    // 5. Output Layer: z = W2 * h + b2
    final nClasses = _classes.length;
    final z = List<double>.filled(nClasses, 0.0);
    for (var k = 0; k < nClasses; k++) {
      double sum = (k < _b2.length) ? _b2[k] : 0.0;
      for (var j = 0; j < _nHidden; j++) {
        if (j < _w2.length && k < _w2[j].length) {
          sum += h[j] * _w2[j][k];
        }
      }
      z[k] = sum;
    }

    // 6. Softmax Probabilities: p_k = exp(z_k - max_z) / sum(exp)
    double maxZ = z[0];
    for (var val in z) {
      if (val > maxZ) maxZ = val;
    }

    double sumExp = 0.0;
    final expZ = List<double>.filled(nClasses, 0.0);
    for (var k = 0; k < nClasses; k++) {
      final e = math.exp(z[k] - maxZ);
      expZ[k] = e;
      sumExp += e;
    }

    // 7. Find top class
    int bestIdx = 0;
    double bestProb = 0.0;
    if (sumExp > 0) {
      for (var k = 0; k < nClasses; k++) {
        final p = expZ[k] / sumExp;
        if (p > bestProb) {
          bestProb = p;
          bestIdx = k;
        }
      }
    }

    if (bestIdx < _classes.length) {
      return MapEntry(_classes[bestIdx], bestProb);
    }
    return null;
  }

  /// Named Entity Recognition (NER) & Slot Extraction for Tamil, Tanglish, Telugu, Hindi, and English.
  Map<String, dynamic> extractSlots(String text) {
    final lower = text.toLowerCase().trim();
    final slots = <String, dynamic>{};

    // ── 1. Machine Type Extraction ──
    if (_containsAny(lower, ['டிராக்டர்', 'tractor', 'traktor', 'ట్రాక్టర్', 'ट्रैक्टर'])) {
      slots['machineType'] = 'tractor';
    } else if (_containsAny(lower, ['அறுவடை', 'harvester', 'harvest', 'హార్వెస్టర్', 'हार्वेस्टर'])) {
      slots['machineType'] = 'harvester';
    } else if (_containsAny(lower, ['தெளிப்பான்', 'sprayer', 'spray', 'స్ప్రేయర్', 'स्प्रेयर'])) {
      slots['machineType'] = 'sprayer';
    } else if (_containsAny(lower, ['விதைப்பான்', 'seeder', 'seed drill', 'సీడర్', 'सीडर'])) {
      slots['machineType'] = 'seeder';
    } else if (_containsAny(lower, ['ரோட்டவேட்டர்', 'rotavator', 'rotovator', 'రోటావేటర్', 'रोटावेटर'])) {
      slots['machineType'] = 'rotavator';
    } else if (_containsAny(lower, ['கலப்பை', 'plough', 'plow', 'நாగలి', 'हल'])) {
      slots['machineType'] = 'plough';
    }

    // ── 2. Area Extraction ──
    double? acres;
    // Word numbers in Tamil
    if (lower.contains('ஒரு') || lower.contains('1')) acres = 1.0;
    if (lower.contains('இரண்டு') || lower.contains('ரெண்டு') || lower.contains('2')) acres = 2.0;
    if (lower.contains('மூன்று') || lower.contains('மூணு') || lower.contains('3')) acres = 3.0;
    if (lower.contains('நான்கு') || lower.contains('நாலு') || lower.contains('4')) acres = 4.0;
    if (lower.contains('ஐந்து') || lower.contains('அஞ்சு') || lower.contains('5')) acres = 5.0;
    if (lower.contains('பத்து') || lower.contains('10')) acres = 10.0;

    // Numerical extraction: e.g. "2.5 acre", "3 ஏக்கர்", "5 एकड़"
    final areaMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(ஏக்கர்|எகரம்|एकड़|acre|acres|சென்ட்|cent)?').firstMatch(lower);
    if (areaMatch != null) {
      final parsed = double.tryParse(areaMatch.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        if (lower.contains('சென்ட்') || lower.contains('cent')) {
          acres = parsed / 100.0; // 100 cents = 1 acre
        } else {
          acres = parsed;
        }
      }
    }
    if (acres != null) slots['areaAcres'] = acres;

    // ── 3. Date Extraction ──
    final now = DateTime.now();
    if (_containsAny(lower, ['இன்று', 'இன்றே', 'today', 'ఈ రోజు', 'आज', 'innikku'])) {
      slots['preferredDate'] = now;
    } else if (_containsAny(lower, ['நாளை', 'tomorrow', 'ரேపు', 'कल', 'naalaikku'])) {
      slots['preferredDate'] = now.add(const Duration(days: 1));
    } else if (_containsAny(lower, ['மறுநாள்', 'day after tomorrow', 'ఎల్లుండి', 'परसों'])) {
      slots['preferredDate'] = now.add(const Duration(days: 2));
    } else if (_containsAny(lower, ['2 நாள்', '2 days', '2 రోజుల్లో', 'दो दिन'])) {
      slots['preferredDate'] = now.add(const Duration(days: 2));
    } else if (_containsAny(lower, ['வாரம்', 'week', 'వారం', 'हफ्ते'])) {
      slots['preferredDate'] = now.add(const Duration(days: 3));
    }

    // ── 4. Owner Selection Index ──
    if (_containsAny(lower, ['மூன்றாவது', 'third', '3rd', 'மூడవ', 'तीसरा', 'moonavathu']) ||
        lower == '3' || lower == 'three') {
      slots['ownerIndex'] = 2;
    } else if (_containsAny(lower, ['இரண்டாவது', 'second', '2nd', 'రెండవ', 'दूसरा', 'rendavathu']) ||
        lower == '2' || lower == 'two') {
      slots['ownerIndex'] = 1;
    } else if (_containsAny(lower, ['முதல்', 'first', '1st', 'மొదటి', 'पहला', 'muthal']) ||
        lower == '1' || lower == 'one') {
      slots['ownerIndex'] = 0;
    }

    return slots;
  }

  String _heuristicFallback(String lower, Map<String, dynamic> slots) {
    if (slots.containsKey('machineType')) return 'book_${slots['machineType']}';
    if (slots.containsKey('areaAcres')) return 'specify_area';
    if (slots.containsKey('preferredDate')) return 'specify_date';
    if (_containsAny(lower, ['ஆம்', 'சரி', 'yes', 'confirm', 'அனுப்பு', 'ok', 'అవును', 'हाँ'])) {
      return 'confirm_booking';
    }
    if (_containsAny(lower, ['வேண்டாம்', 'no', 'cancel', 'ரத்து', 'வద్దు', 'नहीं'])) {
      return 'cancel_booking';
    }
    if (_containsAny(lower, ['வணக்கம்', 'hello', 'hi', 'ஹலோ', 'నమస్కారం', 'नमस्ते'])) {
      return 'greeting';
    }
    return 'unknown';
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
