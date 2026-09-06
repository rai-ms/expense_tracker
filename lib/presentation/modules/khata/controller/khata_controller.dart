import 'package:flutter/material.dart';

import '../../../../core/services/di/injection.dart';
import '../../../../data/models/khata_contact_entity.dart';
import '../../../../domain/repositories/i_khata_repository.dart';
import '../../../blocs/khata/khata_bloc.dart';
import '../../khata_detail/controller/khata_detail_controller.dart';
import '../ui/khata_view.dart';
import '../ui/widgets/add_contact_modal.dart';
import '../ui/widgets/add_entry_modal.dart';

class KhataController extends StatefulWidget {
  const KhataController({super.key});

  @override
  State<KhataController> createState() => KhataControllerState();
}

class KhataControllerState extends State<KhataController> with _KhataMixin {
  late final KhataBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = KhataBloc(sl<IKhataRepository>());
    bloc.add(LoadKhataDataEvent());
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KhataView(this);
  }
}

mixin _KhataMixin on State<KhataController> {
  KhataControllerState get _state => this as KhataControllerState;

  void onAddNewContact() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddContactModal(
        onSave: (contact) {
          _state.bloc.add(AddKhataContactEvent(contact));
        },
      ),
    );
  }

  Future<void> onContactTap(KhataContactEntity contact) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KhataDetailController(contactId: contact.id),
      ),
    );
    _state.bloc.add(LoadKhataDataEvent());
  }

  void onAddEntry(KhataContactEntity contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddEntryModal(
        contact: contact,
        onSave: (entry) {
          _state.bloc.add(AddKhataEntryEvent(contact.id, entry));
        },
      ),
    );
  }

  void onSettleContact(KhataContactEntity contact) {
    _state.bloc.add(SettleKhataContactEvent(contact.id));
  }
}
