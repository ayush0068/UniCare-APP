import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../doctors/domain/doctor_providers.dart';
import '../domain/booking_provider.dart';
import '../domain/slot_generator.dart';
import 'widgets/date_picker_strip.dart';
import 'widgets/slot_grid.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String doctorId;
  const BookingScreen({super.key, required this.doctorId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late DateTime _selectedDate;
  TimeSlot? _selectedSlot;
  String _consultationType = 'Video Consultation';
  final _symptomsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _symptomsController.addListener(() => setState(() {}));
  }

  String get _dateKey =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorDetailProvider(widget.doctorId));
    final bookingState = ref.watch(bookingProvider);

    ref.listen(bookingProvider, (previous, next) {
      if (next.status == BookingStatus.success) {
        context.go('/booking-success', extra: next.bookedAppointment);
      }
      if (next.status == BookingStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Book Appointment')),
      body: doctorAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (doctor) {
          final bookedSlotsAsync = ref.watch(
            bookedSlotsProvider((doctorId: widget.doctorId, date: _dateKey)),
          );
          final platformFees = (doctor.fees * 0.1).ceil();
          final totalAmount = doctor.fees + platformFees;

          return Column(
            children: [
              _DoctorStrip(name: doctor.name, specialization: doctor.specialization),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    const _StepHeader(number: '1', title: 'Select Date'),
                    const SizedBox(height: 10),
                    DatePickerStrip(
                      doctor: doctor,
                      selectedDate: _selectedDate,
                      onDateSelected: (date) => setState(() {
                        _selectedDate = date;
                        _selectedSlot = null;
                      }),
                    ),
                    const SizedBox(height: 22),
                    const _StepHeader(number: '2', title: 'Select Time Slot'),
                    bookedSlotsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: LoadingIndicator(),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('Could not load slots: $e',
                            style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                      ),
                      data: (bookedIso) {
                        final slots = generateDaySlots(
                          date: _selectedDate,
                          doctor: doctor,
                          bookedIsoSlots: bookedIso,
                          now: DateTime.now(),
                        );
                        // Selection may have become stale (e.g. someone
                        // else booked it while this screen was open) —
                        // drop it if it's no longer selectable.
                        if (_selectedSlot != null &&
                            !slots.any((s) => s.start == _selectedSlot!.start && s.isSelectable)) {
                          _selectedSlot = null;
                        }
                        return SlotGrid(
                          slots: slots,
                          selectedSlot: _selectedSlot,
                          onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    const _StepHeader(number: '3', title: 'Consultation Type'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeOption(
                            icon: Icons.videocam_rounded,
                            label: 'Video Call',
                            selected: _consultationType == 'Video Consultation',
                            onTap: () => setState(() => _consultationType = 'Video Consultation'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeOption(
                            icon: Icons.call_rounded,
                            label: 'Voice Call',
                            selected: _consultationType == 'Voice Call',
                            onTap: () => setState(() => _consultationType = 'Voice Call'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _StepHeader(number: '4', title: 'Describe Symptoms'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _symptomsController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'E.g. fever since 2 days, mild headache...',
                        counterText: '',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_symptomsController.text.trim().length}/500 · min 10 characters',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _symptomsController.text.trim().length >= 10
                              ? AppColors.textMuted
                              : AppColors.danger,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _PriceSummaryCard(
                      consultationFee: doctor.fees,
                      platformFee: platformFees,
                      total: totalAmount,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              _BottomBar(
                selectedSlot: _selectedSlot,
                totalAmount: totalAmount,
                isSubmitting: bookingState.status == BookingStatus.submitting,
                onConfirm: () {
                  if (_selectedSlot == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a time slot')),
                    );
                    return;
                  }
                  if (_symptomsController.text.trim().length < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please describe symptoms (min 10 characters)')),
                    );
                    return;
                  }
                  ref.read(bookingProvider.notifier).submit(
                    doctorId: doctor.id,
                    slotStart: _selectedSlot!.start,
                    slotEnd: _selectedSlot!.end,
                    consultationType: _consultationType,
                    symptoms: _symptomsController.text.trim(),
                    consultationFees: doctor.fees,
                    platformFees: platformFees,
                    totalAmount: totalAmount,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DoctorStrip extends StatelessWidget {
  final String name;
  final String specialization;
  const _DoctorStrip({required this.name, required this.specialization});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              name.isNotEmpty ? name[0] : 'D',
              style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text(specialization, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String number;
  final String title;
  const _StepHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.4 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primaryDark : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceSummaryCard extends StatelessWidget {
  final num consultationFee;
  final num platformFee;
  final num total;
  const _PriceSummaryCard({
    required this.consultationFee,
    required this.platformFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _row('Consultation fee', '₹${consultationFee.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _row('Platform fee', '₹$platformFee'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
          _row('Total', '₹$total', bold: true),
          const SizedBox(height: 8),
          const Text(
            'Final amount may differ based on your Parchi discount or guest surcharge.',
            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: bold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final TimeSlot? selectedSlot;
  final num totalAmount;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  const _BottomBar({
    required this.selectedSlot,
    required this.totalAmount,
    required this.isSubmitting,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (selectedSlot != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selected slot', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                    Text(
                      _dateTimeLabel(selectedSlot!.start),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              const Expanded(
                child: Text(
                  'Select a time slot to continue',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onConfirm,
                child: isSubmitting
                    ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : Text('Confirm · ₹$totalAmount'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateTimeLabel(DateTime time) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.day} ${months[time.month - 1]}, $hour:$minute $period';
  }
}