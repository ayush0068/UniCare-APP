import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/slot_generator.dart';

class SlotGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final TimeSlot? selectedSlot;
  final ValueChanged<TimeSlot> onSlotSelected;

  const SlotGrid({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        child: const Text(
          'No slots configured for this day.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    final grouped = groupSlotsByPeriod(slots);
    final anyAvailable = slots.any((s) => s.status == SlotStatus.available);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final period in SlotPeriod.values)
          if (grouped[period]!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                periodLabel(period),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: grouped[period]!.map((slot) => _SlotChip(
                slot: slot,
                isSelected: selectedSlot?.start == slot.start,
                onTap: () => onSlotSelected(slot),
              )).toList(),
            ),
          ],
        if (!anyAvailable) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_busy_rounded, size: 18, color: AppColors.textMuted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No slots left for this day — try another date.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        const _Legend(),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;
  const _SlotChip({required this.slot, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBooked = slot.status == SlotStatus.booked;
    final isPast = slot.status == SlotStatus.past;
    final isDisabled = isBooked || isPast;

    Color bg = AppColors.surface;
    Color border = AppColors.border;
    Color text = AppColors.textPrimary;

    if (isSelected) {
      bg = AppColors.primary;
      border = AppColors.primary;
      text = Colors.white;
    } else if (isBooked) {
      bg = AppColors.surfaceMuted;
      border = AppColors.border;
      text = AppColors.textMuted;
    } else if (isPast) {
      bg = AppColors.surfaceMuted;
      border = AppColors.border;
      text = AppColors.textMuted;
    }

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _timeLabel(slot.start),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: text,
                decoration: isDisabled ? TextDecoration.lineThrough : null,
              ),
            ),
            if (isBooked || isPast) ...[
              const SizedBox(height: 2),
              Text(
                isBooked ? 'Booked' : 'Past',
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: const [
        _LegendItem(color: AppColors.surface, border: AppColors.border, label: 'Available'),
        _LegendItem(color: AppColors.primary, border: AppColors.primary, label: 'Selected'),
        _LegendItem(color: AppColors.surfaceMuted, border: AppColors.border, label: 'Booked / Past'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;
  const _LegendItem({required this.color, required this.border, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}