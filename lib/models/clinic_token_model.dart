import 'package:clinic_finance_pro/models/user_model.dart';

class ClinicTokenModel {
  final String? id;
  final DateTime createdAt;
  final String tokenCode;
  final String patientName;
  final int age;
  final String gender;
  final String contact;
  final String doctorName;
  final String doctorSpecialization;
  final String patientType; // 'Routine', 'Emergency', 'Follow up'
  final int tokenNumber;
  final double consultationFee;
  final String? enteredBy;
  final String? transactionId;
  final UserModel? user;

  ClinicTokenModel({
    this.id,
    DateTime? createdAt,
    String? tokenCode,
    required this.patientName,
    this.age = 0,
    this.gender = 'Male',
    required this.contact,
    required this.doctorName,
    this.doctorSpecialization = 'Consultant Physician',
    this.patientType = 'Routine',
    required this.tokenNumber,
    required this.consultationFee,
    this.enteredBy,
    this.transactionId,
    this.user,
  })  : createdAt = createdAt ?? DateTime.now(),
        tokenCode = tokenCode ?? 'Te${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

  factory ClinicTokenModel.fromMap(Map<String, dynamic> map) {
    UserModel? userObj;
    if (map['users'] != null && map['users'] is Map<String, dynamic>) {
      userObj = UserModel.fromMap(map['users']);
    }

    return ClinicTokenModel(
      id: map['id']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      tokenCode: map['token_code']?.toString() ?? 'Te17076',
      patientName: map['patient_name']?.toString() ?? '',
      age: int.tryParse(map['age']?.toString() ?? '0') ?? 0,
      gender: map['gender']?.toString() ?? 'Male',
      contact: map['contact']?.toString() ?? '',
      doctorName: map['doctor_name']?.toString() ?? 'Dr. Kashif Bashir',
      doctorSpecialization: map['doctor_specialization']?.toString() ?? 'Consultant Physician',
      patientType: map['patient_type']?.toString() ?? 'Routine',
      tokenNumber: int.tryParse(map['token_number']?.toString() ?? '1') ?? 1,
      consultationFee: (map['consultation_fee'] is num)
          ? (map['consultation_fee'] as num).toDouble()
          : double.tryParse(map['consultation_fee']?.toString() ?? '0') ?? 0.0,
      enteredBy: map['entered_by']?.toString(),
      transactionId: map['transaction_id']?.toString(),
      user: userObj,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'token_code': tokenCode,
      'patient_name': patientName,
      'age': age,
      'gender': gender,
      'contact': contact,
      'doctor_name': doctorName,
      'doctor_specialization': doctorSpecialization,
      'patient_type': patientType,
      'token_number': tokenNumber,
      'consultation_fee': consultationFee,
      'entered_by': enteredBy,
    };
    if (id != null && id!.isNotEmpty) map['id'] = id;
    if (transactionId != null) map['transaction_id'] = transactionId;
    return map;
  }
}
