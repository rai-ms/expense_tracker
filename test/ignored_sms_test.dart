import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/services/sms_parser_service/sms_parser_service.dart';

void main() {
  group('SMS Notification Filter & Ignored Rule Tests', () {
    test('Identifies purely informational OTP messages as Notification Only', () {
      const otpSms = '987654 is your OTP for HDFC NetBanking login. Do not share your OTP with anyone.';
      expect(SmsParserService.isNotificationOnly(otpSms), isTrue);

      final result = SmsParserService.parse(otpSms);
      expect(result.isValidTransaction, isFalse);
    });

    test('Identifies payment collect requests as Notification Only', () {
      const collectRequestSms = 'rahul@upi has requested Rs. 1500.00 from you on Google Pay. Pay before 07-Sep-26.';
      expect(SmsParserService.isNotificationOnly(collectRequestSms), isTrue);

      final result = SmsParserService.parse(collectRequestSms);
      expect(result.isValidTransaction, isFalse);
    });

    test('Identifies mandate and autopay registrations as Notification Only', () {
      const mandateSms = 'Your e-mandate for Netflix Entertainment of Rs 649.00 has been registered successfully.';
      expect(SmsParserService.isNotificationOnly(mandateSms), isTrue);

      final result = SmsParserService.parse(mandateSms);
      expect(result.isValidTransaction, isFalse);

      const paytmAutopaySms = 'Congratulations! Automatic payment of Rs.15,000 for Suryoday Small Finance Bank... has been setup successfully - Paytm';
      expect(SmsParserService.isNotificationOnly(paytmAutopaySms), isTrue);

      final result2 = SmsParserService.parse(paytmAutopaySms);
      expect(result2.isValidTransaction, isFalse);
    });

    test('Identifies promotional loan & credit limit enhancement as Notification Only', () {
      const promoSms = 'Congratulations! Your ICICI Bank credit limit enhanced to Rs 3,00,000. Apply now for pre-approved loan of Rs 5,00,000.';
      expect(SmsParserService.isNotificationOnly(promoSms), isTrue);

      final result = SmsParserService.parse(promoSms);
      expect(result.isValidTransaction, isFalse);
    });

    test('Identifies freeze period / first transaction limit advisory as Notification Only', () {
      const freezePeriodSms =
          'Dear Customer, You can initiate your first transaction with max limit of Rs.5000. '
          'After the freeze period of 24 hours, subsequent transactions can be performed. -Suryoday Small Finance Bank Limited';
      expect(SmsParserService.isNotificationOnly(freezePeriodSms), isTrue);

      final result = SmsParserService.parse(freezePeriodSms);
      expect(result.isValidTransaction, isFalse);
    });

    test('Real financial debits & credits are correctly recognized as valid transactions', () {
      const debitSms = 'Dear Customer, INR 489.00 debited from A/C **4582 on 06-SEP-26 via UPI to SWIGGY. Ref No 425109283741. Avl Bal: INR 34,250.00';
      expect(SmsParserService.isNotificationOnly(debitSms), isFalse);

      final result = SmsParserService.parse(debitSms);
      expect(result.isValidTransaction, isTrue);
      expect(result.amount, 489.0);
      expect(result.type, 'debit');
    });

    test('Salary credit SMS is correctly recognized as valid credit transaction', () {
      const salarySms = 'Salary of INR 85,000.00 credited to your A/C **4582 on 01-SEP-26 by INFOSYS LIMITED. Avl Bal: INR 1,19,250.00.';
      expect(SmsParserService.isNotificationOnly(salarySms), isFalse);

      final result = SmsParserService.parse(salarySms);
      expect(result.isValidTransaction, isTrue);
      expect(result.amount, 85000.0);
      expect(result.type, 'credit');
    });
  });
}
