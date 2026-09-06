# 🚀 Master Project Plan & Roadmap: Expense Tracker & KhataBook

An enterprise-grade, offline-first Flutter application featuring real-time SMS sync & parsing, KhataBook (Udhar-Jama ledger), dynamic interactive charts, payment reminders, platform auto-detection, and PDF statement export.

---

## 📑 Tech Stack & Latest Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| `flutter_bloc` | `^9.1.0` | State Management with BaseBloc pattern |
| `get_it` | `^9.2.1` | Dependency Injection & Service Locator |
| `injectable` | `^3.0.0` | Code-generated DI configuration |
| `objectbox` | `^5.3.2` | High-performance local ObjectBox database |
| `objectbox_flutter_libs` | `^5.3.2` | Native C bindings for ObjectBox |
| `go_router` | `^18.0.1` | Declarative URL-based routing |
| `fl_chart` | `^1.2.0` | Dynamic Donut, Spline, and Bar charts |
| `pdf` | `^3.13.0` | High-quality printable PDF statements |
| `printing` | `^5.15.0` | Direct printing & PDF preview widget |
| `share_plus` | `^13.3.0` | Native file & text share sheet |
| `flutter_local_notifications` | `^22.3.0` | Scheduled bill reminder alerts |
| `permission_handler` | `^13.0.2` | Runtime SMS & notification permissions |
| `google_fonts` | `^8.2.1` | Modern typography (Outfit) |
| `flutter_secure_storage` | `^11.0.0` | Secure encrypted key-value storage |
| `shimmer` | `^4.0.0` | Skeleton loading effects |
| `timezone` | `^0.11.1` | Timezone scheduling for reminders |
| `uuid` | `^4.5.1` | Unique ID generation |
| `intl` | `^0.20.2` | Currency and date formatting |

---

## 🏛️ Clean Architecture Structure

```
lib/
├── core/
│   ├── base/
│   │   ├── bloc_base/                # BaseBloc<E, S>, BlocEventState<T>, BlocEvent
│   │   ├── base_controller/          # WidgetView<V, C> & Controller StatefulWidget
│   │   ├── base_use_case/            # UseCase<T, P>
│   │   └── logger/                   # AppLogger (Log.d, Log.i, Log.e)
│   ├── constants/
│   │   ├── app_colors.dart           # Fintech dark/light palette tokens
│   │   ├── app_constants.dart        # 10+ categories with icons & supported platforms
│   │   └── app_routes.dart           # GoRouter named routes
│   ├── theme/
│   │   └── app_theme.dart            # Material 3 Dark & Light theme
│   └── services/
│       ├── objectbox_service/        # ObjectBox store & entity boxes
│       ├── di/                       # GetIt service locator setup
│       ├── route_service/            # GoRouter configuration
│       ├── sms_parser_service/       # Bank & UPI SMS Regex/Heuristics engine
│       ├── sms_sync_service/         # Inbox query & 15+ SMS test templates
│       ├── pdf_export_service/       # PDF Statement & Khata Report generator
│       ├── notification_service/     # Local bill reminder notifications
│       └── permission_service/       # Android SMS & notification permissions
├── data/
│   ├── models/                       # ObjectBox Entities (@Entity)
│   │   ├── transaction_entity.dart   # Transactions with UTR, Platform, Category
│   │   ├── khata_contact_entity.dart # Khata contacts with ToMany relations
│   │   ├── khata_entry_entity.dart   # Gave/Got ledger entries
│   │   └── bill_reminder_entity.dart # Scheduled bill dues
│   └── repositories/
│       ├── transaction_repository_impl.dart
│       ├── khata_repository_impl.dart
│       └── reminder_repository_impl.dart
├── domain/
│   └── repositories/                 # Abstract contracts (ITransactionRepository, etc.)
└── presentation/
    ├── bloc_observer.dart            # Global AppBlocObserver
    ├── my_app/my_app.dart            # Root MaterialApp.router
    └── modules/
        ├── splash/                   # Animated splash screen with auto-routing
        ├── main_navigation/          # Bottom navigation shell (5 tabs)
        ├── dashboard/                # Balance KPI cards, spend meter, quick actions
        ├── analytics/                # Dynamic interactive fl_chart (Donut, Spline)
        ├── transactions/             # Search, filter chips, transaction details
        ├── khata/                    # Udhar-Jama ledger & 1-click WhatsApp reminders
        ├── reminders/                # Scheduled bill dues with paid toggles
        ├── sms_simulator/            # In-app SMS tester & demo data injector
        └── export_pdf/               # PDF financial statement preview & share
```
