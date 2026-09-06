# 🗄️ Database Schema & Queries Specification

The application uses an offline-first SQLite relational database managed via `sqflite`.

---

## 1. Tables & Schema

### `transactions` Table
Stores all automated (parsed from SMS) and manual financial transactions.

```sql
CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    amount REAL NOT NULL,
    type TEXT NOT NULL, -- 'debit' or 'credit'
    category TEXT NOT NULL,
    merchant TEXT,
    platform TEXT, -- 'GPay', 'PhonePe', 'Paytm', 'HDFC', etc.
    transaction_id TEXT, -- UTR or Bank Ref ID
    account_or_card TEXT, -- Last 4 digits
    date INTEGER NOT NULL, -- Unix timestamp in ms
    raw_sms TEXT,
    balance_after REAL,
    notes TEXT,
    is_automated INTEGER DEFAULT 0 -- 1 = SMS parsed, 0 = Manual
);

CREATE INDEX idx_txn_date ON transactions(date DESC);
CREATE INDEX idx_txn_category ON transactions(category);
CREATE INDEX idx_txn_type ON transactions(type);
CREATE INDEX idx_txn_id ON transactions(transaction_id);
```

---

### `khata_contacts` Table
Stores contact profiles for the Udhar-Jama ledger.

```sql
CREATE TABLE khata_contacts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    phone_number TEXT,
    created_at INTEGER NOT NULL,
    avatar_color INTEGER
);
```

---

### `khata_entries` Table
Stores individual lend/borrow ledger records linked to a contact.

```sql
CREATE TABLE khata_entries (
    id TEXT PRIMARY KEY,
    contact_id TEXT NOT NULL,
    amount REAL NOT NULL,
    type TEXT NOT NULL, -- 'gave' (You gave) or 'got' (You got)
    date INTEGER NOT NULL,
    due_date INTEGER,
    notes TEXT,
    is_settled INTEGER DEFAULT 0,
    FOREIGN KEY (contact_id) REFERENCES khata_contacts (id) ON DELETE CASCADE
);

CREATE INDEX idx_khata_contact ON khata_entries(contact_id);
CREATE INDEX idx_khata_date ON khata_entries(date DESC);
```

---

### `bill_reminders` Table
Stores scheduled payment reminders for utility bills, EMIs, credit cards.

```sql
CREATE TABLE bill_reminders (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    amount REAL NOT NULL,
    due_date INTEGER NOT NULL,
    category TEXT NOT NULL,
    is_paid INTEGER DEFAULT 0,
    recurrence TEXT DEFAULT 'none', -- 'none', 'monthly', 'weekly', 'yearly'
    payment_link TEXT
);

CREATE INDEX idx_reminders_due ON bill_reminders(due_date ASC);
```
