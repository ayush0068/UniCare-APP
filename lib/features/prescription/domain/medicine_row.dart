/// Matches website's MedicineRow interface + parsePrescription()/handleSave()
/// in components/doctor/PrescriptionModal.tsx and PrescriptionViewModal.tsx.
///
/// The backend only has a single `prescription: String` field — the
/// website encodes structured medicine rows into that string as:
///   "1. Name | Dosage | Frequency | Duration | Instructions\n2. ..."
/// and decodes it the same way for display. We mirror that exact format
/// so prescriptions written from the app are readable on the website and
/// vice versa.
class MedicineRow {
  String name;
  String dosage;
  String frequency;
  String duration;
  String instructions;

  MedicineRow({
    this.name = '',
    this.dosage = '',
    this.frequency = '',
    this.duration = '',
    this.instructions = '',
  });

  bool get isFilled => name.trim().isNotEmpty;
}

/// Matches website's FREQUENCY_OPTIONS exactly.
const frequencyOptions = [
  'Once daily', 'Twice daily', 'Thrice daily',
  'Every 4 hours', 'Every 6 hours', 'Every 8 hours',
  'At bedtime', 'As needed (SOS)', 'Weekly',
];

/// Matches website's INSTRUCTION_OPTIONS exactly.
const instructionOptions = [
  'After breakfast', 'Before breakfast', 'After lunch',
  'Before lunch', 'After dinner', 'Before dinner',
  'With food', 'Empty stomach', 'With water', 'With milk',
];

/// Matches website's handleSave() serialization exactly.
String buildPrescriptionString(List<MedicineRow> rows) {
  final filled = rows.where((r) => r.isFilled).toList();
  return filled
      .asMap()
      .entries
      .map((e) =>
  '${e.key + 1}. ${e.value.name} | ${e.value.dosage} | ${e.value.frequency} | ${e.value.duration} | ${e.value.instructions}')
      .join('\n');
}

class ParsedMedicine {
  final String index;
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  const ParsedMedicine({
    required this.index,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
  });
}

/// Matches website's parsePrescription() exactly.
List<ParsedMedicine> parsePrescription(String text) {
  if (text.trim().isEmpty) return [];
  return text.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
    final indexMatch = RegExp(r'^(\d+)').firstMatch(line);
    final withoutIndex = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    final parts = withoutIndex.split('|').map((p) => p.trim()).toList();
    return ParsedMedicine(
      index: indexMatch?.group(1) ?? '1',
      name: parts.isNotEmpty ? parts[0] : '',
      dosage: parts.length > 1 ? parts[1] : '',
      frequency: parts.length > 2 ? parts[2] : '',
      duration: parts.length > 3 ? parts[3] : '',
      instructions: parts.length > 4 ? parts[4] : '',
    );
  }).toList();
}