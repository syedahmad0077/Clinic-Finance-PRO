import 'package:clinic_finance_pro/models/user_model.dart';

class LabTestItem {
  String name;
  double price;

  LabTestItem({
    required this.name,
    required this.price,
  });

  factory LabTestItem.fromMap(Map<String, dynamic> map) {
    return LabTestItem(
      name: map['name']?.toString() ?? '',
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }
}

class PatientReceiptModel {
  final String? id;
  final DateTime createdAt;
  final String patientName;
  final int age;
  final String gender;
  final String contact;
  final List<LabTestItem> tests;
  final double totalFee;
  final double amountPaid;
  final double remainingBalance;
  final String? enteredBy;
  final String? transactionId;
  final UserModel? user;

  PatientReceiptModel({
    this.id,
    DateTime? createdAt,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.contact,
    required this.tests,
    required this.totalFee,
    required this.amountPaid,
    required this.remainingBalance,
    this.enteredBy,
    this.transactionId,
    this.user,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PatientReceiptModel.fromMap(Map<String, dynamic> map) {
    List<LabTestItem> testList = [];
    if (map['tests'] != null && map['tests'] is List) {
      testList = (map['tests'] as List)
          .map((t) => LabTestItem.fromMap(Map<String, dynamic>.from(t)))
          .toList();
    }

    UserModel? userObj;
    if (map['users'] != null && map['users'] is Map<String, dynamic>) {
      userObj = UserModel.fromMap(map['users']);
    }

    return PatientReceiptModel(
      id: map['id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      patientName: map['patient_name']?.toString() ?? '',
      age: int.tryParse(map['age']?.toString() ?? '0') ?? 0,
      gender: map['gender']?.toString() ?? 'Male',
      contact: map['contact']?.toString() ?? '',
      tests: testList,
      totalFee: (map['total_fee'] is num)
          ? (map['total_fee'] as num).toDouble()
          : double.tryParse(map['total_fee']?.toString() ?? '0') ?? 0.0,
      amountPaid: (map['amount_paid'] is num)
          ? (map['amount_paid'] as num).toDouble()
          : double.tryParse(map['amount_paid']?.toString() ?? '0') ?? 0.0,
      remainingBalance: (map['remaining_balance'] is num)
          ? (map['remaining_balance'] as num).toDouble()
          : double.tryParse(map['remaining_balance']?.toString() ?? '0') ?? 0.0,
      enteredBy: map['entered_by']?.toString(),
      transactionId: map['transaction_id']?.toString(),
      user: userObj,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'patient_name': patientName,
      'age': age,
      'gender': gender,
      'contact': contact,
      'tests': tests.map((t) => t.toMap()).toList(),
      'total_fee': totalFee,
      'amount_paid': amountPaid,
      'remaining_balance': remainingBalance,
      'entered_by': enteredBy,
    };
    if (id != null && id!.isNotEmpty) map['id'] = id;
    if (transactionId != null) map['transaction_id'] = transactionId;
    return map;
  }

  PatientReceiptModel copyWith({
    String? id,
    DateTime? createdAt,
    String? patientName,
    int? age,
    String? gender,
    String? contact,
    List<LabTestItem>? tests,
    double? totalFee,
    double? amountPaid,
    double? remainingBalance,
    String? enteredBy,
    String? transactionId,
    UserModel? user,
  }) {
    return PatientReceiptModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      patientName: patientName ?? this.patientName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      contact: contact ?? this.contact,
      tests: tests ?? this.tests,
      totalFee: totalFee ?? this.totalFee,
      amountPaid: amountPaid ?? this.amountPaid,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      enteredBy: enteredBy ?? this.enteredBy,
      transactionId: transactionId ?? this.transactionId,
      user: user ?? this.user,
    );
  }
}
