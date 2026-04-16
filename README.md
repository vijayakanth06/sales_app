# HomeSales Tracker

A mobile-first Flutter application for tracking home-based product sales, customer management, and financial calculations. Built with **Supabase** as the backend and **Riverpod** for state management.

## Features

### 📊 Dashboard (Home)
- Today's revenue, collected amount, and outstanding balance
- Recent transaction list with quick status indicators

### 👥 Groups & Persons
- Create groups (Factory, Site, Shop, Other)
- Add persons to groups or as individuals
- Move persons between groups or make them individual
- Full CRUD: Edit, Delete, Move — via long-press actions
- Outstanding balance badge per person and group

### 🛒 Sale Entry
- Product grid with quantity controls (+/-)
- Payment status: PAID / PARTIAL / NOT PAID
- Payment method: Cash / GPay / Other
- Linked to specific person and optional group

### ⚡ Quick Sale
- Fastest entry mode — always marks as PAID
- Auto-resets form after save for rapid entries

### 📦 Bulk Orders
- Full CRUD: Create, Edit, Delete bulk orders
- Status tracking: Pending → Delivered / Cancelled
- Payment tracking: Paid / Partial / Unpaid
- Long-press for quick actions (status change, delete)

### 🧮 Calculate
- Per-person and per-group financial breakdown
- Date range filtering
- Share summary via WhatsApp/Share
- Record settlement payments

### ⚙️ Settings
- Product management (Add, Edit, Delete)
- Language toggle (English / Tamil)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Android + Web) |
| **Backend** | Supabase (PostgreSQL + REST API) |
| **State Management** | Riverpod |
| **Localization** | flutter_localizations + intl (EN / TA) |
| **Offline** | Hive (planned) |

## Database Schema

8 tables with Row Level Security (RLS):
- `products` — Product catalog with selling/cost prices
- `groups` — Customer groups (factory, site, shop, etc.)
- `persons` — Individual customers, optionally linked to a group
- `transactions` — Sale records with payment status
- `transaction_items` — Line items per transaction
- `payments` — Settlement payments against outstanding balance
- `bulk_orders` — Bulk order header with delivery tracking
- `bulk_order_items` — Line items per bulk order

## Setup

### Prerequisites
- Flutter SDK (3.x+)
- Android Studio / VS Code
- Supabase project

### Installation

```bash
# Clone the repo
git clone https://github.com/vikym/sales_app.git
cd sales_app

# Create .env file from example
cp .env.example .env
# Edit .env with your Supabase URL and anon key

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Environment Variables

Create a `.env` file in the project root:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

## Project Structure

```
lib/
├── l10n/                    # Localization files
│   ├── app_en.arb           # English strings
│   ├── app_ta.arb           # Tamil strings
│   └── app_localizations.dart
├── models/
│   └── models.dart          # Data models (Product, Group, Person, etc.)
├── providers/
│   └── providers.dart       # Riverpod providers
├── services/
│   └── supabase_service.dart # Supabase CRUD operations
├── screens/
│   ├── home/                # Dashboard
│   ├── groups/              # Groups list + detail
│   ├── individuals/         # Individual persons
│   ├── sale_entry/          # Sale entry form
│   ├── quick_sale/          # Quick sale mode
│   ├── bulk_orders/         # Bulk order management
│   ├── calculate/           # Financial calculations
│   └── settings/            # App settings
├── app_shell.dart           # Bottom navigation shell
└── main.dart                # Entry point
```

## License

Private — For internal use only.
