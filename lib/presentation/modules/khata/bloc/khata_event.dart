part of 'khata_bloc.dart';

/// Base class for Khata events
abstract class KhataEvent extends BlocEvent {
  const KhataEvent();
}

/// Event to fetch all Khata contacts and net balances
class LoadKhataDataEvent extends KhataEvent {}

/// Event to add a new Khata contact
class AddKhataContactEvent extends KhataEvent {
  final KhataContactEntity contact;
  const AddKhataContactEvent(this.contact);

  @override
  List<Object?> get props => [contact];
}

/// Event to add a transaction entry to a contact's ledger
class AddKhataEntryEvent extends KhataEvent {
  final int contactId;
  final KhataEntryEntity entry;
  const AddKhataEntryEvent(this.contactId, this.entry);

  @override
  List<Object?> get props => [contactId, entry];
}

/// Event to settle all entries for a contact
class SettleKhataContactEvent extends KhataEvent {
  final int contactId;
  const SettleKhataContactEvent(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

/// Event to format and launch WhatsApp reminder message
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
