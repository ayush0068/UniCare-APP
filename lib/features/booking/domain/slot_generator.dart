import '../../doctors/data/doctor_model.dart';

enum SlotStatus { available, booked, past }

class TimeSlot {
  final DateTime start;
  final DateTime end;
  final SlotStatus status;
  const TimeSlot({required this.start, required this.end, required this.status});

  bool get isSelectable => status == SlotStatus.available;
}

/// Generates the day's bookable slots from the doctor's actual working
/// hours (dailyTimeRanges + slotDurationMinutes), then marks each one as
/// booked (already reserved by someone) or past (time has already gone
/// by, only relevant for today) so the UI can grey those out instead of
/// pretending every slot is open.
List<TimeSlot> generateDaySlots({
  required DateTime date,
  required DoctorModel doctor,
  required List<String> bookedIsoSlots,
  required DateTime now,
}) {
  // Fallback to a sensible default window if the doctor hasn't configured
  // dailyTimeRanges yet, so booking still works instead of showing nothing.
  final ranges = doctor.dailyTimeRanges.isNotEmpty
      ? doctor.dailyTimeRanges
      : [TimeRange(start: '09:00', end: '17:00')];

  final bookedTimes = bookedIsoSlots
      .map((iso) => DateTime.tryParse(iso))
      .whereType<DateTime>()
      .toList();

  final slots = <TimeSlot>[];

  for (final range in ranges) {
    final startParts = range.start.split(':');
    final endParts = range.end.split(':');
    if (startParts.length != 2 || endParts.length != 2) continue;

    var cursor = DateTime(
      date.year, date.month, date.day,
      int.tryParse(startParts[0]) ?? 9,
      int.tryParse(startParts[1]) ?? 0,
    );
    final rangeEnd = DateTime(
      date.year, date.month, date.day,
      int.tryParse(endParts[0]) ?? 17,
      int.tryParse(endParts[1]) ?? 0,
    );

    while (cursor.isBefore(rangeEnd)) {
      final slotEnd = cursor.add(Duration(minutes: doctor.slotDurationMinutes));
      if (slotEnd.isAfter(rangeEnd)) break;

      final isBooked = bookedTimes.any((b) =>
      b.year == cursor.year &&
          b.month == cursor.month &&
          b.day == cursor.day &&
          b.hour == cursor.hour &&
          b.minute == cursor.minute);

      final isPast = cursor.isBefore(now);

      slots.add(TimeSlot(
        start: cursor,
        end: slotEnd,
        status: isBooked
            ? SlotStatus.booked
            : isPast
            ? SlotStatus.past
            : SlotStatus.available,
      ));

      cursor = slotEnd;
    }
  }

  slots.sort((a, b) => a.start.compareTo(b.start));
  return slots;
}

enum SlotPeriod { morning, afternoon, evening }

SlotPeriod periodOf(DateTime time) {
  if (time.hour < 12) return SlotPeriod.morning;
  if (time.hour < 17) return SlotPeriod.afternoon;
  return SlotPeriod.evening;
}

String periodLabel(SlotPeriod period) {
  switch (period) {
    case SlotPeriod.morning:
      return 'Morning';
    case SlotPeriod.afternoon:
      return 'Afternoon';
    case SlotPeriod.evening:
      return 'Evening';
  }
}

Map<SlotPeriod, List<TimeSlot>> groupSlotsByPeriod(List<TimeSlot> slots) {
  final grouped = <SlotPeriod, List<TimeSlot>>{
    SlotPeriod.morning: [],
    SlotPeriod.afternoon: [],
    SlotPeriod.evening: [],
  };
  for (final slot in slots) {
    grouped[periodOf(slot.start)]!.add(slot);
  }
  return grouped;
}