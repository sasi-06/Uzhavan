import 'package:flutter_test/flutter_test.dart';
import 'package:uzhavan/core/services/diesel_audit_service.dart';

void main() {
  group('Smart Diesel Consumption Auditor Tests', () {
    final auditor = DieselAuditService.instance;

    test('1. Normal consumption check for 45 HP Tractor with Rotavator in Red Soil', () {
      // 45 HP * 0.100 (Rotavator) * 1.0 (Red Soil) * 3 Hours = 13.5 Litres
      final result = auditor.auditConsumption(
        horsepower: 45,
        workingHours: 3.0,
        implement: FarmImplementType.rotavator,
        soil: SoilCondition.redLoam,
        actualLitres: 14.0, // Well within safe window (12.15 to 15.12 L)
      );

      expect(result.expectedLitres, equals(13.5));
      expect(result.status, equals(DieselAuditStatus.normal));
      expect(result.isSuspicious, isFalse);
      expect(result.varianceLitres, equals(0.5));
    });

    test('2. High Alert (Possible Fuel Pilferage) detected when 22L claimed for 13.5L job', () {
      final result = auditor.auditConsumption(
        horsepower: 45,
        workingHours: 3.0,
        implement: FarmImplementType.rotavator,
        soil: SoilCondition.redLoam,
        actualLitres: 22.0, // 22L is > 60% over expected!
      );

      expect(result.expectedLitres, equals(13.5));
      expect(result.status, equals(DieselAuditStatus.highAlert));
      expect(result.isSuspicious, isTrue);
      expect(result.varianceLitres, equals(8.5));
      expect(result.variancePercent, greaterThan(50.0));
      expect(result.financialVariance, greaterThan(700.0));
      expect(result.adviceTa.contains('எச்சரிக்கை'), isTrue);
    });

    test('3. Heavy Black Clay increases resistance factor properly', () {
      // 50 HP * 0.080 (Cultivator) * 1.20 (Black Clay) * 2 Hours = 9.6 Litres
      final result = auditor.auditConsumption(
        horsepower: 50,
        workingHours: 2.0,
        implement: FarmImplementType.cultivator,
        soil: SoilCondition.blackClay,
        actualLitres: 9.8,
      );

      expect(result.expectedLitres, equals(9.6));
      expect(result.status, equals(DieselAuditStatus.normal));
    });

    test('4. Moderate variance warning triggers correctly', () {
      // 45 HP * 0.100 * 1.0 * 2.0 = 9.0 L. 20% over is 10.8 L.
      final result = auditor.auditConsumption(
        horsepower: 45,
        workingHours: 2.0,
        implement: FarmImplementType.rotavator,
        soil: SoilCondition.redLoam,
        actualLitres: 10.8,
      );

      expect(result.expectedLitres, equals(9.0));
      expect(result.status, equals(DieselAuditStatus.moderate));
      expect(result.isSuspicious, isFalse);
    });
  });
}
