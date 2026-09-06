import 'package:flutter/material.dart';

import '../../../../core/services/di/injection.dart';
import '../../../../data/models/transaction_entity.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../../../blocs/transactions/transactions_bloc.dart';
import '../ui/transactions_view.dart';
import '../ui/widgets/add_transaction_modal.dart';
import '../ui/widgets/transaction_detail_modal.dart';

class TransactionsController extends StatefulWidget {
  const TransactionsController({super.key});

  @override
  State<TransactionsController> createState() => TransactionsControllerState();
}

class TransactionsControllerState extends State<TransactionsController>
    with _TransactionsMixin {
  late final TransactionsBloc bloc;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    bloc = TransactionsBloc(sl<ITransactionRepository>());
    bloc.add(const LoadTransactionsEvent());
  }

  @override
  void dispose() {
    bloc.close();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TransactionsView(this);
  }
}

mixin _TransactionsMixin on State<TransactionsController> {
  TransactionsControllerState get _state => this as TransactionsControllerState;

  void onSearchChanged(String query) {
    final current = _state.bloc.state.data;
    _state.bloc.add(
      LoadTransactionsEvent(
        searchQuery: query,
        selectedCategory: current?.selectedCategory,
        selectedType: current?.selectedType,
        selectedPlatform: current?.selectedPlatform,
      ),
    );
  }

  void onTypeFilterChanged(String type) {
    final current = _state.bloc.state.data;
    _state.bloc.add(
      LoadTransactionsEvent(
        searchQuery: current?.searchQuery,
        selectedCategory: current?.selectedCategory,
        selectedType: type,
        selectedPlatform: current?.selectedPlatform,
      ),
    );
  }

  void onCategoryFilterChanged(String? category) {
    final current = _state.bloc.state.data;
    _state.bloc.add(
      LoadTransactionsEvent(
        searchQuery: current?.searchQuery,
        selectedCategory: category,
        selectedType: current?.selectedType,
        selectedPlatform: current?.selectedPlatform,
      ),
    );
  }

  void onTransactionTap(TransactionEntity txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailModal(
        transaction: txn,
        onDelete: () {
          _state.bloc.add(DeleteTransactionEvent(txn.id));
        },
      ),
    );
  }

  void onAddNewTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddTransactionModal(
        onSave: (txn) {
          _state.bloc.add(AddTransactionEvent(txn));
        },
      ),
    );
  }
}
