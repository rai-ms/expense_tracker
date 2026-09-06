import 'package:uuid/uuid.dart';

/// Parsed SMS transaction result model
class ParsedSmsResult {
  final String uid;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String category; // 'Food & Dining', 'Groceries', etc.
  final String? merchant;
  final String? platform;
  final String? transactionId;
  final String? accountOrCard;
  final DateTime date;
  final String rawSms;
  final double? balanceAfter;
  final bool isValidTransaction;

  const ParsedSmsResult({
    required this.uid,
    required this.amount,
    required this.type,
    required this.category,
    this.merchant,
    this.platform,
    this.transactionId,
    this.accountOrCard,
    required this.date,
    required this.rawSms,
    this.balanceAfter,
    this.isValidTransaction = true,
  });

  factory ParsedSmsResult.invalid(String rawSms) {
    return ParsedSmsResult(
      uid: const Uuid().v4(),
      amount: 0.0,
      type: 'debit',
      category: 'Other / Transfer',
      date: DateTime.now(),
      rawSms: rawSms,
      isValidTransaction: false,
    );
  }
}

/// Intelligent Regex & Heuristic Parser for Indian Banking and Fintech SMS
class SmsParserService {
  static const _uuid = Uuid();

  /// Parse a single SMS text into structured financial transaction details
  static ParsedSmsResult parse(String smsBody, {DateTime? smsDate, String? senderAddress}) {
    final text = smsBody.trim();
    // 0. Pre-check: Check if SMS is purely an informational alert / OTP / mandate notice
    if (isNotificationOnly(text)) {
      return ParsedSmsResult.invalid(text);
    }

    // 1. Amount Extraction
    final amount = _extractAmount(text);
    if (amount == null || amount <= 0) {
      return ParsedSmsResult.invalid(text);
    }

    // 2. Debit vs Credit Type Detection
    final type = _extractType(text);

    // 3. Platform & Bank Detection
    final platform = _extractPlatform(text, senderAddress);

    // 4. Transaction ID / UTR
    final txnId = _extractTransactionId(text);

    // 5. Account or Card Last 4 Digits
    final accountOrCard = _extractAccountOrCard(text);

    // 6. Available Balance
    final balanceAfter = _extractAvailableBalance(text);

    // 7. Merchant Detection
    final merchant = _extractMerchant(text);

    // 8. Auto-Categorization
    final category = _categorize(text, merchant, platform);

    return ParsedSmsResult(
      uid: _uuid.v4(),
      amount: amount,
      type: type,
      category: category,
      merchant: merchant,
      platform: platform,
      transactionId: txnId,
      accountOrCard: accountOrCard,
      date: smsDate ?? DateTime.now(),
      rawSms: text,
      balanceAfter: balanceAfter,
      isValidTransaction: true,
    );
  }

  /// Extract Amount with comma and decimal support
  static double? _extractAmount(String text) {
    // Patterns like: Rs. 1,500.50, INR 500, ₹450, Rs 99.00, 1,200.00 INR
    final regexes = [
      RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:INR|Rs\.?|₹)', caseSensitive: false),
      RegExp(r'(?:spent|paid|debited|credited|sent|received)\s+(?:of\s+)?(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    ];

    for (final reg in regexes) {
      final match = reg.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          final val = double.tryParse(amountStr);
          if (val != null && val > 0) return val;
        }
      }
    }
    return null;
  }

  /// Detect if Debit or Credit
  static String _extractType(String text) {
    final lower = text.toLowerCase();

    // Check credit keywords first
    final creditKeywords = [
      'credited', 'received', 'deposited', 'refund', 'cashback', 'added to',
      'salary', 'bonus', 'transferred to your a/c', 'reversed'
    ];
    for (final kw in creditKeywords) {
      if (lower.contains(kw)) return 'credit';
    }

    // Check debit keywords
    final debitKeywords = [
      'debited', 'paid', 'sent', 'spent', 'withdrawn', 'purchase of',
      'transferred to', 'deducted', 'payment to', 'vpa'
    ];
    for (final kw in debitKeywords) {
      if (lower.contains(kw)) return 'debit';
    }

    return 'debit'; // Default to debit for safety
  }

  /// Extract Platform or Bank
  static String _extractPlatform(String text, String? sender) {
    final combined = '$text ${sender ?? ''}'.toLowerCase();

    if (combined.contains('gpay') || combined.contains('google pay')) return 'Google Pay';
    if (combined.contains('phonepe') || combined.contains('ybl') || combined.contains('ibl')) return 'PhonePe';
    if (combined.contains('paytm') || combined.contains('pytm')) return 'Paytm';
    if (combined.contains('cred')) return 'Cred';
    if (combined.contains('amazon') || combined.contains('amzn')) return 'Amazon Pay';
    if (combined.contains('bhim') || combined.contains('npci')) return 'BHIM';
    if (combined.contains('slice')) return 'Slice';
    if (combined.contains('hdfc')) return 'HDFC Bank';
    if (combined.contains('sbi') || combined.contains('sbin')) return 'SBI';
    if (combined.contains('icici')) return 'ICICI Bank';
    if (combined.contains('axis')) return 'Axis Bank';
    if (combined.contains('kotak')) return 'Kotak Bank';
    if (combined.contains('pnb')) return 'PNB';
    if (combined.contains('bob') || combined.contains('baroda')) return 'Bank of Baroda';
    if (combined.contains('yes bank')) return 'Yes Bank';
    if (combined.contains('indusind')) return 'IndusInd Bank';
    if (combined.contains('upi')) return 'UPI';

    return 'Bank / UPI';
  }

  /// Extract Transaction ID / UTR
  static String? _extractTransactionId(String text) {
    final regexes = [
      RegExp(r'(?:UPI Ref(?: no)?|Txn(?: ID)?|Ref(?: No)?|UTR|Ref id|Ref|txn#)[\s:/-]*([0-9a-zA-Z]{6,22})', caseSensitive: false),
      RegExp(r'(?:transaction ID|rrn)[\s:/-]*([0-9a-zA-Z]{6,22})', caseSensitive: false),
    ];

    for (final reg in regexes) {
      final match = reg.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Extract Account or Card digits
  static String? _extractAccountOrCard(String text) {
    final reg = RegExp(r'(?:A/C|Acct|Account|Card|ending with)\s*(?:no\.?)?\s*[*xX\s]*(\d{3,4})', caseSensitive: false);
    final match = reg.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  /// Extract Available Balance
  static double? _extractAvailableBalance(String text) {
    final reg = RegExp(
      r'(?:Avl\s*Bal|Available\s*Balance|Bal|Balance\s*is)[\s:/-]*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    final match = reg.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      final str = match.group(1)?.replaceAll(',', '');
      if (str != null) return double.tryParse(str);
    }
    return null;
  }

  /// Extract Merchant / Payee
  static String? _extractMerchant(String text) {
    final lower = text.toLowerCase();

    // Prominent brands
    final brands = [
      'Swiggy', 'Zomato', 'Blinkit', 'Zepto', 'Instamart', 'BigBasket', 'D-Mart',
      'Amazon', 'Flipkart', 'Myntra', 'Meesho', 'Ajio', 'Zara', 'H&M', 'Nykaa',
      'Uber', 'Ola', 'Rapido', 'IndianOil', 'HPCL', 'BPCL', 'IRCTC', 'MakeMyTrip',
      'Netflix', 'Spotify', 'BookMyShow', 'Prime Video', 'Hotstar', 'YouTube',
      'Zerodha', 'Groww', 'AngelOne', 'Upstox', 'Apollo', 'PharmEasy', '1mg',
      'Jio', 'Airtel', 'Vi', 'BESCOM', 'Tata Power', 'Starbucks', 'McDonald', 'Dominos'
    ];

    for (final brand in brands) {
      if (lower.contains(brand.toLowerCase())) {
        return brand;
      }
    }

    // Try regex: "to VPA abc@xyz" or "at MERCHANT on"
    final merchantRegex = RegExp(r'(?:to|at|vpa|paid to|info:)\s+([A-Za-z0-9\s&]+?)(?:\s+(?:on|ref|dated|avl|using|\.|\-|\,))', caseSensitive: false);
    final match = merchantRegex.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      final name = match.group(1)?.trim();
      if (name != null && name.length >= 2 && name.length <= 30 && !name.toLowerCase().contains('your')) {
        return name;
      }
    }
    return null;
  }

  /// Auto-Categorization engine
  static String _categorize(String text, String? merchant, String? platform) {
    final lower = '$text ${merchant ?? ''} ${platform ?? ''}'.toLowerCase();

    if (lower.contains('swiggy') ||
        lower.contains('zomato') ||
        lower.contains('mcdonald') ||
        lower.contains('starbucks') ||
        lower.contains('domino') ||
        lower.contains('kfc') ||
        lower.contains('burger') ||
        lower.contains('cafe') ||
        lower.contains('restaurant') ||
        lower.contains('food') ||
        lower.contains('dining') ||
        lower.contains('chai')) {
      return 'Food & Dining';
    }

    if (lower.contains('blinkit') ||
        lower.contains('zepto') ||
        lower.contains('instamart') ||
        lower.contains('bigbasket') ||
        lower.contains('dmart') ||
        lower.contains('d-mart') ||
        lower.contains('supermarket') ||
        lower.contains('grocery') ||
        lower.contains('provision')) {
      return 'Groceries';
    }

    if (lower.contains('amazon') ||
        lower.contains('flipkart') ||
        lower.contains('myntra') ||
        lower.contains('meesho') ||
        lower.contains('ajio') ||
        lower.contains('zara') ||
        lower.contains('h&m') ||
        lower.contains('nykaa') ||
        lower.contains('shopping') ||
        lower.contains('retail') ||
        lower.contains('mall')) {
      return 'Shopping';
    }

    if (lower.contains('uber') ||
        lower.contains('ola') ||
        lower.contains('rapido') ||
        lower.contains('indianoil') ||
        lower.contains('hpcl') ||
        lower.contains('bpcl') ||
        lower.contains('fuel') ||
        lower.contains('petrol') ||
        lower.contains('irctc') ||
        lower.contains('makemytrip') ||
        lower.contains('goibibo') ||
        lower.contains('flight') ||
        lower.contains('train') ||
        lower.contains('metro')) {
      return 'Travel & Fuel';
    }

    if (lower.contains('electricity') ||
        lower.contains('bescom') ||
        lower.contains('power') ||
        lower.contains('gas') ||
        lower.contains('water') ||
        lower.contains('jio') ||
        lower.contains('airtel') ||
        lower.contains('broadband') ||
        lower.contains('fibernet') ||
        lower.contains('recharge') ||
        lower.contains('bill')) {
      return 'Bills & Utilities';
    }

    if (lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('bookmyshow') ||
        lower.contains('prime video') ||
        lower.contains('hotstar') ||
        lower.contains('cinema') ||
        lower.contains('pvr') ||
        lower.contains('inox') ||
        lower.contains('movie')) {
      return 'Entertainment';
    }

    if (lower.contains('zerodha') ||
        lower.contains('groww') ||
        lower.contains('angelone') ||
        lower.contains('upstox') ||
        lower.contains('mutual fund') ||
        lower.contains('sip') ||
        lower.contains('stocks') ||
        lower.contains('investment')) {
      return 'Investments';
    }

    if (lower.contains('apollo') ||
        lower.contains('pharmeasy') ||
        lower.contains('1mg') ||
        lower.contains('netmeds') ||
        lower.contains('hospital') ||
        lower.contains('medical') ||
        lower.contains('clinic') ||
        lower.contains('pharmacy') ||
        lower.contains('doctor')) {
      return 'Health & Medical';
    }

    if (lower.contains('salary') ||
        lower.contains('payroll') ||
        lower.contains('stipend') ||
        lower.contains('interest credited') ||
        lower.contains('dividend')) {
      return 'Salary & Income';
    }

    return 'Other / Transfer';
  }

  /// Detect if the SMS is purely a notification / OTP / informational alert rather than a completed transaction
  static bool isNotificationOnly(String text) {
    if (text.trim().isEmpty) return true;
    final lower = text.toLowerCase();

    // 1. Pure OTP / Login / Security verification (without actual debit/credit)
    if (lower.contains('otp') ||
        lower.contains('one time password') ||
        lower.contains('verification code') ||
        lower.contains('secret code') ||
        lower.contains('do not share your otp') ||
        lower.contains('is your secret code')) {
      if (!lower.contains('debited') &&
          !lower.contains('credited') &&
          !lower.contains('spent on') &&
          !lower.contains('paid to')) {
        return true;
      }
    }

    // 2. Collect requests / Money requests (pending / not yet completed)
    if (lower.contains('requested money') ||
        lower.contains('has requested') ||
        lower.contains('collect request') ||
        lower.contains('request for payment') ||
        lower.contains('payment request of')) {
      return true;
    }

    // 3. Mandate / Auto-pay setup or reminder (not an actual debit)
    if (lower.contains('e-mandate') ||
        lower.contains('mandate registered') ||
        lower.contains('mandate created') ||
        lower.contains('autopay set up') ||
        lower.contains('autopay scheduled') ||
        lower.contains('standing instruction setup')) {
      return true;
    }

    // 4. Credit limit enhancement & Promotional offers
    if (lower.contains('credit limit enhanced') ||
        lower.contains('credit limit increased') ||
        lower.contains('pre-approved') ||
        lower.contains('apply now for') ||
        lower.contains('eligible for loan') ||
        lower.contains('congratulations! you are eligible') ||
        lower.contains('reward points earned')) {
      return true;
    }

    // 5. Bill due reminders / Statement generated (informational notice)
    if (lower.contains('statement generated') ||
        lower.contains('e-statement has been sent') ||
        lower.contains('bill is generated') ||
        lower.contains('bill due date is') ||
        lower.contains('due date for your') ||
        lower.contains('total amount due')) {
      if (!lower.contains('debited') && !lower.contains('paid') && !lower.contains('credited')) {
        return true;
      }
    }

    // 6. Security advisories & ATM PIN changes
    if (lower.contains('pin changed') ||
        lower.contains('kyc update') ||
        lower.contains('profile password') ||
        lower.contains('logged in from')) {
      return true;
    }

    return false;
  }
}
