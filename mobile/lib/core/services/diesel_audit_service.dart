import 'dart:math' as math;

/// Represents standard soil types in rural Indian agriculture.
enum SoilCondition {
  redLoam(
    key: 'red_loam',
    labelTa: 'செம்மண் / சாதாரண மண்',
    labelEn: 'Red / Loam Soil',
    resistanceFactor: 1.0,
  ),
  blackClay(
    key: 'black_clay',
    labelTa: 'கரிசல் மண் (கடின நிலம்)',
    labelEn: 'Black Cotton / Clay Soil',
    resistanceFactor: 1.20,
  ),
  wetPuddled(
    key: 'wet_puddled',
    labelTa: 'சேற்று உழவு (ஈரமான நிலம்)',
    labelEn: 'Wet Puddled / Slush Land',
    resistanceFactor: 1.25,
  ),
  sandy(
    key: 'sandy',
    labelTa: 'மணல் மண் (இலகுவான மண்)',
    labelEn: 'Sandy / Light Soil',
    resistanceFactor: 0.85,
  );

  const SoilCondition({
    required this.key,
    required this.labelTa,
    required this.labelEn,
    required this.resistanceFactor,
  });

  final String key;
  final String labelTa;
  final String labelEn;
  final double resistanceFactor;
}

/// Common tractor implement types with agricultural specific fuel consumption rates.
enum FarmImplementType {
  rotavator(
    key: 'rotavator',
    labelTa: 'ரோட்டாவேட்டர் (Rotavator)',
    labelEn: 'Rotavator',
    loadFactor: 0.100, // L / HP / hour (Heavy PTO load)
  ),
  cultivator(
    key: 'cultivator',
    labelTa: '9-கொழு கலப்பை (Cultivator)',
    labelEn: '9-Tyne Cultivator',
    loadFactor: 0.080, // Medium draft load
  ),
  plough(
    key: 'plough',
    labelTa: 'இரும்பு ஏர்க்கலப்பை (MB Plough)',
    labelEn: 'Disc / MB Plough',
    loadFactor: 0.115, // Very heavy draft load
  ),
  trailer(
    key: 'trailer',
    labelTa: 'டிரெய்லர் / பெட்டி (Haulage)',
    labelEn: 'Trailer / Transport',
    loadFactor: 0.055, // Light road/transport load
  ),
  harvester(
    key: 'harvester',
    labelTa: 'அறுவடை எந்திரம் (Combine Harvester)',
    labelEn: 'Combine Harvester',
    loadFactor: 0.130, // High constant power
  ),
  general(
    key: 'general',
    labelTa: 'பொதுவான உழவு / பிற வேலைகள்',
    labelEn: 'General / Other Implement',
    loadFactor: 0.085,
  );

  const FarmImplementType({
    required this.key,
    required this.labelTa,
    required this.labelEn,
    required this.loadFactor,
  });

  final String key;
  final String labelTa;
  final String labelEn;
  final double loadFactor;
}

/// The classification of the diesel audit result.
enum DieselAuditStatus {
  normal,   // Within safe margin
  moderate, // 12% to 25% above expected
  highAlert // > 25% above expected (Potential theft, severe leak, or massive idling)
}

/// Result object holding complete audit breakdown.
class DieselAuditResult {
  const DieselAuditResult({
    required this.horsepower,
    required this.workingHours,
    required this.implement,
    required this.soil,
    required this.expectedLitres,
    required this.minSafeLitres,
    required this.maxSafeLitres,
    required this.actualLitres,
    required this.varianceLitres,
    required this.variancePercent,
    required this.dieselPricePerLitre,
    required this.financialVariance,
    required this.status,
    required this.adviceTa,
    required this.adviceEn,
  });

  final int horsepower;
  final double workingHours;
  final FarmImplementType implement;
  final SoilCondition soil;
  final double expectedLitres;
  final double minSafeLitres;
  final double maxSafeLitres;
  final double actualLitres;
  final double varianceLitres;
  final double variancePercent;
  final double dieselPricePerLitre;
  final double financialVariance;
  final DieselAuditStatus status;
  final String adviceTa;
  final String adviceEn;

  bool get isSuspicious => status == DieselAuditStatus.highAlert;
}

/// Smart Diesel Consumption Auditor Service.
/// Based on ARAI / ICAR agricultural tractor standards.
class DieselAuditService {
  DieselAuditService._();
  static final DieselAuditService instance = DieselAuditService._();

  static const double defaultDieselPrice = 96.0; // ₹ per Litre in TN / India

  /// Calculates expected diesel consumption and audits reported fuel usage.
  DieselAuditResult auditConsumption({
    required int horsepower,
    required double workingHours,
    required FarmImplementType implement,
    required SoilCondition soil,
    required double actualLitres,
    double dieselPricePerLitre = defaultDieselPrice,
  }) {
    final validHp = math.max(20, math.min(120, horsepower));
    final validHours = math.max(0.1, workingHours);

    // Expected Fuel Formula: HP * Implement Load Factor * Soil Factor * Hours
    final double rawExpected = validHp * implement.loadFactor * soil.resistanceFactor * validHours;
    final double expectedLitres = double.parse(rawExpected.toStringAsFixed(2));

    // Safe tolerance window (±10% to +12% for normal operating variations)
    final double minSafeLitres = double.parse((expectedLitres * 0.90).toStringAsFixed(2));
    final double maxSafeLitres = double.parse((expectedLitres * 1.12).toStringAsFixed(2));

    final double varianceLitres = double.parse((actualLitres - expectedLitres).toStringAsFixed(2));
    final double variancePercent = expectedLitres > 0
        ? double.parse(((varianceLitres / expectedLitres) * 100).toStringAsFixed(1))
        : 0.0;

    final double financialVariance = double.parse((varianceLitres * dieselPricePerLitre).toStringAsFixed(0));

    DieselAuditStatus status;
    String adviceTa;
    String adviceEn;

    if (actualLitres <= maxSafeLitres) {
      status = DieselAuditStatus.normal;
      adviceTa = 'டீசல் நுகர்வு சரியான வரம்பில் உள்ளது. என்ஜின் இயக்கம் மற்றும் ஓட்டுநர் வேலை திருப்திகரமாக உள்ளது.';
      adviceEn = 'Fuel consumption is normal and within standard agricultural limits.';
    } else if (actualLitres <= expectedLitres * 1.25) {
      status = DieselAuditStatus.moderate;
      adviceTa = 'வழக்கத்தை விட $variancePercent% கூடுதல் டீசல் செலவாகியுள்ளது (+${varianceLitres.toStringAsFixed(1)}L, ~₹$financialVariance). என்ஜின் ஏர் பில்டரை சுத்தம் செய்யவும் அல்லது அதிக நேரம் சும்மா நின்றதா என கவனிக்கவும்.';
      adviceEn = 'Fuel consumption is $variancePercent% higher than expected (+${varianceLitres.toStringAsFixed(1)}L, ~₹$financialVariance). Inspect air filter or check idle times.';
    } else {
      status = DieselAuditStatus.highAlert;
      adviceTa = 'எச்சரிக்கை: வழக்கத்தை விட $variancePercent% மிக அதிக டீசல் செலவு (+${varianceLitres.toStringAsFixed(1)}L, இழப்பு: ₹$financialVariance)! டீசல் கசிவு, எரிபொருள் திருட்டு அல்லது தவறான கியர் பயன்பாடு சாத்தியம்.';
      adviceEn = 'ALERT: $variancePercent% abnormal excess fuel reported (+${varianceLitres.toStringAsFixed(1)}L, Loss: ₹$financialVariance)! Possible fuel theft, leakage, or excessive idling.';
    }

    return DieselAuditResult(
      horsepower: validHp,
      workingHours: validHours,
      implement: implement,
      soil: soil,
      expectedLitres: expectedLitres,
      minSafeLitres: minSafeLitres,
      maxSafeLitres: maxSafeLitres,
      actualLitres: actualLitres,
      varianceLitres: varianceLitres,
      variancePercent: variancePercent,
      dieselPricePerLitre: dieselPricePerLitre,
      financialVariance: financialVariance,
      status: status,
      adviceTa: adviceTa,
      adviceEn: adviceEn,
    );
  }
}
