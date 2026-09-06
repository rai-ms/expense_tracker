import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/di/injection.dart';
import '../../../../core/services/event_bus/app_events.dart';
import '../../../../core/services/pdf_export_service/pdf_export_service.dart';
import '../../../../data/models/transaction_entity.dart';
import '../bloc/transactions_bloc.dart';
import '../models/saved_filter_preset.dart';
import '../ui/transactions_view.dart';
import '../ui/widgets/add_transaction_modal.dart';
import '../ui/widgets/manage_categories_modal.dart';
import '../ui/widgets/transaction_detail_modal.dart';
import '../ui/widgets/transaction_filter_modal.dart';

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
    bloc = sl<TransactionsBloc>();
    bloc.add(const LoadTransactionsEvent());
    AppEvents.syncNotifier.addListener(_onSyncData);
  }

  @override
  void dispose() {
    AppEvents.syncNotifier.removeListener(_onSyncData);
    bloc.close();
    searchController.dispose();
    super.dispose();
  }

  void _onSyncData() {
    if (mounted) {
      final currentCriteria = bloc.state.data?.criteria ?? const TransactionFilterCriteria();
      bloc.add(LoadTransactionsEvent(criteria: currentCriteria));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TransactionsView(this);
  }
}

mixin _TransactionsMixin on State<TransactionsController> {
  TransactionsControllerState get _state => this as TransactionsControllerState;

  void onSearchChanged(String query) {
    final current = _state.bloc.state.data?.criteria ?? const TransactionFilterCriteria();
    _state.bloc.add(
      LoadTransactionsEvent(
        criteria: current.copyWith(
          searchQuery: query.trim().isEmpty ? null : query.trim(),
        ),
      ),
    );
  }

  void onOpenFilterModal() {
    final data = _state.bloc.state.data;
    final currentCriteria = data?.criteria ?? const TransactionFilterCriteria();
    final categories = data?.availableCategories ?? [];
    final platforms = data?.availablePlatforms ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFilterModal(
        initialCriteria: currentCriteria,
        availableCategories: categories,
        availablePlatforms: platforms,
        onApply: (newCriteria) {
          _state.bloc.add(LoadTransactionsEvent(criteria: newCriteria));
        },
        onClear: onClearAllFilters,
      ),
    );
  }

  void onQuickDateFilterChanged(TransactionDateFilter filter) {
    final current = _state.bloc.state.data?.criteria ?? const TransactionFilterCriteria();
    _state.bloc.add(
      LoadTransactionsEvent(
        criteria: current.copyWith(dateFilter: filter),
      ),
    );
  }

  void onRemoveFilterTag(String filterType, [String? value]) {
    final current = _state.bloc.state.data?.criteria ?? const TransactionFilterCriteria();
    TransactionFilterCriteria updated = current;

    switch (filterType) {
      case 'date':
        updated = current.copyWith(dateFilter: TransactionDateFilter.thisMonth);
        break;
      case 'type':
        if (value != null) {
          final newTypes = Set<String>.from(current.types)..remove(value);
          updated = current.copyWith(types: newTypes);
        }
        break;
      case 'category':
        if (value != null) {
          final newCats = Set<String>.from(current.categories)..remove(value);
          updated = current.copyWith(categories: newCats);
        }
        break;
      case 'platform':
        if (value != null) {
          final newPlats = Set<String>.from(current.platforms)..remove(value);
          updated = current.copyWith(platforms: newPlats);
        }
        break;
      case 'amount':
        updated = current.copyWith(
          clearMinAmount: true,
          clearMaxAmount: true,
        );
        break;
      case 'sort':
        updated = current.copyWith(sortBy: TransactionSortBy.dateNewest);
        break;
      case 'mode':
        updated = current.copyWith(matchMode: FilterMatchMode.flexible);
        break;
    }

    _state.bloc.add(LoadTransactionsEvent(criteria: updated));
  }

  void onClearAllFilters() {
    _state.searchController.clear();
    _state.bloc.add(const LoadTransactionsEvent());
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

  void onOpenManageCategories() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManageCategoriesModal(
        onCategoriesChanged: () {
          _state._onSyncData();
        },
      ),
    );
  }

  void onApplyPreset(SavedFilterPreset preset) {
    _state.bloc.add(LoadTransactionsEvent(criteria: preset.criteria));
  }

  Future<void> onExportPdf() async {
    final data = _state.bloc.state.data;
    if (data == null || data.transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions available to export.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final criteria = data.criteria;
    final filterParts = <String>[];
    if (criteria.types.isNotEmpty) {
      filterParts.add('Types: ${criteria.types.join(", ")}');
    }
    if (criteria.categories.isNotEmpty) {
      filterParts.add('Categories: ${criteria.categories.join(", ")}');
    }
    if (criteria.platforms.isNotEmpty) {
      filterParts.add('Apps: ${criteria.platforms.join(", ")}');
    }
    if (criteria.minAmount != null || criteria.maxAmount != null) {
      final min = criteria.minAmount != null ? 'Min Rs.${criteria.minAmount!.toInt()}' : '';
      final max = criteria.maxAmount != null ? 'Max Rs.${criteria.maxAmount!.toInt()}' : '';
      filterParts.add([min, max].where((s) => s.isNotEmpty).join(' - '));
    }
    if (criteria.matchMode == FilterMatchMode.strict) {
      filterParts.add('Strict Match');
    }

    final filterSubtitle = filterParts.isEmpty ? null : filterParts.join(' • ');

    final doc = await PdfExportService.generateExpenseStatement(
      transactions: data.transactions,
      totalIncome: data.totalIncome,
      totalExpense: data.totalExpense,
      periodLabel: data.dateFilterLabel,
      startDate: data.startDate,
      endDate: data.endDate,
      filterSubtitle: filterSubtitle,
    );

    if (mounted) {
      PdfExportService.showPdfPreviewModal(
        context: context,
        document: doc,
        title: 'Export PDF Statement',
        fileName: 'SpendWise_Statement_${DateFormat("yyyyMMdd_HHmm").format(DateTime.now())}',
      );
    }
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

