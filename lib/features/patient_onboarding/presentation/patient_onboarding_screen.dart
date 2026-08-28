import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/patient_onboarding_api.dart';

const _genderOptions = ['male', 'female', 'other'];
const _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// Matches the website's components/patient/PatientOnboardingForm.tsx —
/// same 3 steps, same required fields, same validity rules:
///   Step 1 (Basic Details): phone, dob, gender required; bloodGroup optional
///   Step 2 (Emergency Contact): name, phone, relationship all required
///   Step 3 (Medical History): allergies, currentMedications, chronicConditions all required
class PatientOnboardingScreen extends StatefulWidget {
  const PatientOnboardingScreen({super.key});

  @override
  State<PatientOnboardingScreen> createState() => _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends State<PatientOnboardingScreen> {
  final _api = PatientOnboardingApi();
  int _step = 1;
  bool _submitting = false;

  // Step 1
  final _phoneController = TextEditingController();
  DateTime? _dob;
  String? _gender;
  String? _bloodGroup;

  // Step 2
  final _ecNameController = TextEditingController();
  final _ecPhoneController = TextEditingController();
  final _ecRelationshipController = TextEditingController();

  // Step 3
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _conditionsController = TextEditingController();

  bool get _step1Valid => _phoneController.text.trim().isNotEmpty && _dob != null && _gender != null;
  bool get _step2Valid =>
      _ecNameController.text.trim().isNotEmpty &&
          _ecPhoneController.text.trim().isNotEmpty &&
          _ecRelationshipController.text.trim().isNotEmpty;
  bool get _step3Valid =>
      _allergiesController.text.trim().isNotEmpty &&
          _medicationsController.text.trim().isNotEmpty &&
          _conditionsController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _phoneController.dispose();
    _ecNameController.dispose();
    _ecPhoneController.dispose();
    _ecRelationshipController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _api.updateProfile(
        phone: _phoneController.text.trim(),
        dob: _dob!,
        gender: _gender!,
        bloodGroup: _bloodGroup,
        emergencyContact: {
          'name': _ecNameController.text.trim(),
          'phone': _ecPhoneController.text.trim(),
          'relationship': _ecRelationshipController.text.trim(),
        },
        medicalHistory: {
          'allergies': _allergiesController.text.trim(),
          'currentMedications': _medicationsController.text.trim(),
          'chronicConditions': _conditionsController.text.trim(),
        },
      );
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNextDisabled =
        (_step == 1 && !_step1Valid) || (_step == 2 && !_step2Valid);

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
                children: List.generate(3, (i) {
                  final stepNum = i + 1;
                  final isDone = _step > stepNum;
                  final isActive = _step == stepNum;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
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
                            ['Basic Details', 'Emergency Contact', 'Medical History'][i],
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
                  if (_step > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step -= 1),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitting || (isNextDisabled && _step < 3) || (_step == 3 && !_step3Valid)
                          ? null
                          : () {
                        if (_step < 3) {
                          setState(() => _step += 1);
                        } else {
                          _submit();
                        }
                      },
                      child: _submitting
                          ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : Text(_step < 3 ? 'Next' : 'Complete Profile'),
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
        const _FieldLabel('Phone Number'),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '10-digit mobile number'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Date of Birth'),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000, 1, 1),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _dob = picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  _dob != null ? _formatDate(_dob!) : 'Select date of birth',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Gender'),
        Wrap(
          spacing: 8,
          children: _genderOptions.map((g) {
            final selected = _gender == g;
            return ChoiceChip(
              label: Text(g[0].toUpperCase() + g.substring(1), style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => setState(() => _gender = g),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary),
              backgroundColor: AppColors.surface,
              side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Blood Group (optional)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bloodGroupOptions.map((b) {
            final selected = _bloodGroup == b;
            return ChoiceChip(
              label: Text(b, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => setState(() => _bloodGroup = selected ? null : b),
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

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Contact Name'),
        TextField(
          controller: _ecNameController,
          decoration: const InputDecoration(hintText: 'Full name'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Contact Phone'),
        TextField(
          controller: _ecPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '10-digit mobile number'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Relationship'),
        TextField(
          controller: _ecRelationshipController,
          decoration: const InputDecoration(hintText: 'e.g. Spouse, Parent, Sibling'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Allergies'),
        TextField(
          controller: _allergiesController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'e.g. Penicillin, Peanuts — or "None"'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Current Medications'),
        TextField(
          controller: _medicationsController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'e.g. Metformin 500mg — or "None"'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Chronic Conditions'),
        TextField(
          controller: _conditionsController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'e.g. Diabetes, Hypertension — or "None"'),
          onChanged: (_) => setState(() {}),
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