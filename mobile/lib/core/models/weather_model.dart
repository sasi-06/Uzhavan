/// Uzhavan — Weather & Soil Workability Models
/// Data source: Open-Meteo API (https://api.open-meteo.com)
/// WMO Weather Codes: https://open-meteo.com/en/docs#weathervariables

enum SoilWorkabilityLevel {
  good,      // ✅ Safe to book — dry / low rain risk
  caution,   // ⚠️ Possible wet conditions — confirm with owner
  poor,      // ❌ Heavy rain forecast — machinery damage risk
  unknown,   // No data yet
}

class DayWeather {
  const DayWeather({
    required this.date,
    required this.weatherCode,
    required this.precipSumMm,
    required this.precipProbMax,
    required this.windspeedMaxKmh,
    this.soilMoisture,
    required this.workability,
  });

  final DateTime date;
  final int weatherCode;
  final double precipSumMm;    // mm of rain
  final int precipProbMax;     // 0–100 %
  final double windspeedMaxKmh;
  final double? soilMoisture;  // 0.0–1.0 m³/m³ (top 1 cm)
  final SoilWorkabilityLevel workability;

  /// WMO code → English label
  String get weatherLabel {
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode == 1) return 'Mainly Clear';
    if (weatherCode == 2) return 'Partly Cloudy';
    if (weatherCode == 3) return 'Overcast';
    if (weatherCode >= 45 && weatherCode <= 48) return 'Foggy';
    if (weatherCode >= 51 && weatherCode <= 55) return 'Drizzle';
    if (weatherCode >= 56 && weatherCode <= 57) return 'Freezing Drizzle';
    if (weatherCode >= 61 && weatherCode <= 65) return 'Rain';
    if (weatherCode >= 66 && weatherCode <= 67) return 'Freezing Rain';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snow';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain Showers';
    if (weatherCode == 85 || weatherCode == 86) return 'Snow Showers';
    if (weatherCode == 95) return 'Thunderstorm';
    if (weatherCode >= 96 && weatherCode <= 99) return 'Heavy Thunderstorm';
    return 'Unknown';
  }

  /// WMO code → Tamil label
  String get weatherLabelTamil {
    if (weatherCode == 0) return 'தெளிவான வானம்';
    if (weatherCode == 1) return 'பெரும்பாலும் தெளிவு';
    if (weatherCode == 2) return 'பகுதி மேகம்';
    if (weatherCode == 3) return 'மேகமூட்டம்';
    if (weatherCode >= 45 && weatherCode <= 48) return 'மூடுபனி';
    if (weatherCode >= 51 && weatherCode <= 55) return 'தூறல்';
    if (weatherCode >= 61 && weatherCode <= 65) return 'மழை';
    if (weatherCode >= 80 && weatherCode <= 82) return 'மழைச் சாரல்';
    if (weatherCode == 95) return 'இடியுடன் மழை';
    if (weatherCode >= 96 && weatherCode <= 99) return 'கடும் இடியுடன் மழை';
    return 'வானிலை';
  }

  /// Whether this is a rain or storm code
  bool get isRainy => (weatherCode >= 51 && weatherCode <= 67) ||
      (weatherCode >= 80 && weatherCode <= 99);

  bool get isThunderstorm => weatherCode >= 95;
}

/// Compute soil workability for a given machine type
/// Harvesters & Rotavators are more sensitive to wet soil
SoilWorkabilityLevel computeWorkability({
  required double precipSumMm,
  required int precipProbMax,
  required int weatherCode,
  required String machineType,
}) {
  // Strict machines: rotavator, harvester, cultivator
  final strictMachines = {'rotavator', 'harvester', 'cultivator', 'thresher'};
  final isStrict = strictMachines.contains(machineType.toLowerCase());

  // Thunderstorm → always poor
  if (weatherCode >= 95) return SoilWorkabilityLevel.poor;

  // Thresholds
  final goodPrecipMax = isStrict ? 5.0 : 10.0;
  final goodProbMax = isStrict ? 25 : 35;
  final poorPrecipMin = isStrict ? 15.0 : 25.0;
  final poorProbMin = isStrict ? 50 : 65;

  if (precipSumMm >= poorPrecipMin || precipProbMax >= poorProbMin) {
    return SoilWorkabilityLevel.poor;
  }
  if (precipSumMm <= goodPrecipMax && precipProbMax <= goodProbMax) {
    return SoilWorkabilityLevel.good;
  }
  return SoilWorkabilityLevel.caution;
}

class WeatherForecast {
  const WeatherForecast({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.days,
    required this.fetchedAt,
  });

  final double latitude;
  final double longitude;
  final String timezone;
  final List<DayWeather> days;
  final DateTime fetchedAt;

  /// Get forecast for a specific date (day-precision match)
  DayWeather? forDate(DateTime date) {
    try {
      return days.firstWhere(
        (d) =>
            d.date.year == date.year &&
            d.date.month == date.month &&
            d.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }
}
