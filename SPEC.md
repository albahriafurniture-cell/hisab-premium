# Hisab Premium — Build Spec (for agy)

## App
- Name: "Hisab Premium". Package: com.hisab.premium (already set by flutter create --org com.hisab).
- Platform: Android only. Offline-first, no network calls, no backend.
- Currency: PKR (Rs). Language: English + Urdu toggle (en/ur). Default: en.
- Stack: Flutter + Hive (hive, hive_flutter). Charts: fl_chart. Utils: intl, uuid.

## Design language (PREMIUM — this matters most)
- Dark fintech: background #0A0E1A / #0D1220, cards #141B2E with subtle gradient + 1px gold-ish border (#C9A227 at 20% opacity).
- Accent: gold #C9A227 for primary actions/highlights, teal #2DD4BF for income/positive, rose #FB7185 for expense/negative.
- Glassmorphism cards: semi-transparent gradients, rounded 20px corners, soft shadows.
- Typography: bold display numbers (tabular figures), letter-spaced section labels.
- Motion: hero transitions on cards, staggered list entrances, animated number counters on dashboard.
- Bottom nav: custom glass bar with 5 tabs: Home, Records, Loans, Reports, Settings. Center FAB (+) opens Add Transaction sheet.

## Data layer (Hive, hand-written TypeAdapters — NO build_runner)
TypeIds: 0=Account, 1=Category, 2=Txn, 3=Person, 4=LoanEntry, 5=AppSettings.

- Account { id:String, name:String, kind:String(cash/bank/wallet), balance:double, color:int, icon:String }
- Category { id:String, name:String, nameUr:String, kind:String(income/expense), icon:String, color:int }
- Txn { id:String, kind:String(income/expense), amount:double, categoryId:String, accountId:String, note:String, date:DateTime }
  - On add/edit/delete, adjust the linked Account.balance accordingly.
- Person { id:String, name:String, phone:String, note:String }
- LoanEntry { id:String, personId:String, direction:String(given/taken), principal:double, repaid:double, date:DateTime, dueDate:DateTime?, note:String, status:String(active/settled) }
  - given = maine diya (receivable), taken = maine liya (payable). Repayment recorded by increasing `repaid`; when repaid >= principal → status=settled.
- AppSettings { pinHash:String, locale:String(en/ur), currency:String, onboarded:bool }
  - PIN: store SHA-256 hash (use package:crypto), 4-digit.

HiveService (singleton): init() opens all boxes; CRUD for each entity; helpers:
- totalsThisMonth(), balanceTotal(), receivableTotal(), payableTotal(), overdueLoans(), txnsByFilter({kind, categoryId, from, to, query}).

Seed on first run: 3 accounts (Cash, Bank, Wallet), ~14 categories with Urdu names + icons (Material icon names as String), settings defaults.

## Screens
1. Onboarding (3 premium slides) → PinSetup → MainShell.
2. LockScreen (PIN pad, shown on cold start when pinHash set).
3. Home: greeting, total balance (animated counter), month income/expense mini-cards, cash-flow bar sparkline (fl_chart), "Loans overview" card (receivable/payable/overdue counts → tap to Loans), recent 5 transactions.
4. Records: search + filter chips (All/Income/Expense) + month picker; grouped list by date; swipe to delete (with undo snackbar); tap to edit.
5. AddTxnSheet (FAB): amount field with big numerals, Income/Expense segmented toggle, category grid, account dropdown, date picker, note → Save.
6. Loans: tabs "Diye Gaye (Receivable)" / "Liye Gaye (Payable)"; summary header (total + overdue); person cards with net balance and progress; PersonDetail: entries list, "Record repayment" and "Add loan" buttons, call/message person (url_launcher not needed — skip), settle toggle.
7. Reports: month selector; income-vs-expense bar chart; category donut (fl_chart PieChart); top categories list; net savings card.
8. Settings: language toggle, change PIN, currency display (PKR fixed note), export note (text summary share via share_plus? — SKIP sharing, just show a "backup reminder" card), About.

## i18n
- Simple Map-based strings: lib/i18n/strings.dart with `en` and `ur` maps, `tr(key)` helper reading AppSettings.locale. Cover all user-visible strings. Urdu uses Roman Urdu (e.g. "Aamdani", "Kharcha", "Qarz").

## Quality rules
- `flutter analyze` must be CLEAN (zero issues). Fix all warnings.
- No print/debugPrint in release paths; no network; no hardcoded secrets.
- All Hive adapters hand-written in lib/data/adapters.dart.
- main.dart: Hive.initFlutter, HiveService.init, seed, then runApp with lock/onboarding routing.
