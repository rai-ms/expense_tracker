import 'package:url_launcher/url_launcher.dart';
import '../../../core/base/bloc_base/base_bloc.dart';
import '../../../core/base/bloc_base/bloc_event.dart';
import '../../../core/base/logger/app_logger.dart';
import '../../../data/models/khata_contact_entity.dart';
import '../../../data/models/khata_entry_entity.dart';
import '../../../domain/repositories/i_khata_repository.dart';

// Khata Events
abstract class KhataEvent extends BlocEvent {
  const KhataEvent();
}

class LoadKhataDataEvent extends KhataEvent {}

class AddKhataContactEvent extends KhataEvent {
  final KhataContactEntity contact;
  const AddKhataContactEvent(this.contact);

  @override
  List<Object?> get props => [contact];
}

class AddKhataEntryEvent extends KhataEvent {
  final int contactId;
  final KhataEntryEntity entry;
  const AddKhataEntryEvent(this.contactId, this.entry);

  @override
  List<Object?> get props => [contactId, entry];
}

class SettleKhataContactEvent extends KhataEvent {
  final int contactId;
  const SettleKhataContactEvent(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

class SendWhatsAppReminderEvent extends KhataEvent {
  final KhataContactEntity contact;
  final double amount;
  final String? upiId;

  const SendWhatsAppReminderEvent({
    required this.contact,
    required this.amount,
    this.upiId,
  });

  @override
  List<Object?> get props => [contact, amount, upiId];
}

// Khata State Data
class KhataData {
  final List<KhataContactEntity> contacts;
  final double totalWillReceive;
  final double totalWillGive;

  const KhataData({
    required this.contacts,
    required this.totalWillReceive,
    required this.totalWillGive,
  });
}

// Khata BLoC
class KhataBloc extends BaseBloc<KhataEvent, KhataData> {
  final IKhataRepository _khataRepository;

  KhataBloc(this._khataRepository) {
    on<LoadKhataDataEvent>(_onLoadKhataData);
    on<AddKhataContactEvent>(_onAddKhataContact);
    on<AddKhataEntryEvent>(_onAddKhataEntry);
    on<SettleKhataContactEvent>(_onSettleKhataContact);
    on<SendWhatsAppReminderEvent>(_onSendWhatsAppReminder);
  }

  void _onLoadKhataData(
    LoadKhataDataEvent event,
    dynamic emit,
  ) {
    emitLoading();
    try {
      final contacts = _khataRepository.getAllContacts();
      final totalWillReceive = _khataRepository.getTotalWillReceive();
      final totalWillGive = _khataRepository.getTotalWillGive();

      emitSuccess(
        data: KhataData(
          contacts: contacts,
          totalWillReceive: totalWillReceive,
          totalWillGive: totalWillGive,
        ),
      );
    } catch (e) {
      emitFailed(message: 'Failed to load Khata ledger: $e');
    }
  }

  void _onAddKhataContact(
    AddKhataContactEvent event,
    dynamic emit,
  ) {
    try {
      _khataRepository.addContact(event.contact);
      add(LoadKhataDataEvent());
    } catch (e) {
      emitFailed(message: 'Failed to add contact: $e');
    }
  }

  void _onAddKhataEntry(
    AddKhataEntryEvent event,
    dynamic emit,
  ) {
    try {
      _khataRepository.addEntry(event.contactId, event.entry);
      add(LoadKhataDataEvent());
    } catch (e) {
      emitFailed(message: 'Failed to add ledger entry: $e');
    }
  }

  void _onSettleKhataContact(
    SettleKhataContactEvent event,
    dynamic emit,
  ) {
    try {
      _khataRepository.settleAllEntriesForContact(event.contactId);
      add(LoadKhataDataEvent());
    } catch (e) {
      emitFailed(message: 'Failed to settle contact: $e');
    }
  }

  Future<void> _onSendWhatsAppReminder(
    SendWhatsAppReminderEvent event,
    dynamic emit,
  ) async {
    try {
      final phone = event.contact.phoneNumber?.replaceAll(RegExp(r'\D'), '') ?? '';
      final msg = Uri.encodeComponent(
        '🙏 Namaste ${event.contact.name},\n\n'
        'This is a friendly reminder regarding our pending balance of ₹${event.amount.toStringAsFixed(2)}.\n\n'
        'Kindly settle at your earliest convenience.\n'
        '${event.upiId != null && event.upiId!.isNotEmpty ? "Pay via UPI: ${event.upiId}\n" : ""}'
        'Thank you!\nSent via SpendWise Expense Tracker',
      );

      final url = Uri.parse(
        phone.isNotEmpty
            ? 'https://wa.me/$phone?text=$msg'
            : 'https://wa.me/?text=$msg',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Log.w('Could not launch WhatsApp');
      }
    } catch (e) {
      Log.e('Error opening WhatsApp reminder', error: e);
    }
  }
}
