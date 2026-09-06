# 📄 PDF Statement & Financial Report Exporter Guide

This document describes the structure, visual design, and export pipelines for generating PDF financial statements.

---

## 1. Statement Structure

A generated monthly/custom range statement contains:
1. **Header & Branding**:
   - App Logo & Title: *Smart Expense Tracker Statement*.
   - Statement Period: e.g., *01 Aug 2026 – 31 Aug 2026*.
   - Generation Date & Timestamp.
2. **Executive Summary KPI Cards**:
   - Total Inflow (Credit)
   - Total Outflow (Debit)
   - Net Savings / Surplus
   - Total Number of Transactions
3. **Category-Wise Spending Breakdown Table**:
   - Category Name, Transaction Count, Total Amount, Percentage of Total Expense.
4. **Itemized Transaction Ledger**:
   - Table columns: `Date`, `Description / Merchant`, `Platform`, `Txn ID / UTR`, `Category`, `Type`, `Amount (₹)`.
5. **KhataBook Summary Ledger (Optional / Standalone)**:
   - Contact Name, Total Given, Total Received, Net Balance Due.

---

## 2. Export & Share Actions
- **Direct Preview**: In-app PDF viewer powered by `printing` package.
- **Direct Print**: AirPrint / Android system printing.
- **Save to Device**: Saves `.pdf` to documents storage.
- **Share via WhatsApp / Email**: Instant share sheet integration via `share_plus`.
