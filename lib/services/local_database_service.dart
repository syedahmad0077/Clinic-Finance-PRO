import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:clinic_finance_pro/models/transaction_model.dart';
import 'package:clinic_finance_pro/models/user_model.dart';
import 'package:clinic_finance_pro/models/patient_receipt_model.dart';
import 'package:clinic_finance_pro/models/clinic_token_model.dart';

/// Permanent Pure Hive Offline Hardware Database Service for Clinic Finance Pro
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal() {
    _initHiveBoxes();
  }

  static const String _boxTransactions = 'hive_transactions_db';
  static const String _boxReceipts = 'hive_patient_receipts_db';
  static const String _boxTokens = 'hive_clinic_tokens_db';
  static const String _boxUsers = 'hive_users_db';

  Box? _txBox;
  Box? _rcptBox;
  Box? _tokBox;
  Box? _usrBox;
  bool _isInitialized = false;

  final StreamController<List<TransactionModel>> _transactionStreamController =
      StreamController<List<TransactionModel>>.broadcast();

  final List<UserModel> defaultUsers = [
    UserModel(
      id: '11111111-1111-1111-1111-111111111111',
      name: 'Muzaffar',
      role: 'Lab',
    ),
    UserModel(
      id: '22222222-2222-2222-2222-222222222222',
      name: 'Dr. Naeem Sadiq',
      role: 'Clinic',
    ),
  ];

  Future<void> _initHiveBoxes() async {
    try {
      await Hive.initFlutter();
      _txBox = await Hive.openBox(_boxTransactions);
      _rcptBox = await Hive.openBox(_boxReceipts);
      _tokBox = await Hive.openBox(_boxTokens);
      _usrBox = await Hive.openBox(_boxUsers);
      _isInitialized = true;

      // Seed default staff members if user box is empty
      if (_usrBox!.isEmpty) {
        for (var user in defaultUsers) {
          await _usrBox!.put(user.id, jsonEncode(user.toMap()));
        }
      }
      debugPrint('Pure Hive Hardware Storage Engine initialized successfully.');
    } catch (e) {
      debugPrint('Error initializing Hive boxes: $e');
    }
  }

  Future<void> _ensureInit() async {
    if (!_isInitialized) {
      await _initHiveBoxes();
    }
  }

  // Fetch all staff users stored in Hive
  Future<List<UserModel>> fetchUsers() async {
    await _ensureInit();
    try {
      if (_usrBox != null && _usrBox!.isNotEmpty) {
        final List<UserModel> users = [];
        for (var key in _usrBox!.keys) {
          final val = _usrBox!.get(key);
          if (val != null) {
            final map = val is Map
                ? Map<String, dynamic>.from(val)
                : Map<String, dynamic>.from(jsonDecode(val.toString()));
            users.add(UserModel.fromMap(map));
          }
        }
        if (users.isNotEmpty) return users;
      }
    } catch (e) {
      debugPrint('Error fetching users from Hive: $e');
    }
    return defaultUsers;
  }

  // Helper to read all transactions from Hive disk box
  Future<List<TransactionModel>> _getAllTransactions() async {
    await _ensureInit();
    try {
      if (_txBox != null) {
        final usersList = await fetchUsers();
        final userMap = {for (var u in usersList) u.id: u};
        final List<TransactionModel> list = [];

        for (var key in _txBox!.keys) {
          final item = _txBox!.get(key);
          if (item != null) {
            final map = item is Map
                ? Map<String, dynamic>.from(item)
                : Map<String, dynamic>.from(jsonDecode(item.toString()));
            final model = TransactionModel.fromMap(map);

            // Exclude Clinic Token entries from main Expense Ledger
            if (model.id?.startsWith('tx_token_') == true ||
                model.description.startsWith('Clinic Token #')) {
              continue;
            }

            final userId = map['entered_by']?.toString();
            if (userId != null && userMap.containsKey(userId)) {
              list.add(model.copyWith(user: userMap[userId]));
            } else {
              list.add(model);
            }
          }
        }
        return list;
      }
    } catch (e) {
      debugPrint('Error reading transactions from Hive: $e');
    }
    return [];
  }

  /// Stream of Daily Transactions from local Hive database
  Stream<List<TransactionModel>> streamDailyTransactions(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    void emitDaily() async {
      final all = await _getAllTransactions();
      final filtered = all.where((t) {
        final tDateStr = DateFormat('yyyy-MM-dd').format(t.transactionDate);
        return tDateStr == dateStr;
      }).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _transactionStreamController.add(filtered);
    }

    emitDaily();
    return _transactionStreamController.stream;
  }

  /// Fetch Monthly Ledger Transactions from local Hive database
  Future<List<TransactionModel>> fetchMonthlyTransactions(
      int year, int month) async {
    final all = await _getAllTransactions();
    final filtered = all.where((t) {
      return t.transactionDate.year == year && t.transactionDate.month == month;
    }).toList();

    filtered.sort((a, b) {
      final cmp = b.transactionDate.compareTo(a.transactionDate);
      if (cmp != 0) return cmp;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  /// Add new income/expense transaction to Hive permanent storage
  Future<bool> addTransaction(TransactionModel transaction) async {
    await _ensureInit();
    final newId = transaction.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final newTx = transaction.copyWith(id: newId);

    try {
      final map = newTx.toMap();
      map['created_at'] = newTx.createdAt.toIso8601String();
      await _txBox!.put(newId, jsonEncode(map));
      _notifyStream(newTx.transactionDate);
      return true;
    } catch (e) {
      debugPrint('Error adding transaction to Hive: $e');
      return false;
    }
  }

  /// Update existing transaction in Hive permanent storage
  Future<bool> updateTransaction(TransactionModel transaction) async {
    if (transaction.id == null) return false;
    await _ensureInit();

    try {
      final map = transaction.toMap();
      map['created_at'] = transaction.createdAt.toIso8601String();
      await _txBox!.put(transaction.id!, jsonEncode(map));
      _notifyStream(transaction.transactionDate);
      return true;
    } catch (e) {
      debugPrint('Error updating transaction in Hive: $e');
      return false;
    }
  }

  /// Delete transaction permanently from Hive storage
  Future<bool> deleteTransaction(String id) async {
    await _ensureInit();
    try {
      final all = await _getAllTransactions();
      final target = all.firstWhere((t) => t.id == id, orElse: () => all.first);
      await _txBox!.delete(id);
      _notifyStream(target.transactionDate);
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction from Hive: $e');
      return false;
    }
  }

  Future<void> _notifyStream(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final all = await _getAllTransactions();
    final filtered = all.where((t) {
      final tDateStr = DateFormat('yyyy-MM-dd').format(t.transactionDate);
      return tDateStr == dateStr;
    }).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _transactionStreamController.add(filtered);
  }

  /// Save Lab Patient Receipt & Automatically sync Amount Paid to Ledger Transactions in Hive
  Future<bool> savePatientReceipt(PatientReceiptModel receipt) async {
    await _ensureInit();
    final txId = DateTime.now().millisecondsSinceEpoch.toString();
    final duesText = receipt.remainingBalance > 0
        ? ' [Dues: PKR ${receipt.remainingBalance.toStringAsFixed(2)}]'
        : ' [Fully Paid]';
    final transaction = TransactionModel(
      id: txId,
      transactionDate: DateTime.now(),
      type: 'income',
      amount: receipt.amountPaid,
      description:
          'Lab Receipt - ${receipt.patientName} (${receipt.tests.map((t) => t.name).join(", ")})$duesText',
      user: receipt.user,
    );

    // Save transaction entry to Hive
    await addTransaction(transaction);

    // Save receipt entry to Hive
    try {
      final rId = DateTime.now().millisecondsSinceEpoch.toString();
      final receiptData = receipt.toMap();
      receiptData['id'] = rId;
      receiptData['transaction_id'] = txId;
      receiptData['created_at'] = DateTime.now().toIso8601String();
      await _rcptBox!.put(rId, jsonEncode(receiptData));
      return true;
    } catch (e) {
      debugPrint('Error saving patient receipt to Hive: $e');
      return false;
    }
  }

  /// Clear remaining dues for a lab receipt & sync received dues amount to Ledger
  Future<bool> clearReceiptDues(PatientReceiptModel receipt, double dueAmountPaid) async {
    await _ensureInit();
    try {
      final updatedReceipt = receipt.copyWith(
        amountPaid: receipt.totalFee,
        remainingBalance: 0.0,
      );

      // Create a ledger transaction entry for the received dues
      final txId = DateTime.now().millisecondsSinceEpoch.toString();
      final transaction = TransactionModel(
        id: txId,
        transactionDate: DateTime.now(),
        type: 'income',
        amount: dueAmountPaid,
        description: 'Dues Received - Lab Receipt: ${receipt.patientName} [Cleared PKR ${dueAmountPaid.toStringAsFixed(2)}] [Fully Paid]',
        enteredBy: receipt.enteredBy,
      );
      await addTransaction(transaction);

      // Update receipt in Hive box
      final rId = receipt.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final receiptData = updatedReceipt.toMap();
      receiptData['id'] = rId;
      receiptData['transaction_id'] = txId;
      receiptData['created_at'] = updatedReceipt.createdAt.toIso8601String();
      await _rcptBox!.put(rId, jsonEncode(receiptData));
      return true;
    } catch (e) {
      debugPrint('Error clearing receipt dues in Hive: $e');
      return false;
    }
  }

  /// Fetch all saved Lab Patient Receipts from Hive hardware box
  Future<List<PatientReceiptModel>> fetchPatientReceipts() async {
    await _ensureInit();
    try {
      if (_rcptBox != null && _rcptBox!.isNotEmpty) {
        final usersList = await fetchUsers();
        final userMap = {for (var u in usersList) u.id: u};
        final List<PatientReceiptModel> receipts = [];

        for (var key in _rcptBox!.keys) {
          final item = _rcptBox!.get(key);
          if (item != null) {
            final map = item is Map
                ? Map<String, dynamic>.from(item)
                : Map<String, dynamic>.from(jsonDecode(item.toString()));
            final model = PatientReceiptModel.fromMap(map);
            final userId = map['entered_by']?.toString();
            if (userId != null && userMap.containsKey(userId)) {
              receipts.add(PatientReceiptModel.fromMap({
                ...map,
                'users': userMap[userId]!.toMap(),
              }));
            } else {
              receipts.add(model);
            }
          }
        }
        receipts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return receipts;
      }
    } catch (e) {
      debugPrint('Error fetching patient receipts from Hive: $e');
    }
    return [];
  }

  /// Get Next Token Number for Today (per Doctor or overall) from Hive storage
  Future<int> getNextTokenNumber([String? doctorName]) async {
    await _ensureInit();
    try {
      if (_tokBox != null && _tokBox!.isNotEmpty) {
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        int maxToken = 0;

        for (var key in _tokBox!.keys) {
          final item = _tokBox!.get(key);
          if (item != null) {
            final map = item is Map
                ? Map<String, dynamic>.from(item)
                : Map<String, dynamic>.from(jsonDecode(item.toString()));
            final createdAtStr = map['created_at']?.toString() ?? '';
            final doc = map['doctor_name']?.toString() ?? '';

            if (createdAtStr.startsWith(todayStr)) {
              if (doctorName == null || doctorName.trim().isEmpty || doc == doctorName) {
                final num = map['token_number'];
                if (num is int && num > maxToken) maxToken = num;
              }
            }
          }
        }
        return maxToken + 1;
      }
    } catch (e) {
      debugPrint('Error calculating token number from Hive: $e');
    }
    return 1;
  }

  /// Save Clinic Token Slip into Hive hardware box (Kept separate from main Expense Ledger)
  Future<bool> saveClinicToken(ClinicTokenModel token) async {
    await _ensureInit();
    try {
      final tokId = DateTime.now().millisecondsSinceEpoch.toString();
      final tokenData = token.toMap();
      tokenData['id'] = tokId;
      tokenData['created_at'] = DateTime.now().toIso8601String();
      await _tokBox!.put(tokId, jsonEncode(tokenData));
      return true;
    } catch (e) {
      debugPrint('Error saving clinic token to Hive: $e');
      return false;
    }
  }

  /// Fetch all saved Clinic Tokens from Hive hardware box
  Future<List<ClinicTokenModel>> fetchClinicTokens() async {
    await _ensureInit();
    try {
      if (_tokBox != null && _tokBox!.isNotEmpty) {
        final usersList = await fetchUsers();
        final userMap = {for (var u in usersList) u.id: u};
        final List<ClinicTokenModel> tokens = [];

        for (var key in _tokBox!.keys) {
          final item = _tokBox!.get(key);
          if (item != null) {
            final map = item is Map
                ? Map<String, dynamic>.from(item)
                : Map<String, dynamic>.from(jsonDecode(item.toString()));
            final model = ClinicTokenModel.fromMap(map);
            final userId = map['entered_by']?.toString();
            if (userId != null && userMap.containsKey(userId)) {
              tokens.add(ClinicTokenModel.fromMap({
                ...map,
                'users': userMap[userId]!.toMap(),
              }));
            } else {
              tokens.add(model);
            }
          }
        }
        tokens.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return tokens;
      }
    } catch (e) {
      debugPrint('Error fetching clinic tokens from Hive: $e');
    }
    return [];
  }

  /// Export all local Hive database records as a JSON string for offline hardware backup
  Future<String> exportBackupJson() async {
    await _ensureInit();
    final Map<String, dynamic> backupMap = {
      'app': 'Clinic Finance Pro',
      'version': '1.0.0',
      'export_timestamp': DateTime.now().toIso8601String(),
      'transactions': {},
      'receipts': {},
      'tokens': {},
      'users': {},
    };

    if (_txBox != null) {
      for (var key in _txBox!.keys) {
        backupMap['transactions'][key.toString()] = _txBox!.get(key);
      }
    }
    if (_rcptBox != null) {
      for (var key in _rcptBox!.keys) {
        backupMap['receipts'][key.toString()] = _rcptBox!.get(key);
      }
    }
    if (_tokBox != null) {
      for (var key in _tokBox!.keys) {
        backupMap['tokens'][key.toString()] = _tokBox!.get(key);
      }
    }
    if (_usrBox != null) {
      for (var key in _usrBox!.keys) {
        backupMap['users'][key.toString()] = _usrBox!.get(key);
      }
    }

    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  /// Restore local Hive database records from a JSON backup map
  Future<bool> importBackupJson(String jsonString) async {
    await _ensureInit();
    try {
      final Map<String, dynamic> backupMap = jsonDecode(jsonString);

      if (backupMap.containsKey('transactions') && backupMap['transactions'] is Map) {
        final txs = Map<String, dynamic>.from(backupMap['transactions']);
        for (var entry in txs.entries) {
          await _txBox!.put(entry.key, entry.value);
        }
      }

      if (backupMap.containsKey('receipts') && backupMap['receipts'] is Map) {
        final rcpts = Map<String, dynamic>.from(backupMap['receipts']);
        for (var entry in rcpts.entries) {
          await _rcptBox!.put(entry.key, entry.value);
        }
      }

      if (backupMap.containsKey('tokens') && backupMap['tokens'] is Map) {
        final toks = Map<String, dynamic>.from(backupMap['tokens']);
        for (var entry in toks.entries) {
          await _tokBox!.put(entry.key, entry.value);
        }
      }

      if (backupMap.containsKey('users') && backupMap['users'] is Map) {
        final usrs = Map<String, dynamic>.from(backupMap['users']);
        for (var entry in usrs.entries) {
          await _usrBox!.put(entry.key, entry.value);
        }
      }

      _notifyStream(DateTime.now());
      return true;
    } catch (e) {
      debugPrint('Error restoring backup into Hive: $e');
      return false;
    }
  }
}

