import 'hive_service.dart';
import 'models.dart';

/// Seeds default accounts, categories, and settings on first run.
/// Called only when the settings box is empty.
Future<void> seedDefaults() async {
  final hive = HiveService.instance;

  if (hive.settingsBox.isNotEmpty) {
    return;
  }

  // 1. Default AppSettings
  const defaultSettings = AppSettings(
    pinHash: '',
    locale: 'en',
    currency: 'PKR',
    onboarded: false,
  );
  await hive.saveSettings(defaultSettings);

  // 2. Default Accounts (3 accounts: Cash, Bank, Wallet)
  final defaultAccounts = [
    const Account(
      id: 'acc_cash',
      name: 'Cash',
      kind: 'cash',
      color: 0xFF2DD4BF, // Teal
      icon: 'payments',
      balance: 0.0,
    ),
    const Account(
      id: 'acc_bank',
      name: 'Bank Account',
      kind: 'bank',
      color: 0xFF38BDF8, // Sky Blue
      icon: 'account_balance',
      balance: 0.0,
    ),
    const Account(
      id: 'acc_wallet',
      name: 'Digital Wallet',
      kind: 'wallet',
      color: 0xFFC9A227, // Gold
      icon: 'account_balance_wallet',
      balance: 0.0,
    ),
  ];

  for (final account in defaultAccounts) {
    await hive.saveAccount(account);
  }

  // 3. Default Categories (~14 categories: 10 expense, 5 income)
  final defaultCategories = [
    // Expenses
    const Category(
      id: 'cat_food',
      name: 'Food & Dining',
      nameUr: 'Khana Peena',
      kind: 'expense',
      icon: 'restaurant',
      color: 0xFFFB7185,
    ),
    const Category(
      id: 'cat_groceries',
      name: 'Groceries',
      nameUr: 'Sauda Salaf',
      kind: 'expense',
      icon: 'shopping_cart',
      color: 0xFFF472B6,
    ),
    const Category(
      id: 'cat_rent',
      name: 'Rent & Housing',
      nameUr: 'Kiraya aur Ghar',
      kind: 'expense',
      icon: 'home',
      color: 0xFFA78BFA,
    ),
    const Category(
      id: 'cat_utilities',
      name: 'Bills & Utilities',
      nameUr: 'Bills aur Bijli',
      kind: 'expense',
      icon: 'receipt_long',
      color: 0xFFFBBF24,
    ),
    const Category(
      id: 'cat_transport',
      name: 'Transport & Fuel',
      nameUr: 'Gaari aur Petrol',
      kind: 'expense',
      icon: 'directions_car',
      color: 0xFF60A5FA,
    ),
    const Category(
      id: 'cat_shopping',
      name: 'Shopping',
      nameUr: 'Kharidari',
      kind: 'expense',
      icon: 'shopping_bag',
      color: 0xFFE879F9,
    ),
    const Category(
      id: 'cat_health',
      name: 'Healthcare & Medicine',
      nameUr: 'Sehat aur Dawai',
      kind: 'expense',
      icon: 'medical_services',
      color: 0xFF34D399,
    ),
    const Category(
      id: 'cat_education',
      name: 'Education',
      nameUr: 'Taleem',
      kind: 'expense',
      icon: 'school',
      color: 0xFF38BDF8,
    ),
    const Category(
      id: 'cat_entertainment',
      name: 'Entertainment',
      nameUr: 'Tafreeh',
      kind: 'expense',
      icon: 'movie',
      color: 0xFF818CF8,
    ),
    const Category(
      id: 'cat_other_expense',
      name: 'Other Expense',
      nameUr: 'Deegar Kharcha',
      kind: 'expense',
      icon: 'more_horiz',
      color: 0xFF94A3B8,
    ),

    // Incomes
    const Category(
      id: 'cat_salary',
      name: 'Salary',
      nameUr: 'Tankhwah',
      kind: 'income',
      icon: 'payments',
      color: 0xFF2DD4BF,
    ),
    const Category(
      id: 'cat_business',
      name: 'Business',
      nameUr: 'Karobar',
      kind: 'income',
      icon: 'storefront',
      color: 0xFF34D399,
    ),
    const Category(
      id: 'cat_freelance',
      name: 'Freelance & Side Gig',
      nameUr: 'Freelance Kamai',
      kind: 'income',
      icon: 'laptop_mac',
      color: 0xFF38BDF8,
    ),
    const Category(
      id: 'cat_investment',
      name: 'Investment Profit',
      nameUr: 'Sarmayakari Munafa',
      kind: 'income',
      icon: 'trending_up',
      color: 0xFFFBBF24,
    ),
    const Category(
      id: 'cat_gift_income',
      name: 'Gift & Other Income',
      nameUr: 'Tohfa aur Deegar',
      kind: 'income',
      icon: 'card_giftcard',
      color: 0xFFA78BFA,
    ),
  ];

  for (final category in defaultCategories) {
    await hive.saveCategory(category);
  }
}
