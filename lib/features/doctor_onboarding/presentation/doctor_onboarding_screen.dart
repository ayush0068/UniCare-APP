import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/doctor_onboarding_api.dart';
import 'widgets/document_upload_card.dart';

/// Matches website's specializations list (lib/constant.ts) exactly.
const _specializations = [
  'Cardiologist', 'Dermatologist', 'Orthopedic', 'Pediatrician', 'Neurologist',
  'Gynecologist', 'General Physician', 'ENT Specialist', 'Psychiatrist', 'Ophthalmologist',
];

/// Matches website's healthcareCategoriesList exactly.
const _categories = [
  'Primary Care', 'Manage Your Condition', 'Mental & Behavioral Health', 'Sexual Health',
  "Children's Health", 'Senior Health', "Women's Health", "Men's Health", 'Wellness',
];

const _weekdays = [
  {'label': 'Sun', 'value': 0}, {'label': 'Mon', 'value': 1}, {'label': 'Tue', 'value': 2},
  {'label': 'Wed', 'value': 3}, {'label': 'Thu', 'value': 4}, {'label': 'Fri', 'value': 5},
  {'label': 'Sat', 'value': 6},
];

class DoctorOnboardingScreen extends StatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  State<DoctorOnboardingScreen> createState() => _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState extends State<DoctorOnboardingScreen> {
  final _api = DoctorOnboardingApi();
  int _step = 1;
  bool _submitting = false;
  bool _profileSaved = false; // true once step 1-3 data is saved to backend
  List<UploadedDocument> _uploadedDocuments = [];
  bool _loadingDocuments = false;
  String? _documentsError;

  // Step 1
  String? _specialization;
  final Set<String> _selectedCategories = {};
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feesController = TextEditingController();
  final _aboutController = TextEditingController();

  // Step 2
  final _hospitalNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  // Step 3
  DateTime? _availabilityStart;
  DateTime? _availabilityEnd;
  final Set<int> _excludedWeekdays = {};
  List<Map<String, String>> _timeRanges = [
    {'start': '09:00', 'end': '12:00'},
    {'start': '14:00', 'end': '17:00'},
  ];
  int _slotDuration = 30;

  bool get _step1Valid =>
      _specialization != null && _selectedCategories.isNotEmpty && _qualificationController.text.trim().isNotEmpty;
  bool get _step2Valid =>
      _hospitalNameController.text.trim().isNotEmpty &&
          _addressController.text.trim().isNotEmpty &&
          _cityController.text.trim().isNotEmpty;
  bool get _step3Valid => _availabilityStart != null && _availabilityEnd != null;

  @override
  void dispose() {
    _qualificationController.dispose();
    _experienceController.dispose();
    _feesController.dispose();
    _aboutController.dispose();
    _hospitalNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    setState(() => _submitting = true);
    try {
      await _api.updateProfile(
        specialization: _specialization!,
        categories: _selectedCategories.toList(),
        qualification: _qualificationController.text.trim(),
        experience: _experienceController.text.trim(),
        about: _aboutController.text.trim(),
        fees: _feesController.text.trim(),
        hospitalInfo: {
          'name': _hospitalNameController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
        },
        availabilityStartDate: _availabilityStart!,
        availabilityEndDate: _availabilityEnd!,
        excludedWeekdays: _excludedWeekdays.toList(),
        dailyTimeRanges: _timeRanges,
        slotDurationMinutes: _slotDuration,
      );
      if (!mounted) return;
      setState(() {
        _profileSaved = true;
        _step = 4;
      });
      _loadDocuments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _loadingDocuments = true);
    try {
      final data = await _api.getVerificationDocuments();
      final docs = (data['documents'] as List)
          .map((d) => UploadedDocument(
        id: d['_id'] as String,
        type: d['type'] as String,
        uploadedAt: DateTime.tryParse(d['uploadedAt'] as String? ?? '') ?? DateTime.now(),
      ))
          .toList();
      if (!mounted) return;
      setState(() {
        _uploadedDocuments = docs;
        _documentsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _documentsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingDocuments = false);
    }
  }

  Future<void> _uploadDocument(String type, dynamic bytes, String fileName, String mimeType) async {
    await _api.uploadVerificationDocument(
      documentType: type,
      fileBytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
    await _loadDocuments();
  }

  Future<void> _deleteDocument(String documentId) async {
    await _api.deleteVerificationDocument(documentId);
    await _loadDocuments();
  }

  void _finishOnboarding() {
    if (_uploadedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one verification document to continue')),
      );
      return;
    }
    context.go('/doctor-pending-verification');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: List.generate(4, (i) {
                  final stepNum = i + 1;
                  final isDone = _step > stepNum;
                  final isActive = _step == stepNum;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDone || isActive ? AppColors.primary : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ['Professional', 'Hospital', 'Availability', 'Documents'][i],
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isActive ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  if (_step == 1) _buildStep1(),
                  if (_step == 2) _buildStep2(),
                  if (_step == 3) _buildStep3(),
                  if (_step == 4) _buildStep4(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (_step > 1 && _step < 4)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step -= 1),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 1 && _step < 4) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : (_step == 1 && !_step1Valid)
                          ? null
                          : (_step == 2 && !_step2Valid)
                          ? null
                          : (_step == 3 && !_step3Valid)
                          ? null
                          : () {
                        if (_step < 3) {
                          setState(() => _step += 1);
                        } else if (_step == 3) {
                          _submitProfile();
                        } else {
                          _finishOnboarding();
                        }
                      },
                      child: _submitting
                          ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : Text(
                        _step < 3
                            ? 'Next'
                            : _step == 3
                            ? 'Save & Continue to Documents'
                            : 'Submit for Review',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Specialization'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _specializations.map((s) {
            final selected = _specialization == s;
            return ChoiceChip(
              label: Text(s, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => setState(() => _specialization = s),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary),
              backgroundColor: AppColors.surface,
              side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Categories (select all that apply)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((c) {
            final selected = _selectedCategories.contains(c);
            return FilterChip(
              label: Text(c, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (v) => setState(() => v ? _selectedCategories.add(c) : _selectedCategories.remove(c)),
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primaryDark,
              backgroundColor: AppColors.surface,
              side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Qualification'),
        TextField(
          controller: _qualificationController,
          decoration: const InputDecoration(hintText: 'MBBS, MD Cardiology'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Experience (Years)'),
                  TextField(
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '5'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Consultation Fee (₹)'),
                  TextField(
                    controller: _feesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '500'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _FieldLabel('About (optional)'),
        TextField(
          controller: _aboutController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Tell patients about your practice...'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Hospital / Clinic Name'),
        TextField(
          controller: _hospitalNameController,
          decoration: const InputDecoration(hintText: 'e.g., Apollo Hospital'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Full Address'),
        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Street address, landmark...'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('City'),
        TextField(
          controller: _cityController,
          decoration: const InputDecoration(hintText: 'e.g., Prayagraj'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Available From – To'),
        Row(
          children: [
            Expanded(
              child: _DatePickField(
                label: _availabilityStart == null
                    ? 'Start date'
                    : _formatDate(_availabilityStart!),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setState(() => _availabilityStart = picked);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DatePickField(
                label: _availabilityEnd == null ? 'End date' : _formatDate(_availabilityEnd!),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _availabilityStart ?? DateTime.now(),
                    firstDate: _availabilityStart ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 1095)),
                  );
                  if (picked != null) setState(() => _availabilityEnd = picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Weekly Off Days'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekdays.map((d) {
            final value = d['value'] as int;
            final label = d['label'] as String;
            final selected = _excludedWeekdays.contains(value);
            return FilterChip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (v) => setState(() => v ? _excludedWeekdays.add(value) : _excludedWeekdays.remove(value)),
              selectedColor: AppColors.tintRed,
              backgroundColor: AppColors.surface,
              side: BorderSide(color: selected ? AppColors.danger : AppColors.border),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Daily Working Hours'),
        ..._timeRanges.asMap().entries.map((entry) {
          final i = entry.key;
          final range = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: range['start'],
                    decoration: const InputDecoration(labelText: 'Start (HH:mm)'),
                    onChanged: (v) => _timeRanges[i]['start'] = v,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: range['end'],
                    decoration: const InputDecoration(labelText: 'End (HH:mm)'),
                    onChanged: (v) => _timeRanges[i]['end'] = v,
                  ),
                ),
                if (_timeRanges.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.danger, size: 20),
                    onPressed: () => setState(() => _timeRanges.removeAt(i)),
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _timeRanges.add({'start': '18:00', 'end': '20:00'})),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add another time range'),
        ),
        const SizedBox(height: 8),
        const _FieldLabel('Slot Duration (minutes)'),
        Wrap(
          spacing: 8,
          children: [15, 20, 30, 45, 60].map((d) {
            final selected = _slotDuration == d;
            return ChoiceChip(
              label: Text('$d min', style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => setState(() => _slotDuration = d),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary),
              backgroundColor: AppColors.surface,
              side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.tintOrange,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload at least one document to prove you\'re a licensed doctor. Our admin team reviews these before your account goes live.',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_loadingDocuments)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_documentsError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_documentsError!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
          )
        else
          DocumentUploadCard(
            uploadedDocuments: _uploadedDocuments,
            onUpload: _uploadDocument,
            onDelete: _deleteDocument,
          ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      ),
    );
  }
}

class _DatePickField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DatePickField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}