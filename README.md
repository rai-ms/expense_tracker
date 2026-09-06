# 💰 Smart Expense Tracker & KhataBook (Flutter)

A high-performance, dynamic Flutter application combining **Automated Real-Time SMS Expense Tracking** (for Indian Banks & UPI apps) and a full-fledged **KhataBook (Digital Udhar-Jama Ledger)** with dynamic analytics, bill reminders, and PDF statement generation.

---

## 🚀 Key Features

### 1. 📱 Real-Time & Historical SMS Expense Tracking
- **Smart SMS Regex Engine**: Automatically extracts Amount, Transaction Type (Debit/Credit), Merchant / Sender, Bank / UPI source (HDFC, SBI, ICICI, Axis, Paytm, PhonePe, GPay, Cred, Zerodha, etc.), Account Digits, and UTR/Txn IDs.
- **Auto Categorization**: Classifies transactions into Food & Dining, Groceries, Shopping, Travel & Commute, Entertainment, Bills & Utilities, Investment, Salary, etc.
- **Date Range & Calendar Backfill Sync**: Pick any start date from the past to backfill transactions from SMS inbox.
- **In-App SMS Simulator**: Test SMS parsing without a physical SIM card using 15+ curated Indian banking SMS templates or custom input.

### 2. 📖 KhataBook (Digital Udhar-Jama Ledger)
- **Dual Balance Tracking**: Tracks Net Balance with distinct *"Aapko Milenge (You Will Receive)"* and *"Aapko Dene Hain (You Will Give)"* indicators.
- **Dedicated Contact Detail Page**: Complete ledger history timeline with settled badges, notes, and timestamps.
- **Signature Dual-Action Bottom Bar**: Instant **"YOU GAVE ₹ (Maine Diye)"** [Red] & **"YOU GOT ₹ (Mujhe Mile)"** [Green] entry logging.
- **1-Click WhatsApp Reminders**: Direct WhatsApp message generation with pending balance and UPI payment intent.
- **Settle Account & Delete Actions**: One-tap settlement of outstanding balances.

### 3. 📊 Dynamic Visual Analytics & Charts
- **Category Donut / Pie Chart** powered by `fl_chart` with interactive percentage breakdowns.
- **6-Month Spend Trend Area Spline Chart** displaying month-over-month debit vs credit trajectories.
- **Top Merchant Breakdown** with rank, volume, and percentage impact.

### 4. ⏰ Bill Reminders & Alerts
- Local notification reminders for utility bills, credit cards, EMI, rent, and subscriptions.
- Due date timeline tracking (Overdue, Due Today, Due This Week, Upcoming).

### 5. 📄 PDF Statement Exporter & Sharing
- Export monthly expense statements and Khata contact ledger statements to formatted PDFs.
- 1-click share via WhatsApp, Email, or Print.

---

## 🏗️ Architecture & Tech Stack

- **Pattern**: Clean Architecture (`core/`, `data/`, `domain/`, `presentation/`) with Controller-View separation (`WidgetView`).
- **State Management**: BLoC Pattern (`BaseBloc<Event, State>` extending `flutter_bloc`).
- **Local Storage**: [ObjectBox](https://objectbox.io/) (High performance, offline-first NoSQL/relational embedded database).
- **Navigation**: `go_router`
- **Charts**: `fl_chart`
- **Notifications**: `flutter_local_notifications`
- **PDF & Export**: `pdf` & `printing` & `share_plus`
- **Dependency Injection**: `get_it`

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK (3.x or higher)
- Android SDK (compileSdk 37) / Xcode for iOS / macOS

### Setup & Run
```bash
# Clone the repository
git clone https://github.com/rai-ms/expense_tracker.git
cd expense_tracker

# Get dependencies
flutter pub get

# Generate ObjectBox code (if needed)
dart run build_runner build --delete-conflicting-outputs

# Run on your connected device or simulator
flutter run
```

### Build Release APK
```bash
flutter build apk --release
```

