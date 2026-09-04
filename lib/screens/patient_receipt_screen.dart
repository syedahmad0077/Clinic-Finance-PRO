import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:clinic_finance_pro/models/patient_receipt_model.dart';
import 'package:clinic_finance_pro/models/user_model.dart';
import 'package:clinic_finance_pro/services/local_database_service.dart';
import 'package:clinic_finance_pro/services/pdf_receipt_service.dart';
import 'package:clinic_finance_pro/widgets/clinic_header.dart';

class PatientReceiptScreen extends StatefulWidget {
  const PatientReceiptScreen({super.key});

  @override
  State<PatientReceiptScreen> createState() => _PatientReceiptScreenState();
}

class _PatientReceiptScreenState extends State<PatientReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localDbService = LocalDatabaseService();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  String _gender = 'Male';

  // Dynamic Tests List
  final List<LabTestItem> _tests = [
    LabTestItem(name: 'CBC (Complete Blood Count)', price: 800.0),
  ];

  final _testNameController = TextEditingController();
  final _testPriceController = TextEditingController();

  final _amountPaidController = TextEditingController();
  double _manualTotalFee = 0.0;
  bool _useManualTotalFee = false;

  List<UserModel> _users = [];
  UserModel? _selectedUser;
  bool _isLoadingUsers = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _commonTests = [
    {'name': 'CBC (Blood Count)', 'price': 800.0},
    {'name': 'Blood Sugar (Fasting/Random)', 'price': 300.0},
    {'name': 'Lipid Profile', 'price': 1500.0},
    {'name': 'LFT (Liver Function Test)', 'price': 1400.0},
    {'name': 'RFT (Renal Function Test)', 'price': 1200.0},
    {'name': 'Urine Routine Examination', 'price': 400.0},
    {'name': 'Typhoid (Widal / ICT)', 'price': 600.0},
    {'name': 'HBsAg / Anti-HCV (Hepatitis)', 'price': 1000.0},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _updateAmountPaidDefault();
  }

  Future<void> _loadUsers() async {
    final users = await _localDbService.fetchUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoadingUsers = false;
        if (users.isNotEmpty) {
          _selectedUser = users.firstWhere(
            (u) => u.role.toLowerCase() == 'lab',
            orElse: () => users.first,
          );
        }
      });
    }
  }

  void _updateAmountPaidDefault() {
    _amountPaidController.text = _calculatedTotalFee.toStringAsFixed(2);
  }

  double get _calculatedTotalFee {
    if (_useManualTotalFee && _manualTotalFee > 0) return _manualTotalFee;
    return _tests.fold(0.0, (sum, item) => sum + item.price);
  }

  double get _amountPaid {
    return double.tryParse(_amountPaidController.text.trim()) ?? 0.0;
  }

  double get _remainingBalance {
    final balance = _calculatedTotalFee - _amountPaid;
    return balance < 0 ? 0.0 : balance;
  }

  void _addTest(String name, double price) {
    if (name.trim().isEmpty) return;
    setState(() {
      _tests.add(LabTestItem(name: name.trim(), price: price));
      _updateAmountPaidDefault();
    });
    _testNameController.clear();
    _testPriceController.clear();
  }

  void _removeTest(int index) {
    setState(() {
      _tests.removeAt(index);
      _updateAmountPaidDefault();
    });
  }

  Future<void> _saveAndPrintReceipt({bool printPdf = true}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_tests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one test to the receipt.')),
      );
      return;
    }

    final receipt = PatientReceiptModel(
      patientName: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      gender: _gender,
      contact: _contactController.text.trim(),
      tests: List.from(_tests),
      totalFee: _calculatedTotalFee,
      amountPaid: _amountPaid,
      remainingBalance: _remainingBalance,
      enteredBy: _selectedUser?.id,
      user: _selectedUser,
    );

    setState(() => _isSaving = true);

    try {
      // Save receipt & auto-sync to Local Ledger
      await _localDbService.savePatientReceipt(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lab receipt saved & income synced to Ledger!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }

      if (printPdf) {
        await PdfReceiptService.print4upA4LabReceipt(receipt);
      }

      _resetForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _nameController.clear();
    _ageController.clear();
    _contactController.clear();
    setState(() {
      _tests.clear();
      _tests.add(LabTestItem(name: 'CBC (Complete Blood Count)', price: 800.0));
      _useManualTotalFee = false;
      _updateAmountPaidDefault();
    });
  }

  void _showPdfPreview() {
    final receipt = PatientReceiptModel(
      patientName: _nameController.text.trim().isEmpty ? 'John Doe' : _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 30,
      gender: _gender,
      contact: _contactController.text.trim().isEmpty ? '+92 300 4915255' : _contactController.text.trim(),
      tests: List.from(_tests),
      totalFee: _calculatedTotalFee,
      amountPaid: _amountPaid,
      remainingBalance: _remainingBalance,
      user: _selectedUser,
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 700,
          height: 600,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('A4 4-in-1 Paper Saving PDF Preview'),
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            body: PdfPreview(
              build: (format) => PdfReceiptService.generate4upA4LabReceiptPdf(receipt),
            ),
          ),
        ),
      ),
    );
  }

  void _showSavedReceiptsHistory() {
    showDialog(
      context: context,
      builder: (context) => const _SavedLabReceiptsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lab Patient Receipt & Billing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('4-in-1 A4 Paper Saving Receipt System', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F766E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('Saved Receipts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: _showSavedReceiptsHistory,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Live A4 PDF Preview',
            onPressed: _showPdfPreview,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClinicHeader(
                title: 'SYED SADIQ POLY CLINIC & LAB',
                subtitle: 'Lab Patient Registration & 4-in-1 A4 Paper Saving Receipt',
              ),
              const SizedBox(height: 20),

              // Patient Info Section
              const Text('1. Patient Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Patient Full Name *',
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter patient name' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age (Yrs)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: const Icon(Icons.wc_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Child', child: Text('Child')),
                            ],
                            onChanged: (val) => setState(() => _gender = val ?? 'Male'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _contactController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Contact / Mobile No.',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tests & Billing Details Section
              const Text('2. Lab Tests & Billing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick add test chips
                    const Text('Quick Add Common Tests:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _commonTests.map((t) {
                        return ActionChip(
                          avatar: const Icon(Icons.add, size: 14, color: Color(0xFF0F766E)),
                          label: Text('${t['name']} (Rs.${t['price'].toInt()})', style: const TextStyle(fontSize: 12)),
                          backgroundColor: const Color(0xFFECFDF5),
                          onPressed: () => _addTest(t['name'], t['price']),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 24),

                    // Custom test input row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _testNameController,
                            decoration: InputDecoration(
                              hintText: 'Custom Test Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _testPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Price (PKR)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            final price = double.tryParse(_testPriceController.text.trim()) ?? 0.0;
                            _addTest(_testNameController.text, price);
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selected tests table
                    if (_tests.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('No tests added yet.', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tests.length,
                        itemBuilder: (context, index) {
                          final test = _tests[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Text('${index + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(test.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                Text('PKR ${test.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _removeTest(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const Divider(height: 24),

                    // Financial calculations
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Fee: PKR ${_calculatedTotalFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _amountPaidController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount Paid (Cash)',
                                  prefixIcon: const Icon(Icons.payments_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (val) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _remainingBalance > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _remainingBalance > 0 ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_remainingBalance > 0 ? 'Dues / Remaining Balance' : 'Fully Paid',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _remainingBalance > 0 ? Colors.red.shade800 : Colors.green.shade800)),
                                const SizedBox(height: 4),
                                Text(
                                  'PKR ${_remainingBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _remainingBalance > 0 ? Colors.red.shade800 : Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Staff Signature Assignment Dropdown
                    _isLoadingUsers
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<UserModel>(
                            initialValue: _selectedUser,
                            decoration: InputDecoration(
                              labelText: 'Authorized Signature (Staff / Doctor)',
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: _users.map((u) => DropdownMenuItem(value: u, child: Text(u.displayName))).toList(),
                            onChanged: (val) => setState(() => _selectedUser = val),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.print_rounded),
                        label: const Text('Save & Print A4 Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: _isSaving ? null : () => _saveAndPrintReceipt(printPdf: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save to Ledger Only'),
                      onPressed: _isSaving ? null : () => _saveAndPrintReceipt(printPdf: false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedLabReceiptsDialog extends StatefulWidget {
  const _SavedLabReceiptsDialog();

  @override
  State<_SavedLabReceiptsDialog> createState() => _SavedLabReceiptsDialogState();
}

class _SavedLabReceiptsDialogState extends State<_SavedLabReceiptsDialog> {
  final _localDbService = LocalDatabaseService();
  final _searchController = TextEditingController();
  List<PatientReceiptModel> _allReceipts = [];
  List<PatientReceiptModel> _filteredReceipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    final receipts = await _localDbService.fetchPatientReceipts();
    if (mounted) {
      setState(() {
        _allReceipts = receipts;
        _filteredReceipts = receipts;
        _isLoading = false;
      });
    }
  }

  void _filterReceipts(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredReceipts = _allReceipts;
      } else {
        _filteredReceipts = _allReceipts.where((r) {
          final testsStr = r.tests.map((t) => t.name.toLowerCase()).join(' ');
          return r.patientName.toLowerCase().contains(q) ||
              r.contact.toLowerCase().contains(q) ||
              testsStr.contains(q);
        }).toList();
      }
    });
  }

  void _previewReceipt(PatientReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 700,
          height: 600,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Lab Receipt - ${receipt.patientName}'),
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            body: PdfPreview(
              build: (format) => PdfReceiptService.generate4upA4LabReceiptPdf(receipt),
            ),
          ),
        ),
      ),
    );
  }

  void _clearReceiptDues(PatientReceiptModel rcpt) {
    final due = rcpt.remainingBalance;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Receive Remaining Dues'),
        content: Text(
          'Mark dues as fully paid for ${rcpt.patientName}?\n\n'
          'Remaining Dues Amount: PKR ${due.toStringAsFixed(2)}\n'
          'This will update the receipt to Fully Paid and log the received income to the Daily Ledger.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: Text('Receive PKR ${due.toInt()}'),
            onPressed: () async {
              Navigator.pop(context);
              await _localDbService.clearReceiptDues(rcpt, due);
              await _loadReceipts();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dues of PKR ${due.toInt()} cleared & synced to Ledger!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 860,
        height: 680,
        child: Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved Lab Receipts History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Permanent Local Database Records (محفوظ شدہ لیب رسیدیں)', style: TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _filterReceipts,
                  decoration: InputDecoration(
                    hintText: 'Search by Patient Name, Contact, or Test Name...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _filterReceipts('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Total Summary Card (Total Paid & Total Pending Dues)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.science_rounded, color: Color(0xFF0F766E), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Total Receipts: ${_filteredReceipts.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Paid: PKR ${NumberFormat('#,##0.00', 'en_US').format(_filteredReceipts.fold(0.0, (sum, r) => sum + r.amountPaid))}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              'Pending Dues: PKR ${NumberFormat('#,##0.00', 'en_US').format(_filteredReceipts.fold(0.0, (sum, r) => sum + r.remainingBalance))}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFB91C1C)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Saved Receipts List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredReceipts.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('No saved lab receipts found.', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredReceipts.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final rcpt = _filteredReceipts[index];
                                final dateStr = DateFormat('dd-MMM-yyyy hh:mm a').format(rcpt.createdAt);
                                final testsListStr = rcpt.tests.map((t) => t.name).join(', ');
                                final hasDues = rcpt.remainingBalance > 0;

                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: const CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Color(0xFF0F766E),
                                      child: Icon(Icons.science_rounded, color: Colors.white, size: 24),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          rcpt.patientName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${rcpt.age} Yrs / ${rcpt.gender})',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        if (hasDues) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFFECACA)),
                                            ),
                                            child: Text(
                                              'Dues: PKR ${rcpt.remainingBalance.toInt()}',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Tests: $testsListStr', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Date: $dateStr | Total: PKR ${rcpt.totalFee.toInt()} | Paid: PKR ${rcpt.amountPaid.toInt()}',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (hasDues)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFEF4444),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            ),
                                            icon: const Icon(Icons.payments_outlined, size: 14),
                                            label: Text('Receive Dues (PKR ${rcpt.remainingBalance.toInt()})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            onPressed: () => _clearReceiptDues(rcpt),
                                          ),
                                        if (hasDues) const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF0F766E)),
                                          tooltip: 'Preview Receipt',
                                          onPressed: () => _previewReceipt(rcpt),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0F766E),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: const Icon(Icons.print_rounded, size: 16),
                                          label: const Text('Re-Print'),
                                          onPressed: () => PdfReceiptService.print4upA4LabReceipt(rcpt),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
