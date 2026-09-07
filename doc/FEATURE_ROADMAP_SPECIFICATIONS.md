# 🚀 SpendWise: Master Feature Roadmap & Technical Specifications

> **Application**: SpendWise (formerly Expense Tracker)  
> **Architecture**: Clean Architecture + BLoC (`flutter_bloc ^9.1.0`) + ObjectBox (`^5.3.2`) + GetIt / Injectable  
> **Status**: Comprehensive Engineering Specification for the Next 8 High-Impact Features  

---

## 📋 Executive Feature Matrix

| # | Feature | Impact | Complexity | Dependencies | Est. Time |
|---|---|:---:|:---:|---|:---:|
| 1 | **Biometric Lock & Privacy Mode** | 🔴 Critical | Medium | `local_auth`, `flutter_secure_storage` | 1-2 Days |
| 2 | **Category Budgets & Alerts** | 🔴 Critical | Low-Medium | `flutter_local_notifications` | 1-2 Days |
| 3 | **Bill & Receipt Attachments** | 🟡 High | Medium | `image_picker`, `path_provider` | 2 Days |
| 4 | **Split Bill / Group Expenses** | 🟡 High | Medium | Built-in KhataBook integration | 2-3 Days |
| 5 | **1-Tap Offline Backup & Restore** | 🔴 Critical | Medium | `archive`, `share_plus`, `file_picker` | 2 Days |
| 6 | **Excel (.xlsx) & CSV Exporter** | 🟢 Medium | Low | `excel`, `csv`, `share_plus` | 1 Day |
| 7 | **Subscriptions Tracker** | 🟡 High | Medium | `flutter_local_notifications` | 2 Days |
| 8 | **Spending Insights & Health Score** | 🟢 Medium | Low-Medium | Pure Dart Heuristics Engine | 1-2 Days |

---

## 1. 🔒 Biometric Lock & Privacy Mode (Security Pillar)

### 1.1 Overview & Value Proposition
Financial and ledger apps contain sensitive personal transactions. Biometric Lock ensures unauthorized persons cannot access transaction data if the phone is unlocked or shared. Privacy mode allows users to hide account numbers and balances when opening the app in public.

### 1.2 Technical Stack
- `local_auth: ^2.3.0` (Fingerprint, TouchID, FaceID)
- `flutter_secure_storage: ^11.0.0` (Encrypted 4-digit fallback PIN storage)

### 1.3 Data Model & Storage
Stored securely in `FlutterSecureStorage`:
- `key_biometric_enabled`: `bool`
- `key_app_pin`: `String` (Hashed with salt via SHA-256)
- `key_lock_timeout`: `int` (Seconds before locking on background, e.g., `0` for immediately, `30`, `60`, `300`)
- `key_privacy_mode`: `bool` (Mask balances with `••••`)

### 1.4 Architecture & UI Flow
```
App Launch / App Resumed (WidgetsBindingObserver)
       │
       ▼
Is Biometric/PIN Enabled?
 ├── NO ──► Continue to Dashboard
 └── YES ─► Check Last Unlock Timestamp
             ├── Within Timeout ──► Continue to Dashboard
             └── Expired ─────────► Show LockScreenView (Blur effect)
                                      ├── Biometric Prompt (Fingerprint/Face)
                                      │    ├── Success ──► Dismiss & Update Timestamp
                                      │    └── Failed  ──► Allow 4-Digit Fallback PIN
                                      └── 5 Failed PINs ─► 30s Cooldown
```

### 1.5 Privacy Mode ("Eye" Toggle on Dashboard)
- An Eye icon (`Icons.visibility` / `Icons.visibility_off`) on the Dashboard Balance Card.
- When enabled, all KPI totals (`₹1,24,500` $\to$ `₹ ••••••`) and list amounts are masked. State persisted across sessions.

---

## 2. 🎯 Category-wise Monthly Budgets & Overspend Alerts

### 2.1 Overview & Value Proposition
Allows users to set strict or advisory spending caps on individual categories (e.g., Food: ₹8,000, Shopping: ₹5,000) and track consumption in real-time with color-coded alerts (Green $\to$ Amber $\to$ Red).

### 2.2 ObjectBox Entity (`BudgetEntity`)
```dart
@Entity()
class BudgetEntity {
  @Id()
  int id = 0;

  @Index()
  String categoryId; // 'food', 'shopping', 'travel', etc.
  
  double monthlyLimit; // e.g., 8000.00
  int month;           // 1 - 12
  int year;            // 2026
  
  bool alertAt80Percent;  // Default: true
  bool alertAt100Percent; // Default: true
  bool isAlert80Sent;
  bool isAlert100Sent;

  BudgetEntity({
    this.id = 0,
    required this.categoryId,
    required this.monthlyLimit,
    required this.month,
    required this.year,
    this.alertAt80Percent = true,
    this.alertAt100Percent = true,
    this.isAlert80Sent = false,
    this.isAlert100Sent = false,
  });
}
```

### 2.3 Visual Spend Meters
- **< 75% Spent**: Sleek Primary Gradient / Forest Green (`AppColors.creditGreen`)
- **75% - 95% Spent**: Caution Amber (`AppColors.warningAmber`)
- **> 95% Spent / Exceeded**: Glowing Crimson (`AppColors.debitRed`) + Vibration alert
- Displays: `"₹6,400 of ₹8,000 (80%) • ₹1,600 Left • 14 days remaining"`

### 2.4 Proactive Notifications
When a transaction is parsed or added:
1. Recalculate category total for the current month.
2. If `total >= limit * 0.8` and `!isAlert80Sent`:
   - Trigger local notification: *"⚠️ Warning: You have reached 80% of your Food budget (₹6,400 / ₹8,000)."*
3. If `total >= limit` and `!isAlert100Sent`:
   - Trigger local notification: *"🚨 Alert: You have exceeded your Food budget for September!"*

---

## 3. 📸 Bill & Receipt Photo Attachments (Receipt Vault)

### 3.1 Overview & Value Proposition
Users frequently need receipts for tax filing, warranties, business reimbursements, or Khata evidence. This feature lets users attach multiple photos/receipts directly to any expense or Khata transaction.

### 3.2 Technical Stack
- `image_picker: ^1.1.2` (Camera capture & Gallery picker)
- `path_provider: ^2.1.5` (Local sandbox directory storage)

### 3.3 Storage Strategy
- Photos are compressed (JPEG 85% quality, max dimensions 1920x1080) to save disk space.
- Stored locally inside `app_flutter/receipts/{txn_uid}_{timestamp}.jpg`.
- Database stores relative file paths in `TransactionEntity`:
  ```dart
  // Added to TransactionEntity and KhataEntryEntity
  List<String> attachmentPaths;
  ```

### 3.4 UI & UX Components
- **Attachment Strip**: Thumbnail preview carousel in `AddTransactionModal` and `TransactionDetailModal`.
- **Full-Screen Viewer**: Interactive pinch-to-zoom modal with Share button (WhatsApp/Email/AirDrop).
- **Camera Quick Action**: "Scan Receipt" quick action on the Dashboard FAB menu.

---

## 4. 👥 Split Bill & Group Expenses (Flatmates & Friends)

### 4.1 Overview & Value Proposition
Splitting restaurant bills, house rent, groceries, or trip expenses among friends. Seamlessly connects with the existing KhataBook module so unpaid balances automatically become ledger entries!

### 4.2 User Flow
```
Tap "Split Bill" from Dashboard or Expense Detail
                       │
                       ▼
Enter Total Amount (e.g. ₹2,400 at BBQ Nation)
                       │
                       ▼
Select Participants from Khata Contacts or Phone Contacts
(e.g., You, Rahul, Priya, Amit)
                       │
                       ▼
Choose Split Method:
 ├── Equal Split (₹600 each)
 ├── Exact Amounts (e.g., ₹800, ₹500, ₹600, ₹500)
 └── Percentages (40%, 20%, 20%, 20%)
                       │
                       ▼
Confirm & 1-Click Sync to KhataBook:
 ├── Creates 1 Main Expense for User's own share (₹600)
 └── Auto-creates 3 Khata "Gave (Udhar)" entries for Rahul, Priya, Amit
                       │
                       ▼
Send WhatsApp Reminder to all 3 with UPI Deep Link in 1 tap!
```

### 4.3 WhatsApp Reminder Format
```
Hey Rahul! 👋
Your share for "BBQ Nation Dinner" is ₹600.00.
Kindly settle via UPI:
upi://pay?pa=myupi@oksbi&pn=SpendWise&am=600.00&cu=INR

Sent via SpendWise
```

---

## 5. 💾 1-Tap Offline Backup & Restore (Zero Data Loss)

### 5.1 Overview & Value Proposition
Since SpendWise is 100% offline-first, users need an effortless way to safeguard their data before formatting their phone or switching devices.

### 5.2 Technical Stack
- `archive: ^4.0.2` (Zip compression & decompression)
- `file_picker: ^8.1.7` (Document selection for restore)
- `share_plus: ^13.3.0` (Share backup file via Drive, WhatsApp, Telegram, Email)

### 5.3 Backup Architecture
- **Export Content**:
  - `database.json`: Complete dump of all Entities (Transactions, Khata Contacts, Khata Entries, Bill Reminders, Budgets, Categories).
  - `receipts/`: Folder containing all receipt images.
  - `manifest.json`: App version, checksum (SHA-256), timestamp, device model.
- All bundled into a single compressed `.spendwise` (encrypted zip) file.
- File Name: `SpendWise_Backup_2026-09-07_1430.spendwise`.

### 5.4 Restore Strategy & Validation
1. User picks `.spendwise` file via FilePicker.
2. App validates checksum and version compatibility.
3. User chooses restore mode:
   - **Merge**: Merges new transactions without overwriting existing IDs.
   - **Full Replace**: Cleans store and does a fresh restore with progress bar.
4. Database hot-refreshes and notifies UI via `AppEvents.notifyDataChanged()`.

---

## 6. 📊 Excel (.xlsx) & CSV Statement Export & Import

### 6.1 Overview & Value Proposition
Accountants, CAs, and business owners need spreadsheets for tax filing (ITR), balance sheet preparation, or custom spreadsheet formulas.

### 6.2 Technical Stack
- `excel: ^4.0.6` (Native Dart Excel XLSX creation with styles and formulas)
- `csv: ^6.0.0` (Fast CSV generator and parser)

### 6.3 Spreadsheet Structure
- **Sheet 1: Summary Dashboard**:
  - Total Income, Total Expenses, Net Savings, Highest Expense Category.
- **Sheet 2: All Transactions**:
  - Headers: `Date`, `Time`, `Type (Debit/Credit)`, `Category`, `Merchant / Payee`, `Amount (₹)`, `Platform / Bank`, `Account / Card`, `UTR / Txn ID`, `Balance After`.
  - Auto-formatted currency columns, styled headers with `#1E293B` background and white text.
- **Sheet 3: KhataBook Ledger**:
  - Contact Name, Phone, Total Gave, Total Got, Net Balance, Status (Settled/Pending).

### 6.4 Bank CSV Import (Bonus)
- Allows importing `.csv` statements downloaded from NetBanking (HDFC, SBI, ICICI) to retroactively populate years of transactions in SpendWise.

---

## 7. 🔄 Subscriptions & Recurring Bills Tracker

### 7.1 Overview & Value Proposition
Prevent "zombie subscriptions" (unnoticed auto-debits for Netflix, Spotify, Gym, Amazon Prime, SaaS tools). SpendWise tracks upcoming renewal dates and notifies users 48 hours before auto-debit.

### 7.2 ObjectBox Entity (`SubscriptionEntity`)
```dart
@Entity()
class SubscriptionEntity {
  @Id()
  int id = 0;

  String name;              // 'Netflix Premium', 'Spotify Family', 'Gym'
  double amount;            // e.g. 649.00
  String categoryId;        // 'entertainment', 'bills', etc.
  
  String billingCycle;      // 'monthly', 'quarterly', 'yearly'
  DateTime startDate;       // Initial registration
  DateTime nextBillingDate; // Next expected auto-debit
  
  String? paymentMethod;    // 'HDFC Credit Card **4582', 'Paytm UPI'
  bool remindBefore48h;     // Push notification 2 days before
  bool isAutoDetected;      // Extracted via Bank Mandate SMS
  bool isActive;            // Toggle active / paused

  SubscriptionEntity({
    this.id = 0,
    required this.name,
    required this.amount,
    required this.categoryId,
    this.billingCycle = 'monthly',
    required this.startDate,
    required this.nextBillingDate,
    this.paymentMethod,
    this.remindBefore48h = true,
    this.isAutoDetected = false,
    this.isActive = true,
  });
}
```

### 7.3 Auto-Detection from SMS
- When an SMS contains mandate keywords (which we previously marked as Notification Only):
  `"Your e-mandate for Netflix Entertainment of Rs 649.00 has been registered successfully."`
- The system prompts: *"Detect Netflix mandate for ₹649/mo? Add to Subscription Tracker?"*
- 1-tap add without manual typing!

---

## 8. 💡 AI / Smart Spending Insights & Financial Health Score

### 8.1 Overview & Value Proposition
Go beyond static numbers. Provide actionable intelligence on personal spending habits, cash burn rate, and an engaging Financial Health Score (0-100).

### 8.2 Heuristic Intelligence Engine
- **Week-over-Week Velocity**:
  - *"You spent ₹4,200 on Food this week — 34% more than your 4-week average."*
- **Weekend vs Weekday Ratio**:
  - *"62% of your discretionary spending occurs between Friday evening and Sunday night."*
- **Recurring Leak Alerts**:
  - *"You have made 18 small UPI payments under ₹50 this week (Total: ₹720). Small spends add up!"*
- **Salary Burn Rate**:
  - *"At your current daily burn rate of ₹1,850/day, your available balance will last 16 more days."*

### 8.3 Financial Health Score Algorithm (0 - 100)
Calculated from 4 weighted pillars:
1. **Savings Rate (35%)**: `(Income - Expense) / Income >= 20%` $\to$ Max 35 pts
2. **Budget Adherence (25%)**: Staying within category budget limits $\to$ Max 25 pts
3. **Khata Debt Recovery (20%)**: Ratio of pending receivables recovered $\to$ Max 20 pts
4. **Emergency Buffer (20%)**: Net positive cash flow over 3 months $\to$ Max 20 pts

- **Visual Display**: Animated circular gauge on Dashboard with rating badges (*"Excellent"*, *"Disciplined"*, *"Needs Attention"*).

---

## 🗺️ Recommended Implementation Roadmap

```
PHASE 1: Foundation & Privacy (Immediate)
  ├── 1. Biometric Lock & Privacy Mode
  └── 2. Category Budgets & Overspend Alerts

PHASE 2: Everyday Utilities (Week 2)
  ├── 3. Split Bill & Group Expenses (KhataBook connection)
  └── 4. Bill & Receipt Photo Attachments

PHASE 3: Data Independence & Export (Week 3)
  ├── 5. 1-Tap Offline Backup & Restore (.spendwise package)
  └── 6. Excel (.xlsx) & CSV Statement Exporter

PHASE 4: Automation & Intelligence (Week 4)
  ├── 7. Subscriptions & Mandate Tracker
  └── 8. Smart Spending Insights & Financial Health Score
```

---

*Authored for SpendWise Core Engineering Team.*  
*Maintained under Clean Architecture & ObjectBox specifications.*
