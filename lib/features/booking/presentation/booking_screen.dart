import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../doctors/domain/doctor_providers.dart';
import '../domain/booking_provider.dart';

/// NOTE: the backend doesn't expose a "generate available slots" endpoint —
/// only booked-slots (to grey out) and the doctor's dailyTimeRanges /
/// slotDurationMinutes (to know working hours). For this first version we
/// generate slots for a simple 9 AM – 5 PM window at the doctor's slot
/// duration and greyed out anything already booked. Swap this for the
/// doctor's actual dailyTimeRanges once that's parsed on the Flutter side.
class BookingScreen extends ConsumerStatefulWidget {
  final String doctorId;
  const BookingScreen({super.key, required this.doctorId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedSlotStart;
  String _consultationType = 'Video Consultation';
  final _symptomsController = TextEditingController();

  String get _dateKey =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  List<DateTime> _generateSlots(int slotDurationMinutes) {
    final slots = <DateTime>[];
    var cursor = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 9, 0);
    final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 17, 0);
    while (cursor.isBefore(end)) {
      slots.add(cursor);
      cursor = cursor.add(Duration(minutes: slotDurationMinutes));
    }
    return slots;
  }

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
          final slots = _generateSlots(doctor.slotDurationMinutes);
          final platformFees = (doctor.fees * 0.1).ceil();
          final totalAmount = doctor.fees + platformFees;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    Text('Select Date', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 14,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final date = DateTime.now().add(Duration(days: i));
                          final isSelected = date.day == _selectedDate.day &&
                              date.month == _selectedDate.month;
                          return InkWell(
                            onTap: () => setState(() {
                              _selectedDate = date;
                              _selectedSlotStart = null;
                            }),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 56,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _weekdayLabel(date.weekday),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? Colors.white70 : AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Select Time Slot', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    bookedSlotsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: LoadingIndicator(),
                      ),
                      error: (e, _) => Text('Could not load slots: $e'),
                      data: (bookedIsoSlots) {
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: slots.map((slot) {
                            final isBooked = bookedIsoSlots.any((iso) {
                              final bookedTime = DateTime.tryParse(iso);
                              return bookedTime != null &&
                                  bookedTime.hour == slot.hour &&
                                  bookedTime.minute == slot.minute &&
                                  bookedTime.day == slot.day;
                            });
                            final isSelected = _selectedSlotStart == slot;
                            return InkWell(
                              onTap: isBooked
                                  ? null
                                  : () => setState(() => _selectedSlotStart = slot),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isBooked
                                      ? AppColors.surfaceMuted
                                      : isSelected
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  _timeLabel(slot),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isBooked
                                        ? AppColors.textMuted
                                        : isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    decoration: isBooked ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('Consultation Type', style: Theme.of(context).textTheme.titleMedium),
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
                    const SizedBox(height: 20),
                    Text('Describe your symptoms', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _symptomsController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'E.g. fever since 2 days, mild headache...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _PriceRow('Consultation fee', '₹${doctor.fees.toStringAsFixed(0)}'),
                          const SizedBox(height: 6),
                          _PriceRow('Platform fee', '₹$platformFees'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(),
                          ),
                          _PriceRow('Total', '₹$totalAmount', bold: true),
                          const SizedBox(height: 6),
                          const Text(
                            'Final amount may differ based on your Parchi discount or guest surcharge.',
                            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: bookingState.status == BookingStatus.submitting
                        ? null
                        : () {
                      if (_selectedSlotStart == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a time slot')),
                        );
                        return;
                      }
                      if (_symptomsController.text.trim().length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please describe symptoms (min 10 characters)')),
                        );
                        return;
                      }
                      final slotEnd = _selectedSlotStart!
                          .add(Duration(minutes: doctor.slotDurationMinutes));
                      ref.read(bookingProvider.notifier).submit(
                        doctorId: doctor.id,
                        slotStart: _selectedSlotStart!,
                        slotEnd: slotEnd,
                        consultationType: _consultationType,
                        symptoms: _symptomsController.text.trim(),
                        consultationFees: doctor.fees,
                        platformFees: platformFees,
                        totalAmount: totalAmount,
                      );
                    },
                    child: bookingState.status == BookingStatus.submitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Confirm Booking'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
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

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _PriceRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: bold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}