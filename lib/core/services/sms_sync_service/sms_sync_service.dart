import 'dart:io';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../base/logger/app_logger.dart';
import '../sms_parser_service/ignored_rule_service.dart';
import '../sms_parser_service/sms_parser_service.dart';

/// SMS sync service for scanning device SMS with custom date range support
@lazySingleton
class SmsSyncService {
  final SmsQuery _query = SmsQuery();
  final IgnoredRuleService _ignoredRuleService;

  SmsSyncService(this._ignoredRuleService);

  /// Check if SMS permission is granted
  Future<bool> hasSmsPermission() async {
    if (!Platform.isAndroid) return false;
    return await Permission.sms.isGranted;
  }

  /// Request SMS permission
  Future<bool> requestSmsPermission() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Scan inbox SMS and parse financial messages with date filtering
  Future<List<ParsedSmsResult>> syncInbox({
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 500,
  }) async {
    if (!Platform.isAndroid) {
      Log.w('SMS reading is only supported on Android. Use SMS simulator for other platforms.');
      return [];
    }

    try {
      final hasPermission = await hasSmsPermission();
      if (!hasPermission) {
        final granted = await requestSmsPermission();
        if (!granted) {
          Log.w('SMS Permission not granted by user.');
          return [];
        }
      }

      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: limit,
      );

      final List<ParsedSmsResult> parsedList = [];

      for (final msg in messages) {
        final msgDate = msg.date ?? DateTime.now();

        // Filter by user selected fromDate
        if (fromDate != null && msgDate.isBefore(fromDate)) {
          continue;
        }

        // Filter by user selected toDate
        if (toDate != null && msgDate.isAfter(toDate)) {
          continue;
        }

        final body = msg.body;
        if (body == null || body.trim().isEmpty) continue;

        // Check if ignored by custom user rules
        if (_ignoredRuleService.isIgnored(body, sender: msg.sender)) {
          continue;
        }

        final parsed = SmsParserService.parse(
          body,
          smsDate: msgDate,
          senderAddress: msg.sender,
        );

        if (parsed.isValidTransaction) {
          parsedList.add(parsed);
        }
      }

      Log.i('SMS Sync completed: Found ${parsedList.length} transactions since ${fromDate ?? "beginning"} (scanned ${messages.length} SMS).');
      return parsedList;
    } catch (e, stack) {
      Log.e('Error syncing SMS inbox', error: e, stackTrace: stack);
      return [];
    }
  }

  /// 15+ Real-world Indian Bank & UPI SMS Templates for instant simulator testing
  static final List<Map<String, String>> sampleSmsTemplates = [
    {
      'title': 'HDFC Swiggy UPI Debit',
      'sender': 'HDFCBK',
      'body': 'Dear Customer, INR 489.00 debited from A/C **4582 on 06-SEP-26 via UPI to SWIGGY. Ref No 425109283741. Avl Bal: INR 34,250.00 - HDFC Bank',
    },
    {
      'title': 'SBI Zomato Debit',
      'sender': 'SBIN',
      'body': 'Your A/C *7891 has been debited by Rs 620.00 on 05-SEP-26 20:15:20 by UPI Ref no 424876543210. Transfer to Zomato Limited. Bal Rs 18,400.50',
    },
    {
      'title': 'Google Pay Grocery (Blinkit)',
      'sender': 'AXISBK',
      'body': 'Paid Rs. 340.00 to Blinkit using Google Pay from Axis Bank A/C ending with 9021. UPI Ref: 425098123456. Avl Bal: Rs. 12,890.00',
    },
    {
      'title': 'PhonePe Amazon Shopping',
      'sender': 'PHONEPE',
      'body': 'Rs 1,499.00 paid to Amazon Pay India on 04-Sep-26 using PhonePe UPI. Txn ID: T26090412345678. Debited from ICICI Bank **3321.',
    },
    {
      'title': 'Salary Credit (HDFC)',
      'sender': 'HDFCBK',
      'body': 'Salary of INR 85,000.00 credited to your A/C **4582 on 01-SEP-26 by INFOSYS LIMITED. Avl Bal: INR 1,19,250.00.',
    },
    {
      'title': 'Uber Ride Travel',
      'sender': 'PAYTM',
      'body': 'Money Sent: Rs 285.00 paid to Uber India via Paytm UPI from Kotak Bank A/c **1122. UPI Ref 424789012345.',
    },
    {
      'title': 'Electricity Bill (BESCOM)',
      'sender': 'CRED',
      'body': 'Paid Rs 1,850.00 for BESCOM Electricity Bill via CRED Pay. Reference: CRD987654321 on 03-SEP-26. Cashback of Rs 25.00 received in CRED wallet.',
    },
    {
      'title': 'Netflix Subscription',
      'sender': 'ICICIB',
      'body': 'INR 649.00 spent on ICICI Bank Credit Card ending 7741 at NETFLIX ENTERTAINMENT on 02-SEP-26. Available limit: INR 1,45,000.00.',
    },
    {
      'title': 'SIP Investment (Zerodha)',
      'sender': 'HDFCBK',
      'body': 'INR 5,000.00 debited from A/C **4582 on 05-SEP-26 towards ZERODHA BROKING LTD. Ref No 425112233445. Avl Bal: INR 29,250.00.',
    },
    {
      'title': 'Apollo Pharmacy Medical',
      'sender': 'SBIN',
      'body': 'Rs. 890.00 debited from A/c **7891 on 04-Sep-26 at Apollo Pharmacy. Txn ID 424987654321. Avl Bal Rs 17,510.50',
    },
    {
      'title': 'Zepto Grocery Quick Delivery',
      'sender': 'KOTAKB',
      'body': 'Rs 215.00 debited from Kotak Bank A/c **1122 on 06-Sep-26 to KiranaKart Zepto. UPI Ref 425234567890.',
    },
    {
      'title': 'Flipkart Big Billion Days',
      'sender': 'AXISBK',
      'body': 'Transaction of INR 4,999.00 made on Axis Bank Card ending 9021 at FLIPKART INTERNET on 03-SEP-26. Ref No: 424765432198.',
    },
    {
      'title': 'Friend Payment Received (PhonePe)',
      'sender': 'PHONEPE',
      'body': 'You have received Rs 2,500.00 from Rahul Verma on PhonePe UPI. Deposited in SBI A/C ending 7891. UPI Ref 425012345678.',
    },
    {
      'title': 'Jio Fiber Broadband Recharge',
      'sender': 'PAYTM',
      'body': 'Recharge of Rs 1,178.00 successful for Jio Fiber ID 1234567890 via Paytm UPI on 01-SEP-26. Txn ID: PYTM987654.',
    },
  ];
}
