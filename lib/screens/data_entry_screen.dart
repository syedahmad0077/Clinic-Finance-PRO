import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinic_finance_pro/models/transaction_model.dart';
import 'package:clinic_finance_pro/models/user_model.dart';
import 'package:clinic_finance_pro/services/local_database_service.dart';

class DataEntryScreen extends StatefulWidget {
  final TransactionModel? transactionToEdit;

  const DataEntryScreen({super.key, this.transactionToEdit});

  /// Static helper to open the data entry form cleanly as a modal sheet or dialog depending on screen size
  static Future<bool?> show(BuildContext context, {TransactionModel? transactionToEdit}) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 540,
            child: DataEntryScreen(transactionToEdit: transactionToEdit),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: DataEntryScreen(transactionToEdit: transactionToEdit),
          ),
        ),
      );
    }
  }

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localDbService = LocalDatabaseService();

  late String _type; // 'income' or 'expense'
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate;
  
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  bool _isLoadingUsers = true;
  bool _isSaving = false;

  bool get _isEditMode => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    _type = widget.transactionToEdit?.type ?? 'income';
    _amountController.text = widget.transactionToEdit != null
        ? widget.transactionToEdit!.amount.toStringAsFixed(2)
        : '';
    _descriptionController.text = widget.transactionToEdit?.description ?? '';
    _selectedDate = widget.transactionToEdit?.transactionDate ?? DateTime.now();

    _loadStaffUsers();
  }

  Future<void> _loadStaffUsers() async {
    setState(() => _isLoadingUsers = true);
    final users = await _localDbService.fetchUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoadingUsers = false;
        
        if (widget.transactionToEdit?.enteredBy != null) {
          _selectedUser = users.firstWhere(
            (u) => u.id == widget.transactionToEdit!.enteredBy,
            orElse: () => users.first,
          );
        } else if (users.isNotEmpty) {
          _selectedUser = users.first;
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select who is entering this transaction.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final transaction = TransactionModel(
      id: widget.transactionToEdit?.id,
      transactionDate: _selectedDate,
      type: _type,
      amount: amount,
      description: _descriptionController.text.trim(),
      enteredBy: _selectedUser!.id,
      user: _selectedUser,
    );

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        await _localDbService.updateTransaction(transaction);
      } else {
        await _localDbService.addTransaction(transaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Transaction updated successfully!'
                  : 'New entry added successfully!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save transaction: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_chart_rounded,
                        color: Color(0xFF0F766E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEditMode ? 'Edit Transaction' : 'Add New Transaction',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 28),

            // Type Toggle (Income / Expense)
            const Text(
              'Transaction Type',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'income'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'income' ? const Color(0xFFECFDF5) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _type == 'income' ? const Color(0xFF10B981) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            color: _type == 'income' ? const Color(0xFF10B981) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Income (Test/Fee)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _type == 'income' ? const Color(0xFF047857) : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'expense'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == 'expense' ? const Color(0xFFFEF2F2) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _type == 'expense' ? const Color(0xFFEF4444) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            color: _type == 'expense' ? const Color(0xFFEF4444) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Expense',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _type == 'expense' ? const Color(0xFFB91C1C) : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount & Date
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (PKR)',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter amount';
                      if (double.tryParse(val.trim()) == null) return 'Invalid number';
                      if (double.parse(val.trim()) <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Role-Based Dropdown (Entered By)
            _isLoadingUsers
                ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                : DropdownButtonFormField<UserModel>(
                    initialValue: _selectedUser,
                    decoration: InputDecoration(
                      labelText: 'Entered By (Role / Staff)',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _users.map((user) {
                      return DropdownMenuItem<UserModel>(
                        value: user,
                        child: Text(user.displayName),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedUser = val),
                    validator: (val) => val == null ? 'Select staff role' : null,
                  ),
            const SizedBox(height: 16),

            // Description / Test Detail
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (e.g. CBC Test, Electricity Bill)',
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Please enter description' : null,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E), // Clinic Deep Teal
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _saveTransaction,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _isEditMode ? 'Save Changes' : 'Record Transaction',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
