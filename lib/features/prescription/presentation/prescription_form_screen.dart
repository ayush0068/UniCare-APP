import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/prescription_api.dart';
import '../domain/medicine_row.dart';

/// Matches website's PrescriptionModal.tsx: dynamic medicine rows
/// (name/dosage/frequency/duration/instructions), a notes field for
/// diet/follow-up advice, saved via PUT /appointment/end/:id which also
/// marks the appointment Completed. Reached automatically right after a
/// doctor ends a video/voice call (see consultation_screen.dart).
class PrescriptionFormScreen extends StatefulWidget {
  final String appointmentId;
  final String patientName;
  const PrescriptionFormScreen({super.key, required this.appointmentId, required this.patientName});

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _api = PrescriptionApi();
  final List<MedicineRow> _medicines = [MedicineRow()];
  final _notesController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final filled = _medicines.where((m) => m.isFilled).toList();
    if (filled.isEmpty) {
      setState(() => _error = 'At least one medicine is required.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await _api.savePrescription(
        widget.appointmentId,
        prescription: buildPrescriptionString(_medicines),
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      context.go('/doctor/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription saved — appointment marked completed')),
      );
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Write Prescription'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryDark, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Consultation with ${widget.patientName} has ended. Add a prescription to mark it complete.',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Medicines', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      TextButton.icon(
                        onPressed: () => setState(() => _medicines.add(MedicineRow())),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Medicine'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._medicines.asMap().entries.map((entry) => _MedicineRowCard(
                    index: entry.key,
                    row: entry.value,
                    canRemove: _medicines.length > 1,
                    onRemove: () => setState(() => _medicines.removeAt(entry.key)),
                    onChanged: () => setState(() {}),
                  )),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.tintRed, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.danger))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text('Advice & Notes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Diet advice, follow-up instructions, restrictions, lifestyle changes...',
                    ),
                  ),
                ],
              ),
            ),
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
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_saving ? 'Saving...' : 'Save & Complete Consultation'),
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

class _MedicineRowCard extends StatelessWidget {
  final int index;
  final MedicineRow row;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _MedicineRowCard({
    required this.index,
    required this.row,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Medicine ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textSecondary)),
              if (canRemove)
                InkWell(
                  onTap: onRemove,
                  child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: row.name,
            decoration: const InputDecoration(labelText: 'Medicine Name'),
            onChanged: (v) {
              row.name = v;
              onChanged();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: row.dosage,
                  decoration: const InputDecoration(labelText: 'Dosage', hintText: 'e.g. 500mg'),
                  onChanged: (v) => row.dosage = v,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: row.duration,
                  decoration: const InputDecoration(labelText: 'Duration', hintText: 'e.g. 5 days'),
                  onChanged: (v) => row.duration = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: row.frequency.isEmpty ? null : row.frequency,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Frequency'),
            items: frequencyOptions.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) {
              row.frequency = v ?? '';
              onChanged();
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: row.instructions.isEmpty ? null : row.instructions,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Instructions'),
            items: instructionOptions.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) {
              row.instructions = v ?? '';
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}