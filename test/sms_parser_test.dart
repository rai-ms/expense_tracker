import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/services/sms_parser_service/sms_parser_service.dart';

void main() {
  group('SmsParserService Tests', () {
    test('HDFC Swiggy UPI Debit SMS parsing', () {
      const sms = 'Dear Customer, INR 489.00 debited from A/C **4582 on 06-SEP-26 via UPI to SWIGGY. Ref No 425109283741. Avl Bal: INR 34,250.00 - HDFC Bank';
      final result = SmsParserService.parse(sms, senderAddress: 'HDFCBK');

      expect(result.isValidTransaction, isTrue);
      expect(result.amount, 489.00);
      expect(result.type, 'debit');
      expect(result.category, 'Food & Dining');
      expect(result.merchant, 'Swiggy');
      expect(result.platform, 'HDFC Bank');
      expect(result.transactionId, '425109283741');
      expect(result.accountOrCard, '4582');
      expect(result.balanceAfter, 34250.00);
    });

    test('SBI Zomato Debit SMS parsing', () {
      const sms = 'Your A/C *7891 has been debited by Rs 620.00 on 05-SEP-26 20:15:20 by UPI Ref no 424876543210. Transfer to Zomato Limited. Bal Rs 18,400.50';
      final result = SmsParserService.parse(sms, senderAddress: 'SBIN');

      expect(result.isValidTransaction, isTrue);
      expect(result.amount, 620.00);
      expect(result.type, 'debit');
      expect(result.category, 'Food & Dining');
      expect(result.merchant, 'Zomato');
      expect(result.platform, 'SBI');
      expect(result.transactionId, '424876543210');
      expect(result.accountOrCard, '7891');
      expect(result.balanceAfter, 18400.50);
    });

    test('Google Pay Blinkit Grocery parsing', () {
      const sms = 'Paid Rs. 340.00 to Blinkit using Google Pay from Axis Bank A/C ending with 9021. UPI Ref: 425098123456. Avl Bal: Rs. 12,890.00';
      final result = SmsParserService.parse(sms, senderAddress: 'AXISBK');

      expect(result.isValidTransaction, isTrue);
      expect(result.amount, 340.00);
      expect(result.type, 'debit');
      expect(result.category, 'Groceries');
      expect(result.merchant, 'Blinkit');
      expect(result.platform, 'Google Pay');
      expect(result.transactionId, '425098123456');
      expect(result.accountOrCard, '9021');
    });

    test('Salary Credit SMS parsing', () {
      const sms = 'Salary of INR 85,000.00 credited to your A/C **4582 on 01-SEP-26 by INFOSYS LIMITED. Avl Bal: INR 1,19,250.00.';
      final result = SmsParserService.parse(sms, senderAddress: 'HDFCBK');

      expect(result.isValidTransaction, isTrue);
      expect(result.amount, 85000.00);
      expect(result.type, 'credit');
      expect(result.category, 'Salary & Income');
      expect(result.balanceAfter, 119250.00);
    });

    test('Uber Ride Travel SMS parsing', () {
      const sms = 'Money Sent: Rs 285.00 paid to Uber India via Paytm UPI from Kotak Bank A/c **1122. UPI Ref 424789012345.';
      final result = SmsParserService.parse(sms, senderAddress: 'PAYTM');

      expect(result.isValidTransaction, isTrue);
      expect(result.amount, 285.00);
      expect(result.type, 'debit');
      expect(result.category, 'Travel & Fuel');
      expect(result.merchant, 'Uber');
      expect(result.platform, 'Paytm');
      expect(result.transactionId, '424789012345');
    });

    test('Zerodha Investment SMS parsing', () {
      const sms = 'INR 5,000.00 debited from A/C **4582 on 05-SEP-26 towards ZERODHA BROKING LTD. Ref No 425112233445. Avl Bal: INR 29,250.00.';
      final result = SmsParserService.parse(sms, senderAddress: 'HDFCBK');

      expect(result.isValidTransaction, isTrue);
      expect(result.amount, 5000.00);
      expect(result.category, 'Investments');
      expect(result.merchant, 'Zerodha');
    });
  });
}
