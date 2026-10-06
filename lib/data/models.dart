library;
/// Plain Dart models for Hisab Premium data layer.
/// Exactly follows the SPEC schema with copyWith, equals, and hashCode.

class Account {
  final String id;
  final String name;
  final String kind; // 'cash' | 'bank' | 'wallet'
  final int color;
  final String icon;
  final double balance;

  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.color,
    required this.icon,
    required this.balance,
  });

  Account copyWith({
    String? id,
    String? name,
    String? kind,
    int? color,
    String? icon,
    double? balance,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      balance: balance ?? this.balance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          kind == other.kind &&
          color == other.color &&
          icon == other.icon &&
          balance == other.balance;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      kind.hashCode ^
      color.hashCode ^
      icon.hashCode ^
      balance.hashCode;

  @override
  String toString() =>
      'Account(id: $id, name: $name, kind: $kind, balance: $balance)';
}

class Category {
  final String id;
  final String name;
  final String nameUr;
  final String kind; // 'income' | 'expense'
  final String icon;
  final int color;

  const Category({
    required this.id,
    required this.name,
    required this.nameUr,
    required this.kind,
    required this.icon,
    required this.color,
  });

  Category copyWith({
    String? id,
    String? name,
    String? nameUr,
    String? kind,
    String? icon,
    int? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      nameUr: nameUr ?? this.nameUr,
      kind: kind ?? this.kind,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          nameUr == other.nameUr &&
          kind == other.kind &&
          icon == other.icon &&
          color == other.color;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      nameUr.hashCode ^
      kind.hashCode ^
      icon.hashCode ^
      color.hashCode;

  @override
  String toString() =>
      'Category(id: $id, name: $name, nameUr: $nameUr, kind: $kind)';
}

class Txn {
  final String id;
  final String kind; // 'income' | 'expense'
  final double amount;
  final String categoryId;
  final String accountId;
  final String note;
  final DateTime date;

  const Txn({
    required this.id,
    required this.kind,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.note,
    required this.date,
  });

  Txn copyWith({
    String? id,
    String? kind,
    double? amount,
    String? categoryId,
    String? accountId,
    String? note,
    DateTime? date,
  }) {
    return Txn(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Txn &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          amount == other.amount &&
          categoryId == other.categoryId &&
          accountId == other.accountId &&
          note == other.note &&
          date == other.date;

  @override
  int get hashCode =>
      id.hashCode ^
      kind.hashCode ^
      amount.hashCode ^
      categoryId.hashCode ^
      accountId.hashCode ^
      note.hashCode ^
      date.hashCode;

  @override
  String toString() =>
      'Txn(id: $id, kind: $kind, amount: $amount, date: $date)';
}

class Person {
  final String id;
  final String name;
  final String phone;
  final String note;

  const Person({
    required this.id,
    required this.name,
    required this.phone,
    required this.note,
  });

  Person copyWith({
    String? id,
    String? name,
    String? phone,
    String? note,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ phone.hashCode ^ note.hashCode;

  @override
  String toString() => 'Person(id: $id, name: $name, phone: $phone)';
}

class LoanEntry {
  final String id;
  final String personId;
  final String direction; // 'given' (receivable) | 'taken' (payable)
  final double principal;
  final double repaid;
  final DateTime date;
  final DateTime? dueDate;
  final String note;
  final String status; // 'active' | 'settled'

  const LoanEntry({
    required this.id,
    required this.personId,
    required this.direction,
    required this.principal,
    this.repaid = 0.0,
    required this.date,
    this.dueDate,
    this.note = '',
    this.status = 'active',
  });

  double get remaining =>
      (principal - repaid) > 0 ? (principal - repaid) : 0.0;

  bool get isSettled => status == 'settled' || repaid >= principal;

  bool get isOverdue {
    if (isSettled || dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  LoanEntry copyWith({
    String? id,
    String? personId,
    String? direction,
    double? principal,
    double? repaid,
    DateTime? date,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? note,
    String? status,
  }) {
    return LoanEntry(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      direction: direction ?? this.direction,
      principal: principal ?? this.principal,
      repaid: repaid ?? this.repaid,
      date: date ?? this.date,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      note: note ?? this.note,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          personId == other.personId &&
          direction == other.direction &&
          principal == other.principal &&
          repaid == other.repaid &&
          date == other.date &&
          dueDate == other.dueDate &&
          note == other.note &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      personId.hashCode ^
      direction.hashCode ^
      principal.hashCode ^
      repaid.hashCode ^
      date.hashCode ^
      dueDate.hashCode ^
      note.hashCode ^
      status.hashCode;

  @override
  String toString() =>
      'LoanEntry(id: $id, personId: $personId, direction: $direction, principal: $principal, repaid: $repaid, status: $status)';
}

class AppSettings {
  final String pinHash;
  final String locale; // 'en' | 'ur'
  final String currency; // default 'PKR'
  final bool onboarded;

  const AppSettings({
    this.pinHash = '',
    this.locale = 'en',
    this.currency = 'PKR',
    this.onboarded = false,
  });

  bool get hasPin => pinHash.isNotEmpty;

  AppSettings copyWith({
    String? pinHash,
    String? locale,
    String? currency,
    bool? onboarded,
  }) {
    return AppSettings(
      pinHash: pinHash ?? this.pinHash,
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          pinHash == other.pinHash &&
          locale == other.locale &&
          currency == other.currency &&
          onboarded == other.onboarded;

  @override
  int get hashCode =>
      pinHash.hashCode ^
      locale.hashCode ^
      currency.hashCode ^
      onboarded.hashCode;

  @override
  String toString() =>
      'AppSettings(pinHash: ${pinHash.isEmpty ? "none" : "***"}, locale: $locale, currency: $currency, onboarded: $onboarded)';
}
