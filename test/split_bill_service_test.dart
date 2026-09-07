import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/services/split_bill_service/split_bill_service.dart';
import 'package:expense_tracker/domain/repositories/i_khata_repository.dart';
import 'package:expense_tracker/domain/repositories/i_transaction_repository.dart';
import 'package:expense_tracker/data/models/khata_contact_entity.dart';
import 'package:expense_tracker/data/models/khata_entry_entity.dart';
import 'package:expense_tracker/data/models/transaction_entity.dart';
import 'package:expense_tracker/core/services/sms_parser_service/sms_parser_service.dart';

class MockKhataRepository implements IKhataRepository {
  final List<KhataContactEntity> contacts = [];
  final List<KhataEntryEntity> entries = [];

  @override
  int addContact(KhataContactEntity contact) {
    contact.id = contacts.length + 1;
    contacts.add(contact);
    return contact.id;
  }

  @override
  int addEntry(int contactId, KhataEntryEntity entry) {
    entry.id = entries.length + 1;
    entries.add(entry);
    return entry.id;
  }

  @override
  List<KhataContactEntity> getAllContacts() => contacts;

  @override
  KhataContactEntity? getContactById(int id) =>
      contacts.where((c) => c.id == id).firstOrNull;

  @override
  KhataContactEntity? getContactByUid(String uid) =>
      contacts.where((c) => c.uid == uid).firstOrNull;

  @override
  bool updateContact(KhataContactEntity contact) => true;

  @override
  bool deleteContact(int id) => true;

  @override
  List<KhataEntryEntity> getEntriesForContact(int contactId) => entries;

  @override
  bool settleEntry(int entryId) => true;

  @override
  bool settleAllEntriesForContact(int contactId) => true;

  @override
  bool deleteEntry(int entryId) => true;

  @override
  double getTotalWillReceive() => 0.0;

  @override
  double getTotalWillGive() => 0.0;
}

class MockTransactionRepository implements ITransactionRepository {
  final List<TransactionEntity> transactions = [];

  @override
  int addTransaction(TransactionEntity transaction) {
    transaction.id = transactions.length + 1;
    transactions.add(transaction);
    return transaction.id;
  }

  @override
  List<int> addTransactions(List<TransactionEntity> txns) {
    return txns.map((t) => addTransaction(t)).toList();
  }

  @override
  List<TransactionEntity> getAllTransactions() => transactions;

  @override
  List<TransactionEntity> getRecentTransactions({int limit = 10}) => transactions;

  @override
  List<TransactionEntity> getTransactionsByDateRange(DateTime start, DateTime end) => transactions;

  @override
  TransactionEntity? getTransactionByUid(String uid) =>
      transactions.where((t) => t.uid == uid).firstOrNull;

  @override
  bool hasTransactionWithTxnId(String txnId) => false;

  @override
  bool isDuplicateParsed(ParsedSmsResult parsed) => false;

  @override
  int cleanDuplicateTransactions() => 0;

  @override
  bool updateTransaction(TransactionEntity transaction) => true;

  @override
  bool deleteTransaction(int id) => true;

  @override
  bool toggleIgnoredStatus(int id, bool isIgnored) => true;

  @override
  double getTotalIncome({DateTime? start, DateTime? end}) => 0.0;

  @override
  double getTotalExpense({DateTime? start, DateTime? end}) => 0.0;

  @override
  double getNetBalance({DateTime? start, DateTime? end}) => 0.0;

  @override
  Map<String, double> getCategoryBreakdown({DateTime? start, DateTime? end}) => {};

  @override
  Map<String, double> getMonthlySpendTrend({int months = 6}) => {};

  @override
  Map<String, double> getTopMerchants({int limit = 5, DateTime? start, DateTime? end}) => {};
}

void main() {
  group('SplitBillService Tests', () {
    late SplitBillService service;
    late MockKhataRepository mockKhata;
    late MockTransactionRepository mockTxn;

    setUp(() {
      mockKhata = MockKhataRepository();
      mockTxn = MockTransactionRepository();
      service = SplitBillService(mockKhata, mockTxn);
    });

    test('Equal split divides amount evenly and compensates rounding remainder', () {
      final participants = [
        SplitParticipant(name: 'You', isCurrentUser: true),
        SplitParticipant(name: 'Aman'),
        SplitParticipant(name: 'Rohan'),
      ];

      // ₹1000 divided by 3: 333.33 each, remainder 0.01 added to first person
      final result = service.computeEqualShares(1000.0, participants);

      expect(result.length, 3);
      final sum = result.fold<double>(0.0, (prev, p) => prev + p.shareAmount);
      expect((sum - 1000.0).abs() < 0.001, isTrue);

      expect(result[0].shareAmount, 333.34);
      expect(result[1].shareAmount, 333.33);
      expect(result[2].shareAmount, 333.33);
    });

    test('Equal split handles clean division without remainder', () {
      final participants = [
        SplitParticipant(name: 'You', isCurrentUser: true),
        SplitParticipant(name: 'Aman'),
        SplitParticipant(name: 'Rohan'),
      ];

      final result = service.computeEqualShares(1500.0, participants);

      expect(result[0].shareAmount, 500.0);
      expect(result[1].shareAmount, 500.0);
      expect(result[2].shareAmount, 500.0);
      expect(result[0].percentage, closeTo(33.33, 0.1));
    });

    test('Percentage split calculates correct rupee shares', () {
      final participants = [
        SplitParticipant(name: 'You', isCurrentUser: true, percentage: 50.0),
        SplitParticipant(name: 'Priya', percentage: 25.0),
        SplitParticipant(name: 'Aditi', percentage: 25.0),
      ];

      final result = service.computePercentageShares(2000.0, participants);

      expect(result[0].shareAmount, 1000.0);
      expect(result[1].shareAmount, 500.0);
      expect(result[2].shareAmount, 500.0);
    });

    test('WhatsApp message includes description, amount, and NPCI UPI URI', () {
      final msg = service.generateWhatsAppMessage(
        friendName: 'Aman',
        amount: 450.0,
        description: 'Swiggy Dinner',
        upiId: 'rohit@okhdfcbank',
        payerName: 'Rohit',
      );

      expect(msg.contains('Hi Aman!'), isTrue);
      expect(msg.contains('₹450'), isTrue);
      expect(msg.contains('Swiggy Dinner'), isTrue);
      expect(msg.contains('upi://pay?pa=rohit@okhdfcbank'), isTrue);
      expect(msg.contains('am=450'), isTrue);
    });

    test('recordSplitBill creates Khata entries and records transaction successfully', () async {
      final participants = [
        SplitParticipant(name: 'You', isCurrentUser: true),
        SplitParticipant(name: 'Vikas', phoneNumber: '9876543210'),
        SplitParticipant(name: 'Neha', phoneNumber: '9876543211'),
      ];

      final request = SplitBillRequest(
        totalAmount: 900.0,
        title: 'Team Pizza',
        category: 'Food & Dining',
        mode: SplitMode.equal,
        participants: participants,
      );

      final result = await service.recordSplitBill(request);

      expect(result.success, isTrue);
      expect(result.createdKhataEntryIds.length, 2); // Vikas and Neha
      expect(mockKhata.contacts.length, 2);
      expect(mockKhata.entries.length, 2);
      expect(mockKhata.entries[0].amount, 300.0);
      expect(mockKhata.entries[0].isGave, isTrue); // "You gave"
      expect(mockTxn.transactions.length, 1);
      expect(mockTxn.transactions[0].amount, 300.0); // User's personal share
    });

    test('recordSplitBill validates exact mode sum discrepancy', () async {
      final participants = [
        SplitParticipant(name: 'You', isCurrentUser: true, shareAmount: 200.0),
        SplitParticipant(name: 'Vikas', shareAmount: 200.0),
      ];

      final request = SplitBillRequest(
        totalAmount: 500.0, // Mismatched with sum of 400
        title: 'Snacks',
        mode: SplitMode.exact,
        participants: participants,
      );

      final result = await service.recordSplitBill(request);

      expect(result.success, isFalse);
      expect(result.message.contains('do not match'), isTrue);
    });
  });
}
