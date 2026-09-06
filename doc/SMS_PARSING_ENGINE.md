# 🧠 SMS Parsing & Auto-Detection Engine Specification

This document details the regex patterns, heuristics, and algorithmic flow for automatically extracting financial transactions from SMS messages in the Indian banking and fintech ecosystem.

---

## 1. Supported Platforms & Banks

### UPI & Fintech Platforms
- **Google Pay** (`GPAY`, `GooglePay`, `AXIS-GPAY`)
- **PhonePe** (`PHONEPE`, `YBL`, `IBL`)
- **Paytm** (`PAYTM`, `PYTM`)
- **Cred** (`CRED`, `CREDCLUB`)
- **Amazon Pay** (`AMAZON`, `AMZN`)
- **BHIM UPI** (`BHIM`, `NPCI`)
- **Slice** (`SLICE`)
- **MobiKwik** (`MOBIKWIK`)

### Leading Banks
- **HDFC Bank** (`HDFCBK`, `HDFC`)
- **State Bank of India** (`SBIN`, `SBIINB`, `SBIPSG`)
- **ICICI Bank** (`ICICIB`, `ICICI`)
- **Axis Bank** (`AXISBK`, `AXIS`)
- **Kotak Mahindra Bank** (`KOTAKB`, `KOTAK`)
- **Punjab National Bank** (`PNBSMS`, `PNB`)
- **Bank of Baroda** (`BOBSMS`, `BOB`)
- **Yes Bank** (`YESBNK`)
- **IndusInd Bank** (`INDBNK`)
- **Canara Bank** (`CANBNK`)
- **Federal Bank** (`FEDBNK`)

---

## 2. Parsing Extraction Rules

### A. Amount Extraction
Patterns to detect transaction amounts:
```regex
(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)
([\d,]+(?:\.\d{1,2})?)\s*(?:INR|Rs\.?|₹)
```

### B. Transaction Type (Debit vs Credit)
- **Debit Keywords**: `debited`, `sent`, `paid`, `spent`, `withdrawn`, `deducted`, `transferred to`, `purchase of`
- **Credit Keywords**: `credited`, `received`, `deposited`, `refund`, `cashback`, `salary`, `transferred from`

### C. Transaction ID / UTR / Reference Number
Patterns to detect reference numbers:
```regex
(?:UPI Ref(?:\s*no)?|Txn(?:\s*ID)?|Ref(?:\s*No)?|UTR|Ref\s*id|transaction\s*id)[\s:/-]*([0-9a-zA-Z]{6,22})
```

### D. Account / Card Last 4 Digits
```regex
(?:A/C|Acct|Account|Card|ending\s*with)\s*(?:no\.?)?\s*[*xX\s]*(\d{3,4})
```

### E. Available Balance Extraction
```regex
(?:Avl\s*Bal|Available\s*Balance|Bal|Balance\s*is)\s*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)
```

---

## 3. Merchant Detection & Auto-Categorization

| Category | Sample Merchants & Keywords |
|----------|----------------------------|
| **Food & Dining** | Swiggy, Zomato, McDonald's, Starbucks, Domino's, KFC, Burger King, Chai Point, Restaurant, Cafe |
| **Groceries** | Blinkit, Zepto, Instamart, BigBasket, D-Mart, Nature's Basket, JioMart, Supermarket |
| **Shopping** | Amazon, Flipkart, Myntra, Meesho, Ajio, Zara, H&M, Nykaa, Tata CLiQ, Apple |
| **Travel & Fuel** | Uber, Ola, Rapido, IndianOil, HPCL, BPCL, IRCTC, MakeMyTrip, Goibibo, Shell, Metro |
| **Bills & Utilities** | Electricity, Water, Gas, BESCOM, Tata Power, Jio, Airtel, Vi, ACT Fibernet, Broadband |
| **Entertainment** | Netflix, Spotify, BookMyShow, Prime Video, Hotstar, YouTube, PVR, INOX |
| **Investments** | Zerodha, Groww, AngelOne, Upstox, Coin, Mutual Fund, SIP, Kuvera |
| **Health & Medical** | Apollo, PharmEasy, 1mg, Netmeds, MedPlus, Hospital, Pharmacy, Clinic |
| **Salary & Income** | Salary, Payroll, Stipend, Interest Credited, Dividend, Bonus |
| **Transfers & Others** | Self transfer, Friend transfer, ATM cash withdrawal |

---

## 4. Deduplication & Real-Time Sync Strategy
1. Primary key for uniqueness: `transaction_id` (if available) or `hash(amount + date + account_ending + type)`.
2. **Custom Date Range / Calendar Backfill**:
   - User can pick any past start date from a built-in calendar picker or choose presets (Last 7 Days, 15 Days, 30 Days, 90 Days, 180 Days, 1 Year).
   - Only SMS messages with `msg.date >= fromDate` are parsed and imported, ensuring users who just installed the app can backfill all historical transactions without missing past days.
3. Live broadcast receiver and on-demand sync captures incoming SMS instantaneously.
