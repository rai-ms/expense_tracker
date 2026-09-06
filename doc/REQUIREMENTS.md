# 📋 Software Requirements Specification (SRS)

**Project Name**: Smart Expense Tracker & KhataBook App  
**Target Platform**: Flutter (Android, iOS, macOS, Web)  
**Architecture**: Offline-First SQLite Local Storage  
**Document Version**: 1.0.0  

---

## 1. Executive Summary & Objectives

The goal of this application is to provide a unified, highly automated personal finance management system tailored for the Indian financial ecosystem. The app automatically captures, parses, and categorizes bank and UPI SMS transactions in real-time, provides an interactive visual dashboard with dynamic charts, integrates a full-featured KhataBook (Udhar-Jama) ledger for tracking money lent and borrowed, schedules payment reminders, and generates downloadable/printable PDF financial statements.

---

## 2. Functional Requirements (FR)

### FR-1: Real-Time SMS Sync & Permission Handling
- **FR-1.1**: The app shall request runtime SMS permissions (`READ_SMS`, `RECEIVE_SMS`) on Android devices.
- **FR-1.2**: The app shall offer both automatic background SMS scanning and a manual 1-tap "Sync SMS" button on the dashboard.
- **FR-1.3**: The app shall deduplicate transactions using a unique signature (Transaction ID / UTR or hash of amount + timestamp + account number) so duplicate SMS entries are never recorded twice.
- **FR-1.4**: On non-Android or restricted platforms, the app shall gracefully degrade and provide a built-in **SMS Simulator** allowing users to paste or test SMS templates directly.

---

### FR-2: Smart SMS Parsing & Entity Extraction
- **FR-2.1**: **Amount Extraction**: Accurately parse transaction amounts in Indian currency formats (`₹ 1,500.00`, `INR 250`, `Rs. 499.50`, etc.).
- **FR-2.2**: **Type Classification**: Correctly identify whether an SMS corresponds to a **Debit** (Spent, Sent, Paid, Withdrawn, Deducted) or **Credit** (Received, Refunded, Deposited, Salary, Cashback).
- **FR-2.3**: **Platform & Bank Detection**: Auto-detect the originating bank (HDFC, SBI, ICICI, Axis, Kotak, PNB, etc.) or UPI/fintech platform (Google Pay, PhonePe, Paytm, Cred, Amazon Pay, BHIM, Slice, etc.).
- **FR-2.4**: **Transaction ID / UTR Identification**: Extract reference codes (`UPI Ref 425109283741`, `Txn ID: AX98214`, `UTR: 129384729103`).
- **FR-2.5**: **Account / Card Number Detection**: Extract the last 3 or 4 digits of the bank account or debit/credit card (`A/C **1234`, `Card ending 5678`).
- **FR-2.6**: **Available Balance Extraction**: Extract remaining account balance when present in the SMS (`Avl Bal: ₹24,500.00`).

---

### FR-3: Intelligent Auto-Categorization & Merchant Detection
- **FR-3.1**: Auto-categorize incoming transactions into standard categories:
  - *Food & Dining* (Swiggy, Zomato, Starbucks, McDonald's, KFC, restaurants)
  - *Groceries* (Blinkit, Zepto, Instamart, BigBasket, D-Mart)
  - *Shopping* (Amazon, Flipkart, Myntra, Meesho, Zara, Nykaa)
  - *Travel & Fuel* (Uber, Ola, Rapido, IndianOil, HPCL, BPCL, IRCTC, MakeMyTrip)
  - *Bills & Utilities* (Electricity, Water, Gas, Jio, Airtel, Vi, Broadband)
  - *Entertainment* (Netflix, Spotify, BookMyShow, Prime Video, Hotstar)
  - *Investments* (Zerodha, Groww, AngelOne, Upstox, Mutual Funds, SIP)
  - *Health & Medical* (Apollo, PharmEasy, 1mg, Hospitals, Clinics)
  - *Salary & Income* (Salary, Payroll, Interest, Dividend)
  - *Transfers & Others* (Self-transfer, friend transfer, ATM cash)
- **FR-3.2**: Allow users to manually change or override the category of any transaction.

---

### FR-4: KhataBook (Udhar-Jama / Lend & Borrow Ledger)
- **FR-4.1**: Enable users to create contacts/customers with Name, Phone Number, and avatar.
- **FR-4.2**: Record "You Gave (Maine Diye)" and "You Got (Mujhe Mile)" entries with Amount, Date, Due Date, and Notes.
- **FR-4.3**: Compute real-time net balances per contact:
  - Positive balance: *You will receive (Aapko milenge)* [Green].
  - Negative balance: *You will give (Aapko dene hain)* [Red].
  - Zero balance: *Settled* [Gray].
- **FR-4.4**: Display aggregate Khata totals on the main KhataBook screen ("Total to Receive" vs "Total to Pay").
- **FR-4.5**: Generate 1-click **WhatsApp Payment Reminders** with pre-formatted, polite reminder text and UPI payment details.
- **FR-4.6**: Support full and partial account settlement.

---

### FR-5: Dynamic UI & Interactive Analytics
- **FR-5.1**: Provide a modern, clean Fintech UI with Dark and Light mode options.
- **FR-5.2**: **Dashboard**:
  - Live Balance Card with Total Income, Total Expense, and Net Balance.
  - Quick-action buttons (Sync SMS, Add Expense, Add Khata, Export PDF).
  - Spending Meter vs monthly budget.
  - Recent transactions list with platform badges and category icons.
- **FR-5.3**: **Interactive Charts** (powered by `fl_chart`):
  - **Category Donut / Pie Chart** with interactive touch slice selection and percentage breakdown.
  - **Weekly & Monthly Spend Spline Trend** chart showing spend velocity.
  - **Cash Flow Bar Chart** comparing Income vs Expense across months.
  - **Top Merchants Leaderboard** with spend totals.
- **FR-5.4**: Filter analytics by: This Week, This Month, Last 3 Months, This Year, or Custom Date Range.

---

### FR-6: Payment Reminders & Bill Management
- **FR-6.1**: Allow users to create scheduled reminders for upcoming bills (Credit Cards, Electricity, Rent, Wi-Fi, EMIs, Khata dues).
- **FR-6.2**: Provide visual urgency indicators (Due Today, Due in X Days, Overdue).
- **FR-6.3**: Allow users to mark bills as Paid or Snooze them.

---

### FR-7: PDF Statement & Financial Report Exporter
- **FR-7.1**: Generate high-quality, printable PDF financial statements for any filtered date range.
- **FR-7.2**: PDF statement shall include:
  - Header branding & statement date range.
  - KPI Summary Cards (Total Inflow, Total Outflow, Net Savings, Total Transactions).
  - Category-wise Spending Breakdown Table with percentage share.
  - Itemized Transaction Ledger (Date, Merchant, Platform, Txn ID, Category, Amount).
- **FR-7.3**: Support direct Print, local File Save, and instant Share via WhatsApp/Email.

---

### FR-8: Built-in SMS Simulator & Mock Testing Mode
- **FR-8.1**: In-app simulator interface with pre-loaded realistic Indian bank SMS templates (HDFC, SBI, ICICI, Axis, Paytm, PhonePe, GPay, Cred, Swiggy, Uber).
- **FR-8.2**: Allow users to type or paste any custom SMS and view instantaneous parsing output (Amount, Type, Merchant, Platform, UTR) before committing to the database.

---

## 3. Non-Functional Requirements (NFR)

- **NFR-1: 100% Offline & Privacy-First**: All data, SMS parsing, and ledger records remain strictly on the local device in SQLite. No sensitive financial information is transmitted to external servers.
- **NFR-2: Performance**: Real-time SMS parsing within < 50ms per message. Smooth 60fps/120fps UI animations on chart touches and list scrolls.
- **NFR-3: Reliability & Data Integrity**: Foreign key constraints and atomic database transactions to avoid corrupted ledger balances.
- **NFR-4: Modern Aesthetics**: Consistent design tokens, Material 3 theming, glassmorphism cards, and high-contrast accessible typography.
- **NFR-5: Cross-Platform Graceful Fallback**: Native SMS integration on Android, with full simulation and manual mode support on iOS, macOS, and Web.

---

## 4. User Personas & Acceptance Criteria

| Persona | Core Need | Acceptance Criteria |
|---------|-----------|---------------------|
| **Daily UPI Spender** | Wants hands-free expense tracking without manual typing. | SMS from GPay/PhonePe/Paytm automatically creates categorized expense entries with Txn IDs. |
| **Friend / Small Lender** | Needs to remember who owes money and who needs to be paid back. | KhataBook calculates net balances per person and generates 1-click WhatsApp reminders. |
| **Budget Conscious User** | Wants to understand monthly spending habits. | Dynamic donut charts and weekly trends provide clear insights into top spending categories. |
| **Tax / Audit Filer** | Needs official records of yearly or monthly expenses. | PDF statement exports cleanly formatted financial tables with UTR numbers and date stamps. |
