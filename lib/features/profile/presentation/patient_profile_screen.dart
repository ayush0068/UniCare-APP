import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/patient_profile_api.dart';

const _genderOptions = ['male', 'female', 'other'];
const _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  final _api = PatientProfileApi();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _editing = false;

  // Basic info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dob;
  String? _gender;
  String? _bloodGroup;
  String? _ucId;
  String? _email;

  // Emergency contact
  final _ecNameController = TextEditingController();
  final _ecPhoneController = TextEditingController();
  final _ecRelationshipController = TextEditingController();

  // Medical history
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _conditionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ecNameController.dispose();
    _ecPhoneController.dispose();
    _ecRelationshipController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getProfile();
      final ec = data['emergencyContact'] as Map<String, dynamic>?;
      final mh = data['medicalHistory'] as Map<String, dynamic>?;
      setState(() {
        _ucId = data['ucId'] as String?;
        _email = data['email'] as String?;
        _nameController.text = data['name'] as String? ?? '';
        _phoneController.text = data['phone'] as String? ?? '';
        _dob = data['dob'] != null ? DateTime.tryParse(data['dob'] as String) : null;
        _gender = data['gender'] as String?;
        _bloodGroup = data['bloodGroup'] as String?;
        _ecNameController.text = ec?['name'] as String? ?? '';
        _ecPhoneController.text = ec?['phone'] as String? ?? '';
        _ecRelationshipController.text = ec?['relationship'] as String? ?? '';
        _allergiesController.text = mh?['allergies'] as String? ?? '';
        _medicationsController.text = mh?['currentMedications'] as String? ?? '';
        _conditionsController.text = mh?['chronicConditions'] as String? ?? '';
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        dob: _dob,
        gender: _gender,
        bloodGroup: _bloodGroup,
        emergencyContact: (_ecNameController.text.trim().isNotEmpty ||
            _ecPhoneController.text.trim().isNotEmpty ||
            _ecRelationshipController.text.trim().isNotEmpty)
            ? {
          'name': _ecNameController.text.trim(),
          'phone': _ecPhoneController.text.trim(),
          'relationship': _ecRelationshipController.text.trim(),
        }
            : null,
        medicalHistory: {
          'allergies': _allergiesController.text.trim(),
          'currentMedications': _medicationsController.text.trim(),
          'chronicConditions': _conditionsController.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_loading && _error == null)
            IconButton(
              icon: Icon(_editing ? Icons.close_rounded : Icons.edit_outlined),
              onPressed: () => setState(() => _editing = !_editing),
            ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      )
          : SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  _ProfileHeader(name: _nameController.text, ucId: _ucId, email: _email),
                  const SizedBox(height: 22),
                  _SectionLabel('Basic Info'),
                  const SizedBox(height: 10),
                  _EditableField(
                    label: 'Full Name',
                    controller: _nameController,
                    editing: _editing,
                  ),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Phone',
                    controller: _phoneController,
                    editing: _editing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _DobField(
                    dob: _dob,
                    editing: _editing,
                    onPick: (date) => setState(() => _dob = date),
                  ),
                  const SizedBox(height: 12),
                  _DropdownField(
                    label: 'Gender',
                    value: _gender,
                    options: _genderOptions,
                    editing: _editing,
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 12),
                  _DropdownField(
                    label: 'Blood Group',
                    value: _bloodGroup,
                    options: _bloodGroupOptions,
                    editing: _editing,
                    onChanged: (v) => setState(() => _bloodGroup = v),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('Emergency Contact'),
                  const SizedBox(height: 10),
                  _EditableField(label: 'Name', controller: _ecNameController, editing: _editing),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Phone',
                    controller: _ecPhoneController,
                    editing: _editing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Relationship',
                    controller: _ecRelationshipController,
                    editing: _editing,
                    hint: 'e.g. Spouse, Parent',
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('Medical History'),
                  const SizedBox(height: 10),
                  _EditableField(
                    label: 'Allergies',
                    controller: _allergiesController,
                    editing: _editing,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Current Medications',
                    controller: _medicationsController,
                    editing: _editing,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Chronic Conditions',
                    controller: _conditionsController,
                    editing: _editing,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) context.go('/role-selection');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      child: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
            ),
            if (_editing)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Save Changes'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? ucId;
  final String? email;
  const _ProfileHeader({required this.name, this.ucId, this.email});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'P',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.isEmpty ? 'Patient' : name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              if (email != null) ...[
                const SizedBox(height: 2),
                Text(email!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
              if (ucId != null) ...[
                const SizedBox(height: 2),
                Text(ucId!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool editing;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;

  const _EditableField({
    required this.label,
    required this.controller,
    required this.editing,
    this.keyboardType,
    this.maxLines = 1,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return _ReadOnlyRow(label: label, value: controller.text.isEmpty ? '—' : controller.text);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _DobField extends StatelessWidget {
  final DateTime? dob;
  final bool editing;
  final ValueChanged<DateTime> onPick;
  const _DobField({required this.dob, required this.editing, required this.onPick});

  String _format(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return _ReadOnlyRow(label: 'Date of Birth', value: dob != null ? _format(dob!) : '—');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date of Birth', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dob ?? DateTime(2000, 1, 1),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
            );
            if (picked != null) onPick(picked);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Text(dob != null ? _format(dob!) : 'Select date', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final bool editing;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.editing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return _ReadOnlyRow(label: label, value: value ?? '—');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Select'),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}