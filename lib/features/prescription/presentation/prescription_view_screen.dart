import 'package:flutter/material.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../data/prescription_api.dart';
import '../domain/medicine_row.dart';

// Exact color palette from the website's PrescriptionViewModal.tsx so the
// document looks identical whether viewed on the app or the web.
const _navy = Color(0xFF1A3A5C);
const _sky = Color(0xFF0EA5E9);
const _skyLight = Color(0xFF93C5FD);
const _skyBg = Color(0xFFF0F9FF);
const _amber = Color(0xFFFBBF24);
const _amberBg = Color(0xFFFFFBEB);
const _amberText = Color(0xFF78350F);
const _slate50 = Color(0xFFF8FAFC);
const _slate200 = Color(0xFFE2E8F0);
const _slate500 = Color(0xFF64748B);
const _slate900 = Color(0xFF0F172A);

/// Renders the full formal prescription — same document structure as the
/// website's PrescriptionViewModal.tsx (header, Rx badge, meta bar,
/// doctor/patient info, symptoms, medicine table, advice, signatures,
/// footer). Fetches the full appointment detail itself so it always has
/// complete doctor/patient info to print, regardless of where it was
/// opened from.
class PrescriptionViewScreen extends StatefulWidget {
  final String appointmentId;
  const PrescriptionViewScreen({super.key, required this.appointmentId});

  @override
  State<PrescriptionViewScreen> createState() => _PrescriptionViewScreenState();
}

class _PrescriptionViewScreenState extends State<PrescriptionViewScreen> {
  final _api = PrescriptionApi();
  Map<String, dynamic>? _appointment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getAppointmentDetail(widget.appointmentId);
      setState(() {
        _appointment = data;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: const Text('Prescription'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _RxDocument(appointment: _appointment!),
      ),
    );
  }
}

class _RxDocument extends StatelessWidget {
  final Map<String, dynamic> appointment;
  const _RxDocument({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final doctor = appointment['doctorId'] as Map<String, dynamic>? ?? {};
    final patient = appointment['patientId'] as Map<String, dynamic>? ?? {};
    final hospitalInfo = doctor['hospitalInfo'] as Map<String, dynamic>?;
    final medicines = parsePrescription(appointment['prescription'] as String? ?? '');
    final rxNumber = 'RX-${(appointment['_id'] as String? ?? '00000000').substring((appointment['_id'] as String? ?? '00000000').length >= 8 ? (appointment['_id'] as String).length - 8 : 0).toUpperCase()}';
    final slotStart = DateTime.tryParse(appointment['slotStartIso'] as String? ?? '');
    final notes = appointment['notes'] as String?;
    final symptoms = appointment['symptoms'] as String?;

    return Container(
      constraints: const BoxConstraints(maxWidth: 760),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(doctor: doctor),
          _MetaBar(rxNumber: rxNumber, slotStart: slotStart, consultationType: appointment['consultationType'] as String?),
          _InfoBoxes(doctor: doctor, patient: patient, hospitalInfo: hospitalInfo),
          if (symptoms != null && symptoms.trim().isNotEmpty) _SymptomsBox(symptoms: symptoms),
          _RxTitle(),
          _MedicineTable(medicines: medicines, rawPrescription: appointment['prescription'] as String?),
          if (notes != null && notes.trim().isNotEmpty) _NotesBox(notes: notes),
          _SignatureBlock(doctor: doctor),
          _Footer(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _Header({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _navy,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UNICARE',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3, fontFamily: 'serif'),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'DIGITAL HEALTH PLATFORM',
                    style: TextStyle(color: _skyLight, fontSize: 9, letterSpacing: 2.5),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'support@unicare.health  |  www.unicare.health',
                    style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 9),
                  ),
                  const Text(
                    '24/7 Helpline: 1800-UNI-CARE',
                    style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 110,
            color: _sky,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Rx', style: TextStyle(color: Colors.white, fontSize: 42, fontFamily: 'serif', fontWeight: FontWeight.bold, height: 1)),
                SizedBox(height: 4),
                Text('PRESCRIPTION', style: TextStyle(color: Color(0xFFE0F2FE), fontSize: 8, letterSpacing: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBar extends StatelessWidget {
  final String rxNumber;
  final DateTime? slotStart;
  final String? consultationType;
  const _MetaBar({required this.rxNumber, required this.slotStart, required this.consultationType});

  @override
  Widget build(BuildContext context) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = slotStart != null ? '${slotStart!.day} ${months[slotStart!.month - 1]} ${slotStart!.year}' : 'N/A';
    final timeStr = slotStart != null
        ? '${slotStart!.hour % 12 == 0 ? 12 : slotStart!.hour % 12}:${slotStart!.minute.toString().padLeft(2, '0')} ${slotStart!.hour < 12 ? 'AM' : 'PM'} IST'
        : 'N/A';

    return Container(
      color: _skyBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Wrap(
        spacing: 20,
        runSpacing: 6,
        children: [
          _metaItem('Prescription No:', rxNumber),
          _metaItem('Date:', dateStr),
          _metaItem('Type:', consultationType ?? 'N/A'),
          _metaItem('Time:', timeStr),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, fontFamily: 'sans-serif'),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(color: _slate500)),
          TextSpan(text: value, style: const TextStyle(color: _slate900, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InfoBoxes extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final Map<String, dynamic> patient;
  final Map<String, dynamic>? hospitalInfo;
  const _InfoBoxes({required this.doctor, required this.patient, required this.hospitalInfo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460;
          final doctorBox = _InfoBox(
            icon: Icons.medical_services_outlined,
            title: 'DOCTOR INFORMATION',
            rows: [
              ('Name', 'Dr. ${doctor['name'] ?? 'N/A'}'),
              ('Specialization', '${doctor['specialization'] ?? 'N/A'}'),
              ('Qualification', '${doctor['qualification'] ?? 'MBBS, MD'}'),
              ('Hospital', '${hospitalInfo?['name'] ?? 'N/A'}'),
              ('City', '${hospitalInfo?['city'] ?? 'N/A'}'),
              ('Contact', '${doctor['phone'] ?? 'N/A'}'),
            ],
          );
          final patientBox = _InfoBox(
            icon: Icons.person_outline_rounded,
            title: 'PATIENT INFORMATION',
            rows: [
              ('Name', '${patient['name'] ?? 'N/A'}'),
              ('Age', '${patient['age'] ?? 'N/A'} Yrs'),
              ('Date of Birth', patient['dob'] != null ? _formatDob(patient['dob'] as String) : 'N/A'),
              ('Phone', '${patient['phone'] ?? 'N/A'}'),
              ('Email', '${patient['email'] ?? 'N/A'}'),
            ],
          );

          if (isNarrow) {
            return Column(children: [doctorBox, const SizedBox(height: 12), patientBox]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: doctorBox),
              const SizedBox(width: 12),
              Expanded(child: patientBox),
            ],
          );
        },
      ),
    );
  }

  String _formatDob(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return 'N/A';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<(String, String)> rows;
  const _InfoBox({required this.icon, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: _slate200), borderRadius: BorderRadius.circular(6)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: _navy,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 13, color: _skyLight),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 9.5, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: _slate50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows
                  .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 82, child: Text(r.$1, style: const TextStyle(fontSize: 11, color: _slate500))),
                    Expanded(child: Text(r.$2, style: const TextStyle(fontSize: 11.5, color: _slate900, fontWeight: FontWeight.w600))),
                  ],
                ),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomsBox extends StatelessWidget {
  final String symptoms;
  const _SymptomsBox({required this.symptoms});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _skyBg,
        borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
        border: const Border(left: BorderSide(color: _sky, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHIEF COMPLAINTS / SYMPTOMS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF0369A1), letterSpacing: 1)),
          const SizedBox(height: 5),
          Text(symptoms, style: const TextStyle(fontSize: 12, color: Color(0xFF0C4A6E), height: 1.5)),
        ],
      ),
    );
  }
}

class _RxTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          const Text('Rx', style: TextStyle(fontFamily: 'serif', fontSize: 24, color: _sky, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _sky, width: 2))),
              child: const Text('MEDICATIONS PRESCRIBED', style: TextStyle(fontSize: 10.5, color: _navy, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineTable extends StatelessWidget {
  final List<ParsedMedicine> medicines;
  final String? rawPrescription;
  const _MedicineTable({required this.medicines, required this.rawPrescription});

  @override
  Widget build(BuildContext context) {
    const headers = ['#', 'Medicine', 'Dosage', 'Frequency', 'Duration', 'Instructions'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: _slate200, width: 1),
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FixedColumnWidth(120),
            2: FixedColumnWidth(90),
            3: FixedColumnWidth(110),
            4: FixedColumnWidth(90),
            5: FixedColumnWidth(140),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: _navy),
              children: headers
                  .map((h) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                child: Text(h, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ))
                  .toList(),
            ),
            if (medicines.isNotEmpty)
              ...medicines.asMap().entries.map((entry) {
                final i = entry.key;
                final med = entry.value;
                final bg = i % 2 == 0 ? Colors.white : _slate50;
                return TableRow(
                  decoration: BoxDecoration(color: bg),
                  children: [
                    _cell(med.index, color: const Color(0xFF94A3B8), bold: true, center: true),
                    _cell(med.name, bold: true),
                    _cell(med.dosage),
                    _cell(med.frequency),
                    _cell(med.duration),
                    _cell(med.instructions),
                  ],
                );
              })
            else
              TableRow(
                children: List.generate(
                  6,
                      (i) => i == 0
                      ? const SizedBox()
                      : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: i == 3
                        ? Text(
                      rawPrescription?.isNotEmpty == true ? rawPrescription! : 'No prescription provided.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                    )
                        : const SizedBox(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, {Color color = _slate900, bool bold = false, bool center = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: TextStyle(fontSize: 11, color: color, fontWeight: bold ? FontWeight.w700 : FontWeight.normal),
      ),
    );
  }
}

class _NotesBox extends StatelessWidget {
  final String notes;
  const _NotesBox({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const BoxDecoration(color: _amber, borderRadius: BorderRadius.vertical(top: Radius.circular(6))),
            child: const Text("DOCTOR'S ADVICE & NOTES", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF92400E), letterSpacing: 1)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _amberBg,
              border: Border.all(color: _amber),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
            ),
            child: Text(notes, style: const TextStyle(fontSize: 12, color: _amberText, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _SignatureBlock extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _SignatureBlock({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(height: 1, color: _navy, margin: const EdgeInsets.only(bottom: 8)),
                const SizedBox(height: 28),
                const Text('Patient / Guardian Signature', style: TextStyle(fontSize: 10.5, color: _slate500)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                Container(height: 1, color: _navy, margin: const EdgeInsets.only(bottom: 8)),
                const SizedBox(height: 28),
                Text('Dr. ${doctor['name'] ?? ''}', style: const TextStyle(fontSize: 11, color: _slate900, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${doctor['specialization'] ?? ''}', style: const TextStyle(fontSize: 9.5, color: _slate500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _navy,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: const Text(
        'Digitally generated prescription via UniCare platform. Valid for 30 days from date of issue.\nFor queries: support@unicare.health',
        style: TextStyle(color: _skyLight, fontSize: 9, height: 1.6),
      ),
    );
  }
}