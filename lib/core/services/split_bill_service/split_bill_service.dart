import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/khata_contact_entity.dart';
import '../../../data/models/khata_entry_entity.dart';
import '../../../data/models/transaction_entity.dart';
import '../../../domain/repositories/i_khata_repository.dart';
import '../../../domain/repositories/i_transaction_repository.dart';
import '../../base/logger/app_logger.dart';
import '../event_bus/app_events.dart';
import '../objectbox_service/objectbox_service.dart';

enum SplitMode { equal, exact, percentage }

class SplitParticipant {
  final int? contactId;
  final String name;
  final String? phoneNumber;
  final bool isCurrentUser;
  double shareAmount;
  double percentage;

  SplitParticipant({
    this.contactId,
    required this.name,
    this.phoneNumber,
    this.isCurrentUser = false,
    this.shareAmount = 0.0,
    this.percentage = 0.0,
  });

  SplitParticipant copyWith({
    int? contactId,
    String? name,
    String? phoneNumber,
    bool? isCurrentUser,
    double? shareAmount,
    double? percentage,
  }) {
    return SplitParticipant(
      contactId: contactId ?? this.contactId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      shareAmount: shareAmount ?? this.shareAmount,
      percentage: percentage ?? this.percentage,
    );
  }
}

class SplitBillRequest {
  final double totalAmount;
  final String title;
  final String category;
  final SplitMode mode;
  final List<SplitParticipant> participants;
  final int? existingTransactionId;
  final String? note;

  SplitBillRequest({
    required this.totalAmount,
    required this.title,
    this.category = 'Food & Dining',
    this.mode = SplitMode.equal,
    required this.participants,
    this.existingTransactionId,
    this.note,
  });
}

class SplitBillResult {
  final bool success;
  final String message;
  final List<SplitParticipant> participants;
  final List<int> createdKhataEntryIds;
  final int? createdOrUpdatedTransactionId;

  SplitBillResult({
    required this.success,
    required this.message,
    required this.participants,
    this.createdKhataEntryIds = const [],
    this.createdOrUpdatedTransactionId,
  });
}

@lazySingleton
class SplitBillService {
  static const String _prefUserUpiKey = 'user_default_upi_id';
  static const String _prefUserNameKey = 'user_display_name';

  final IKhataRepository _khataRepository;
  final ITransactionRepository _transactionRepository;

  SplitBillService(this._khataRepository, this._transactionRepository);

  /// Get configured User UPI ID for payment links
  String getUserUpiId() {
    return ObjectBoxService.instance.getSetting(_prefUserUpiKey, defaultValue: '') ?? '';
  }

  /// Save User UPI ID
  Future<void> setUserUpiId(String upiId) async {
    ObjectBoxService.instance.setSetting(_prefUserUpiKey, upiId.trim());
  }

  /// Get configured User Name
  String getUserDisplayName() {
    return ObjectBoxService.instance.getSetting(_prefUserNameKey, defaultValue: 'You') ?? 'You';
  }

  /// Save User Name
  Future<void> setUserDisplayName(String name) async {
    ObjectBoxService.instance.setSetting(_prefUserNameKey, name.trim());
  }

  /// Compute equal shares with rounding compensation so the total matches exactly
  List<SplitParticipant> computeEqualShares(double totalAmount, List<SplitParticipant> participants) {
    if (participants.isEmpty) return [];
    if (totalAmount <= 0) {
      return participants.map((p) => p.copyWith(shareAmount: 0.0, percentage: 0.0)).toList();
    }

    final count = participants.length;
    final rawShare = (totalAmount / count);
    // Round to 2 decimal places
    final roundedShare = (rawShare * 100).floor() / 100.0;
    final totalAllocated = roundedShare * count;
    final remainder = double.parse((totalAmount - totalAllocated).toStringAsFixed(2));

    final result = <SplitParticipant>[];
    for (int i = 0; i < count; i++) {
      final p = participants[i];
      // Allocate the fractional cent/paisa remainder to the first participant ("You")
      final share = (i == 0) ? (roundedShare + remainder) : roundedShare;
      final percent = (share / totalAmount) * 100.0;
      result.add(p.copyWith(shareAmount: share, percentage: percent));
    }
    return result;
  }

  /// Compute percentage shares based on custom percentages
  List<SplitParticipant> computePercentageShares(double totalAmount, List<SplitParticipant> participants) {
    if (participants.isEmpty) return [];
    final result = <SplitParticipant>[];
    for (final p in participants) {
      final share = (p.percentage / 100.0) * totalAmount;
      result.add(p.copyWith(shareAmount: double.parse(share.toStringAsFixed(2))));
    }
    return result;
  }

  /// Record Split Bill: Creates Khata "Gave" entries for friends and records/adjusts user's personal expense
  Future<SplitBillResult> recordSplitBill(SplitBillRequest request) async {
    try {
      if (request.participants.isEmpty) {
        return SplitBillResult(
          success: false,
          message: 'At least one participant is required',
          participants: request.participants,
        );
      }

      if (request.totalAmount <= 0) {
        return SplitBillResult(
          success: false,
          message: 'Total amount must be greater than zero',
          participants: request.participants,
        );
      }

      // 1. Calculate and validate shares based on mode
      List<SplitParticipant> calculatedParticipants;
      switch (request.mode) {
        case SplitMode.equal:
          calculatedParticipants = computeEqualShares(request.totalAmount, request.participants);
          break;
        case SplitMode.exact:
          final sum = request.participants.fold<double>(0.0, (prev, p) => prev + p.shareAmount);
          if ((sum - request.totalAmount).abs() > 0.05) {
            return SplitBillResult(
              success: false,
              message: 'Participant shares (₹$sum) do not match total bill amount (₹${request.totalAmount})',
              participants: request.participants,
            );
          }
          calculatedParticipants = request.participants;
          break;
        case SplitMode.percentage:
          final pctSum = request.participants.fold<double>(0.0, (prev, p) => prev + p.percentage);
          if ((pctSum - 100.0).abs() > 0.5) {
            return SplitBillResult(
              success: false,
              message: 'Total percentages ($pctSum%) must equal 100%',
              participants: request.participants,
            );
          }
          calculatedParticipants = computePercentageShares(request.totalAmount, request.participants);
          break;
      }

      final createdKhataEntryIds = <int>[];
      int? transactionId = request.existingTransactionId;

      // Identify current user's share
      final userParticipant = calculatedParticipants.firstWhere(
        (p) => p.isCurrentUser,
        orElse: () => calculatedParticipants.first,
      );
      final userShare = userParticipant.shareAmount;

      // 2. Handle SpendWise Transaction
      if (transactionId != null) {
        // Splitting an existing recorded transaction
        final existingTxn = _transactionRepository.getAllTransactions().firstWhere(
          (t) => t.id == transactionId,
          orElse: () => throw Exception('Transaction not found'),
        );
        final updatedNote = existingTxn.notes != null && existingTxn.notes!.isNotEmpty
            ? '${existingTxn.notes} | Split: ${request.title} (Your share: ₹${userShare.toStringAsFixed(0)})'
            : 'Split: ${request.title} (Your share: ₹${userShare.toStringAsFixed(0)})';
        existingTxn.notes = updatedNote;
        _transactionRepository.updateTransaction(existingTxn);
      } else {
        // Creating a new transaction for user's share
        final newTxn = TransactionEntity(
          uid: const Uuid().v4(),
          amount: userShare,
          type: 'debit',
          category: request.category,
          merchant: request.title,
          notes: 'Split Bill: ${request.title} (Total ₹${request.totalAmount.toStringAsFixed(0)})',
          date: DateTime.now().millisecondsSinceEpoch,
          isAutomated: false,
        );
        transactionId = _transactionRepository.addTransaction(newTxn);
      }

      // 3. Create Khata Entries for Friends (You gave them their share)
      for (final p in calculatedParticipants) {
        if (p.isCurrentUser || p.shareAmount <= 0) continue;

        int contactId;
        if (p.contactId != null && p.contactId! > 0) {
          contactId = p.contactId!;
        } else {
          // Check if contact with same name exists
          final existingContact = _khataRepository.getAllContacts().where(
            (c) => c.name.toLowerCase() == p.name.trim().toLowerCase(),
          ).firstOrNull;

          if (existingContact != null) {
            contactId = existingContact.id;
          } else {
            // Create new Khata contact
            final newContact = KhataContactEntity(
              uid: const Uuid().v4(),
              name: p.name.trim(),
              phoneNumber: p.phoneNumber?.trim(),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            );
            contactId = _khataRepository.addContact(newContact);
          }
        }

        final entry = KhataEntryEntity(
          uid: const Uuid().v4(),
          amount: p.shareAmount,
          type: 'gave', // You gave / They owe you
          date: DateTime.now().millisecondsSinceEpoch,
          notes: 'Split Bill: ${request.title}',
          transactionId: transactionId.toString(),
        );

        final entryId = _khataRepository.addEntry(contactId, entry);
        createdKhataEntryIds.add(entryId);
      }

      // Notify entire app of data changes
      AppEvents.notifyDataChanged();

      return SplitBillResult(
        success: true,
        message: 'Bill split recorded successfully across ${calculatedParticipants.length} people!',
        participants: calculatedParticipants,
        createdKhataEntryIds: createdKhataEntryIds,
        createdOrUpdatedTransactionId: transactionId,
      );
    } catch (e, stack) {
      Log.e('Error recording split bill', error: e, stackTrace: stack);
      return SplitBillResult(
        success: false,
        message: 'Failed to record split bill: $e',
        participants: request.participants,
      );
    }
  }

  /// Generate WhatsApp reminder message with UPI deep link
  String generateWhatsAppMessage({
    required String friendName,
    required double amount,
    required String description,
    String? upiId,
    String? payerName,
  }) {
    final effectiveUpi = upiId ?? getUserUpiId();
    final effectivePayer = payerName ?? getUserDisplayName();
    final formattedAmount = amount.toStringAsFixed(0);

    final buffer = StringBuffer();
    buffer.writeln('Hi $friendName! 👋');
    buffer.writeln('Your share for *$description* is *₹$formattedAmount*.');
    buffer.writeln();

    if (effectiveUpi.isNotEmpty) {
      // Build standard NPCI UPI payment deep link
      final noteEncoded = Uri.encodeComponent(description);
      final payerEncoded = Uri.encodeComponent(effectivePayer);
      final upiUri = 'upi://pay?pa=$effectiveUpi&pn=$payerEncoded&am=$formattedAmount&cu=INR&tn=$noteEncoded';
      buffer.writeln('Pay directly using UPI:');
      buffer.writeln(upiUri);
      buffer.writeln('(or pay to UPI ID: `$effectiveUpi`)');
      buffer.writeln();
    }

    buffer.writeln('Shared via SpendWise 💸');
    return buffer.toString();
  }

  /// Share reminder via WhatsApp or system share dialog
  Future<void> shareReminder({
    required String friendName,
    required double amount,
    required String description,
    String? phoneNumber,
    String? upiId,
  }) async {
    final message = generateWhatsAppMessage(
      friendName: friendName,
      amount: amount,
      description: description,
      upiId: upiId,
    );

    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      // Format with country code if needed (default India +91 if 10 digits)
      final phoneWithCode = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
      final whatsappUrl = Uri.parse('whatsapp://send?phone=$phoneWithCode&text=${Uri.encodeComponent(message)}');
      final webWhatsappUrl = Uri.parse('https://wa.me/$phoneWithCode?text=${Uri.encodeComponent(message)}');

      try {
        if (await canLaunchUrl(whatsappUrl)) {
          await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
          return;
        } else if (await canLaunchUrl(webWhatsappUrl)) {
          await launchUrl(webWhatsappUrl, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        Log.w('Could not launch WhatsApp directly: $e');
      }
    }

    // Fallback to native share sheet
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'Bill Split Reminder - $description',
      ),
    );
  }
}
