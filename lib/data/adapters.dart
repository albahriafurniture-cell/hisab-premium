import 'package:hive/hive.dart';
import 'models.dart';

/// Hand-written Hive TypeAdapters for Hisab Premium.
/// SPEC typeIds:
/// 0 = Account
/// 1 = Category
/// 2 = Txn
/// 3 = Person
/// 4 = LoanEntry
/// 5 = AppSettings

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 0;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as String,
      name: fields[1] as String,
      kind: fields[2] as String,
      color: fields[3] as int,
      icon: fields[4] as String,
      balance: (fields[5] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.kind)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.icon)
      ..writeByte(5)
      ..write(obj.balance);
  }
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 1;

  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(
      id: fields[0] as String,
      name: fields[1] as String,
      nameUr: fields[2] as String,
      kind: fields[3] as String,
      icon: fields[4] as String,
      color: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.nameUr)
      ..writeByte(3)
      ..write(obj.kind)
      ..writeByte(4)
      ..write(obj.icon)
      ..writeByte(5)
      ..write(obj.color);
  }
}

class TxnAdapter extends TypeAdapter<Txn> {
  @override
  final int typeId = 2;

  @override
  Txn read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Txn(
      id: fields[0] as String,
      kind: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      categoryId: fields[3] as String,
      accountId: fields[4] as String,
      note: fields[5] as String,
      date: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Txn obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.kind)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.accountId)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.date);
  }
}

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final int typeId = 3;

  @override
  Person read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Person(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      note: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.note);
  }
}

class LoanEntryAdapter extends TypeAdapter<LoanEntry> {
  @override
  final int typeId = 4;

  @override
  LoanEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoanEntry(
      id: fields[0] as String,
      personId: fields[1] as String,
      direction: fields[2] as String,
      principal: (fields[3] as num).toDouble(),
      repaid: (fields[4] as num).toDouble(),
      date: fields[5] as DateTime,
      dueDate: fields[6] as DateTime?,
      note: fields[7] as String,
      status: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LoanEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personId)
      ..writeByte(2)
      ..write(obj.direction)
      ..writeByte(3)
      ..write(obj.principal)
      ..writeByte(4)
      ..write(obj.repaid)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.status);
  }
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 5;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      pinHash: (fields[0] as String?) ?? '',
      locale: (fields[1] as String?) ?? 'en',
      currency: (fields[2] as String?) ?? 'PKR',
      onboarded: (fields[3] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.pinHash)
      ..writeByte(1)
      ..write(obj.locale)
      ..writeByte(2)
      ..write(obj.currency)
      ..writeByte(3)
      ..write(obj.onboarded);
  }
}
