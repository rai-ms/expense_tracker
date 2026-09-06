# 📖 KhataBook (Udhar-Jama Ledger) Specification

This document describes the business logic, ledger management, balance calculation formulas, and communication templates for the KhataBook feature.

---

## 1. Core Concepts & Ledger Balance

### Terminology:
- **"You Gave" (Maine Diye / Lent)**: You gave money to a contact. (Contact owes you).
- **"You Got" (Mujhe Mile / Borrowed)**: You received money from a contact or borrowed. (You owe contact, or contact repaid you).

### Net Balance Formula for a Contact:
$$\text{Net Balance} = \sum(\text{Gave Entries}) - \sum(\text{Got Entries})$$

- If $\text{Net Balance} > 0$: **You Will Receive (Aapko milenge)** $\rightarrow$ Displayed in **Emerald Green**.
- If $\text{Net Balance} < 0$: **You Will Give (Aapko dene hain)** $\rightarrow$ Displayed in **Crimson Coral**.
- If $\text{Net Balance} = 0$: **All Settled** $\rightarrow$ Displayed in **Muted Gray**.

---

## 2. Total Dashboard Ledger Summary
- **Total You Will Receive**: Sum of all positive contact balances.
- **Total You Will Give**: Sum of absolute values of all negative contact balances.

---

## 3. WhatsApp Payment Reminder Generator

When user taps **"Send WhatsApp Reminder"**, the app creates a respectful, pre-formatted message:

```
🙏 Namaste [Contact Name],

This is a gentle reminder regarding our pending balance of ₹[Amount].

📅 Due Date: [Due Date / As agreed]
📝 Notes: [Transaction notes / Purpose]

Kindly pay via UPI:
🔗 [User's UPI ID or Payment link]

Thank you!
Sent via Smart Expense & Khata Tracker
```
