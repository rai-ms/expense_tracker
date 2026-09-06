import '../../core/services/objectbox_service/objectbox_service.dart';
import '../../domain/repositories/i_khata_repository.dart';
import '../../objectbox.g.dart';
import '../models/khata_contact_entity.dart';
import '../models/khata_entry_entity.dart';

class KhataRepositoryImpl implements IKhataRepository {
  final ObjectBoxService _boxService;

  KhataRepositoryImpl(this._boxService);

  @override
  List<KhataContactEntity> getAllContacts() {
    final query = _boxService.khataContactBox.query()
      ..order(KhataContactEntity_.name);
    final q = query.build();
    final results = q.find();
    q.close();
    return results;
  }

  @override
  KhataContactEntity? getContactById(int id) {
    return _boxService.khataContactBox.get(id);
  }

  @override
  KhataContactEntity? getContactByUid(String uid) {
    final query = _boxService.khataContactBox.query(
      KhataContactEntity_.uid.equals(uid),
    ).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  @override
  int addContact(KhataContactEntity contact) {
    return _boxService.khataContactBox.put(contact);
  }

  @override
  bool updateContact(KhataContactEntity contact) {
    _boxService.khataContactBox.put(contact);
    return true;
  }

  @override
  bool deleteContact(int id) {
    return _boxService.khataContactBox.remove(id);
  }

  @override
  List<KhataEntryEntity> getEntriesForContact(int contactId) {
    final contact = getContactById(contactId);
    if (contact == null) return [];
    final entries = contact.entries.toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  int addEntry(int contactId, KhataEntryEntity entry) {
    final contact = getContactById(contactId);
    if (contact == null) return 0;

    entry.contact.target = contact;
    final entryId = _boxService.khataEntryBox.put(entry);
    contact.entries.add(entry);
    _boxService.khataContactBox.put(contact);
    return entryId;
  }

  @override
  bool settleEntry(int entryId) {
    final entry = _boxService.khataEntryBox.get(entryId);
    if (entry == null) return false;
    entry.isSettled = true;
    _boxService.khataEntryBox.put(entry);
    return true;
  }

  @override
  bool settleAllEntriesForContact(int contactId) {
    final contact = getContactById(contactId);
    if (contact == null) return false;

    for (final entry in contact.entries) {
      entry.isSettled = true;
      _boxService.khataEntryBox.put(entry);
    }
    return true;
  }

  @override
  bool deleteEntry(int entryId) {
    return _boxService.khataEntryBox.remove(entryId);
  }

  @override
  double getTotalWillReceive() {
    final contacts = getAllContacts();
    double total = 0.0;
    for (final contact in contacts) {
      final balance = contact.netBalance;
      if (balance > 0) total += balance;
    }
    return total;
  }

  @override
  double getTotalWillGive() {
    final contacts = getAllContacts();
    double total = 0.0;
    for (final contact in contacts) {
      final balance = contact.netBalance;
      if (balance < 0) total += balance.abs();
    }
    return total;
  }
}
