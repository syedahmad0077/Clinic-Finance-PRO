import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:clinic_finance_pro/models/clinic_token_model.dart';
import 'package:clinic_finance_pro/models/user_model.dart';
import 'package:clinic_finance_pro/services/local_database_service.dart';
import 'package:clinic_finance_pro/services/pdf_receipt_service.dart';
import 'package:clinic_finance_pro/widgets/clinic_header.dart';

class ClinicTokenScreen extends StatefulWidget {
  const ClinicTokenScreen({super.key});

  @override
  State<ClinicTokenScreen> createState() => _ClinicTokenScreenState();
}

class _ClinicTokenScreenState extends State<ClinicTokenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _localDbService = LocalDatabaseService();

  final _patientNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _tokenNumberController = TextEditingController();
  final _feeController = TextEditingController();
  final _specializationController = TextEditingController();
  final _customDoctorController = TextEditingController();

  String _gender = 'Male';
  String _patientType = 'Routine';

  // Preset list of Doctors requested by the user
  final List<Map<String, String>> _availableDoctors = [
    {
      'name': 'Dr. Hina Tabassum',
      'specialization': 'Cardiologist',
      'fee': '1200.00',
    },
    {
      'name': 'Dr. Mian Kaleem',
      'specialization': 'Neurologist',
      'fee': '1500.00',
    },
    {
      'name': 'Dr. Kashif Bashir',
      'specialization': 'Gastroenterologist',
      'fee': '1000.00',
    },
    {
      'name': 'Dr. Naeem Sadiq',
      'specialization': 'Senior Medical Consultant',
      'fee': '1000.00',
    },
  ];

  late String _selectedDoctorName;
  bool _isCustomDoctor = false;

  List<UserModel> _users = [];
  UserModel? _selectedUser;
  bool _isLoadingUsers = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDoctorName = _availableDoctors.first['name']!;
    _specializationController.text = _availableDoctors.first['specialization']!;
    _feeController.text = _availableDoctors.first['fee']!;

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingUsers = true);
    final users = await _localDbService.fetchUsers();
    await _updateTokenNumberForDoctor(_selectedDoctorName);

    if (mounted) {
      setState(() {
        _users = users;
        _isLoadingUsers = false;

        if (users.isNotEmpty) {
          _selectedUser = users.firstWhere(
            (u) => u.role.toLowerCase() == 'clinic',
            orElse: () => users.first,
          );
        }
      });
    }
  }

  Future<void> _updateTokenNumberForDoctor(String doctorName) async {
    final nextToken = await _localDbService.getNextTokenNumber(doctorName);
    if (mounted) {
      setState(() {
        _tokenNumberController.text = nextToken.toString();
      });
    }
  }

  void _onDoctorSelected(String? doctorName) {
    if (doctorName == null) return;
    if (doctorName == 'custom') {
      setState(() {
        _isCustomDoctor = true;
        _selectedDoctorName = '';
        _specializationController.text = 'Medical Specialist';
      });
    } else {
      final docInfo = _availableDoctors.firstWhere(
        (d) => d['name'] == doctorName,
        orElse: () => _availableDoctors.first,
      );
      setState(() {
        _isCustomDoctor = false;
        _selectedDoctorName = docInfo['name']!;
        _specializationController.text = docInfo['specialization']!;
        _feeController.text = docInfo['fee']!;
      });
      _updateTokenNumberForDoctor(docInfo['name']!);
    }
  }

  String get _effectiveDoctorName {
    if (_isCustomDoctor) {
      final text = _customDoctorController.text.trim();
      return text.isEmpty ? 'Dr. Consultant' : (text.startsWith('Dr.') ? text : 'Dr. $text');
    }
    return _selectedDoctorName;
  }

  Future<void> _issueAndPrintToken({bool printSlip = true}) async {
    if (!_formKey.currentState!.validate()) return;

    final tokenNum = int.tryParse(_tokenNumberController.text.trim()) ?? 1;
    final fee = double.tryParse(_feeController.text.trim()) ?? 0.0;
    final age = int.tryParse(_ageController.text.trim()) ?? 0;

    final token = ClinicTokenModel(
      patientName: _patientNameController.text.trim(),
      age: age,
      gender: _gender,
      contact: _contactController.text.trim(),
      doctorName: _effectiveDoctorName,
      doctorSpecialization: _specializationController.text.trim(),
      patientType: _patientType,
      tokenNumber: tokenNum,
      consultationFee: fee,
      enteredBy: _selectedUser?.id,
      user: _selectedUser,
    );

    setState(() => _isSaving = true);

    try {
      // Save token to Hive DB & sync consultation fee to ledger
      await _localDbService.saveClinicToken(token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token #$tokenNum for ${token.doctorName} issued! Fee: PKR $fee'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }

      if (printSlip) {
        await PdfReceiptService.printClinicToken(token);
      }

      // Advance token sequence number while preserving patient name on screen
      if (mounted) {
        setState(() {
          _tokenNumberController.text = (tokenNum + 1).toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error issuing token: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _patientNameController.clear();
    _ageController.clear();
    _contactController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form cleared for next patient!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showTokenSlipPreview() {
    final tokenNum = int.tryParse(_tokenNumberController.text.trim()) ?? 1;
    final fee = double.tryParse(_feeController.text.trim()) ?? 0.0;
    final age = int.tryParse(_ageController.text.trim()) ?? 35;

    final sampleToken = ClinicTokenModel(
      patientName: _patientNameController.text.trim().isEmpty
          ? 'SYED TAHIR'
          : _patientNameController.text.trim(),
      age: age,
      gender: _gender,
      contact: _contactController.text.trim().isEmpty ? '03004915255' : _contactController.text.trim(),
      doctorName: _effectiveDoctorName,
      doctorSpecialization: _specializationController.text.trim(),
      patientType: _patientType,
      tokenNumber: tokenNum,
      consultationFee: fee,
      user: _selectedUser,
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 500,
          height: 650,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Token Slip Thermal Preview'),
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            body: PdfPreview(
              build: (format) => PdfReceiptService.generateClinicTokenPdf(sampleToken),
            ),
          ),
        ),
      ),
    );
  }

  void _showSavedTokensHistory() {
    showDialog(
      context: context,
      builder: (context) => const _SavedTokensDialog(),
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
            Text('Doctor Token Slip Generation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Hospital Parachi Format with Barcode & Doctor Selection', style: TextStyle(fontSize: 12)),
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
            label: const Text('Saved Parachiyan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: _showSavedTokensHistory,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Live Parachi Preview',
            onPressed: _showTokenSlipPreview,
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
                title: 'SYED SADIQ POLY CLINIC & HOSPITAL',
                subtitle: 'Patient Registration & Doctor Token Parachi Module',
              ),
              const SizedBox(height: 16),

              // 1. Select Doctor Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0F766E), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '1. Select Doctor for Token Parachi *',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _isCustomDoctor ? 'custom' : _selectedDoctorName,
                      decoration: InputDecoration(
                        labelText: 'Choose Attending Doctor',
                        prefixIcon: const Icon(Icons.person_pin_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        ..._availableDoctors.map((doc) {
                          return DropdownMenuItem<String>(
                            value: doc['name'],
                            child: Text(doc['name']!),
                          );
                        }),
                        const DropdownMenuItem<String>(
                          value: 'custom',
                          child: Text('+ Add Other / Custom Doctor Name'),
                        ),
                      ],
                      onChanged: _onDoctorSelected,
                    ),

                    if (_isCustomDoctor) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customDoctorController,
                        decoration: InputDecoration(
                          labelText: 'Enter Custom Doctor Full Name *',
                          hintText: 'e.g. Dr. Shabahat Ali',
                          prefixIcon: const Icon(Icons.edit_note_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) => _updateTokenNumberForDoctor(_effectiveDoctorName),
                        validator: (val) => _isCustomDoctor && (val == null || val.trim().isEmpty)
                            ? 'Enter doctor name'
                            : null,
                      ),
                    ],

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _specializationController,
                      decoration: InputDecoration(
                        labelText: 'Doctor Specialization / Category',
                        prefixIcon: const Icon(Icons.medical_services_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Token Display Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOKEN PARACHI NUMBER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _effectiveDoctorName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Today\'s Patient Sequence',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 110,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _tokenNumberController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Patient Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. Patient Details & Consultation Fee',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Patient Name & Age
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _patientNameController,
                            decoration: InputDecoration(
                              labelText: 'Patient Full Name *',
                              hintText: 'e.g. SYED TAHIR',
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty) ? 'Please enter patient name' : null,
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender & Contact
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: const Icon(Icons.wc_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                              labelText: 'Mobile / Contact No.',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Patient Visit Type & Fee Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _patientType,
                            decoration: InputDecoration(
                              labelText: 'Patient / Visit Category',
                              prefixIcon: const Icon(Icons.category_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Routine', child: Text('Routine Checkup')),
                              DropdownMenuItem(value: 'Follow up', child: Text('Follow-up Visit')),
                              DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
                            ],
                            onChanged: (val) => setState(() => _patientType = val ?? 'Routine'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _feeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount Paid (Fee PKR) *',
                              prefixIcon: const Icon(Icons.payments_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter fee';
                              if (double.tryParse(val.trim()) == null) return 'Invalid fee';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Receptionist Signature Staff
                    _isLoadingUsers
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<UserModel>(
                            initialValue: _selectedUser,
                            decoration: InputDecoration(
                              labelText: 'Reception Staff / User',
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _users
                                .map((u) => DropdownMenuItem(value: u, child: Text(u.displayName)))
                                .toList(),
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
                        label: const Text('Issue & Print Token Parachi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: _isSaving ? null : () => _issueAndPrintToken(printSlip: true),
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
                      label: const Text('Save Parachi Only'),
                      onPressed: _isSaving ? null : () => _issueAndPrintToken(printSlip: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('New Patient (Clear)'),
                      onPressed: _clearForm,
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

class _SavedTokensDialog extends StatefulWidget {
  const _SavedTokensDialog();

  @override
  State<_SavedTokensDialog> createState() => _SavedTokensDialogState();
}

class _SavedTokensDialogState extends State<_SavedTokensDialog> {
  final _localDbService = LocalDatabaseService();
  final _searchController = TextEditingController();
  List<ClinicTokenModel> _allTokens = [];
  List<ClinicTokenModel> _filteredTokens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    setState(() => _isLoading = true);
    final tokens = await _localDbService.fetchClinicTokens();
    if (mounted) {
      setState(() {
        _allTokens = tokens;
        _filteredTokens = tokens;
        _isLoading = false;
      });
    }
  }

  void _filterTokens(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredTokens = _allTokens;
      } else {
        _filteredTokens = _allTokens.where((t) {
          return t.patientName.toLowerCase().contains(q) ||
              t.doctorName.toLowerCase().contains(q) ||
              t.tokenCode.toLowerCase().contains(q) ||
              t.tokenNumber.toString().contains(q);
        }).toList();
      }
    });
  }

  void _previewToken(ClinicTokenModel token) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 500,
          height: 650,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Token Parachi #${token.tokenNumber} - ${token.patientName}'),
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            body: PdfPreview(
              build: (format) => PdfReceiptService.generateClinicTokenPdf(token),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 780,
        height: 650,
        child: Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved Token Parachiyan History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Permanent Local Database Records (محفوظ شدہ پرچیاں)', style: TextStyle(fontSize: 12)),
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
                  onChanged: _filterTokens,
                  decoration: InputDecoration(
                    hintText: 'Search by Patient Name, Doctor Name, or Token Code (Te17076)...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _filterTokens('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Total Collection Summary Card for Tokens
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number_rounded, color: Color(0xFF0F766E), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Total Saved Tokens: ${_filteredTokens.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Text(
                        'Total Collection: PKR ${NumberFormat('#,##0.00', 'en_US').format(_filteredTokens.fold(0.0, (sum, t) => sum + t.consultationFee))}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Saved Tokens List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredTokens.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('No saved token parachiyan found.', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredTokens.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final tok = _filteredTokens[index];
                                final dateStr = DateFormat('dd-MMM-yyyy hh:mm a').format(tok.createdAt);

                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: const Color(0xFF0F766E),
                                      child: Text(
                                        '#${tok.tokenNumber}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          tok.patientName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF0F766E)),
                                          ),
                                          child: Text(
                                            tok.tokenCode,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Doctor: ${tok.doctorName} (${tok.doctorSpecialization})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 2),
                                          Text('Date: $dateStr | Category: ${tok.patientType}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'PKR ${tok.consultationFee.toInt()}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF0F766E)),
                                          tooltip: 'Preview Parachi',
                                          onPressed: () => _previewToken(tok),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0F766E),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: const Icon(Icons.print_rounded, size: 16),
                                          label: const Text('Re-Print'),
                                          onPressed: () => PdfReceiptService.printClinicToken(tok),
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
