import 'package:clinic_finance_pro/models/user_model.dart';

class TransactionModel {
  final String? id;
  final DateTime createdAt;
  final DateTime transactionDate;
  final String type; // 'income' or 'expense'
  final double amount;
  final String description;
  final String? enteredBy;
  final UserModel? user;

  TransactionModel({
    this.id,
    DateTime? createdAt,
    required this.transactionDate,
    required this.type,
    required this.amount,
    required this.description,
    this.enteredBy,
    this.user,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isIncome => type.toLowerCase() == 'income';
  bool get isExpense => type.toLowerCase() == 'expense';

  /// Converts transaction record from local database map (with optional nested user details)
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    UserModel? userObj;
    if (map['users'] != null && map['users'] is Map<String, dynamic>) {
      userObj = UserModel.fromMap(map['users']);
    }

    return TransactionModel(
      id: map['id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      transactionDate: map['transaction_date'] != null
          ? DateTime.parse(map['transaction_date'].toString())
          : DateTime.now(),
      type: map['type']?.toString() ?? 'income',
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      description: map['description']?.toString() ?? '',
      enteredBy: map['entered_by']?.toString(),
      user: userObj,
    );
  }

  /// Converts TransactionModel to Map for local database inserts / updates
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'transaction_date':
          "${transactionDate.year.toString().padLeft(4, '0')}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}",
      'type': type.toLowerCase(),
      'amount': amount,
      'description': description,
      'entered_by': enteredBy,
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  /// Display string for who entered the record
  String get enteredByDisplayName {
    if (user != null) {
      return user!.displayName;
    }
    return 'General Staff';
  }

  TransactionModel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? transactionDate,
    String? type,
    double? amount,
    String? description,
    String? enteredBy,
    UserModel? user,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      transactionDate: transactionDate ?? this.transactionDate,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      enteredBy: enteredBy ?? this.enteredBy,
      user: user ?? this.user,
    );
  }
}
