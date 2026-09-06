# 🏛️ Clean Architecture & BLoC Pattern Specification

Based on the `dream_team` architecture foundation, adapted for **BLoC state management** (replacing Cubit) and **ObjectBox local database**.

---

## 1. Clean Architecture Layers

```
lib/
├── core/
│   ├── base/
│   │   ├── bloc_base/                # BaseBloc<E, S>, BlocEventState<T>, BlocEvent
│   │   ├── base_controller/          # WidgetView<V, C> & Controller StatefulWidget
│   │   ├── base_use_case/            # BaseUseCase<Type, Params>
│   │   ├── base_service/             # BaseService interface
│   │   └── logger/                   # AppLogger
│   ├── services/
│   │   ├── objectbox_service/        # ObjectBox Store & Entity Boxes
│   │   ├── di/                       # get_it + injectable dependency registration
│   │   ├── route_service/            # go_router configuration & route names
│   │   ├── sms_parser_service/       # SMS Regex & Heuristic Parser
│   │   ├── sms_sync_service/         # SMS Inbox & Broadcast Sync Service
│   │   ├── pdf_export_service/       # PDF Statement & Report Exporter
│   │   └── notification_service/     # Local notifications for bill reminders
│   ├── constants/
│   │   ├── app_colors.dart           # Fintech palette tokens
│   │   ├── app_constants.dart        # Categories, platforms, banks
│   │   └── app_routes.dart           # Route paths
│   ├── theme/                        # Light & Dark themes
│   └── widgets/                      # Shared UI components
├── data/
│   ├── models/                       # ObjectBox Entities (@Entity)
│   │   ├── transaction_entity.dart
│   │   ├── khata_contact_entity.dart
│   │   ├── khata_entry_entity.dart
│   │   ├── bill_reminder_entity.dart
│   │   └── category_entity.dart
│   └── repositories/                 # Data repositories implementing domain interfaces
│       ├── transaction_repository.dart
│       ├── khata_repository.dart
│       └── reminder_repository.dart
├── domain/
│   ├── repositories/                 # Abstract repository contracts
│   └── usecases/                     # Isolated business logic use cases
└── presentation/
    ├── bloc_observer.dart            # Global BLoC logging & error tracking
    └── modules/                      # Feature modules (Controller + WidgetView)
        ├── dashboard/                # Main overview & spend meter
        ├── analytics/                # Dynamic interactive fl_chart
        ├── transactions/             # Search, filter & itemized list
        ├── khata/                    # KhataBook ledger & WhatsApp reminders
        ├── khata_detail/             # Contact-wise statement & settlement
        ├── reminders/                # Bill & payment alert manager
        ├── export_pdf/               # PDF statement generator
        └── sms_simulator/            # In-app SMS testing engine
```

---

## 2. BLoC Base Pattern

### `BaseBloc<Event, State>`
```dart
abstract class BaseBloc<E, S> extends Bloc<E, BlocEventState<S>> {
  BaseBloc() : super(BlocEventState.initial());

  void emitLoading({String? message}) {
    emit(state.copyWith(state: BlocState.loading, message: message));
  }

  void emitSuccess({S? data, String? message}) {
    emit(state.copyWith(state: BlocState.success, data: data, message: message));
  }

  void emitFailed({String? message, dynamic error}) {
    emit(state.copyWith(state: BlocState.failed, message: message, error: error));
  }

  void emitNoInternet({String? message}) {
    emit(state.copyWith(state: BlocState.noInternet, message: message));
  }

  void reset() {
    emit(BlocEventState.initial());
  }
}
```

---

## 3. Controller & View Pattern (MVVM / WidgetView)

Every screen is divided into:
1. **Controller (`StatefulWidget` + Mixin)**:
   - Holds the state, BLoC references, text controllers, lifecycle (`initState`, `dispose`), and user action handlers.
2. **View (`WidgetView<View, ControllerState>`)**:
   - Pure stateless UI rendering bound to the controller state and BLoC builders.

---

## 4. ObjectBox Local Storage

All financial records are stored locally using high-performance ObjectBox entities:
- `TransactionEntity`: `@Entity()`, indexed `date`, `category`, `platform`, `transactionId`.
- `KhataContactEntity`: `@Entity()`, linked to `ToMany<KhataEntryEntity>`.
- `KhataEntryEntity`: `@Entity()`, indexed `date`, with `ToOne<KhataContactEntity>`.
- `BillReminderEntity`: `@Entity()`, indexed `dueDate`.
