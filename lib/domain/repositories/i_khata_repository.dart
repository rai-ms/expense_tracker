import '../../data/models/khata_contact_entity.dart';
import '../../data/models/khata_entry_entity.dart';

abstract class IKhataRepository {
  const IKhataRepository();

  List<KhataContactEntity> getAllContacts();
  KhataContactEntity? getContactById(int id);
  KhataContactEntity? getContactByUid(String uid);
  int addContact(KhataContactEntity contact);
  bool updateContact(KhataContactEntity contact);
  bool deleteContact(int id);

  List<KhataEntryEntity> getEntriesForContact(int contactId);
  int addEntry(int contactId, KhataEntryEntity entry);
  bool settleEntry(int entryId);
  bool settleAllEntriesForContact(int contactId);
  bool deleteEntry(int entryId);

  // Overall Khata statistics
  double getTotalWillReceive(); // Sum of positive contact balances
  double getTotalWillGive();    // Sum of negative contact balances (absolute)
}
