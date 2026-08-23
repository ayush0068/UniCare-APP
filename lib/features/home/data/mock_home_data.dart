/// TEMPORARY placeholder data so the home page has something to show.
/// Once we build the doctor-discovery API call (/api/doctor/list), this
/// file goes away and DoctorCard gets fed real data from the backend.

class SpecialtyItem {
  final String label;
  final String emoji;
  const SpecialtyItem(this.label, this.emoji);
}

const List<SpecialtyItem> mockSpecialties = [
  SpecialtyItem('General', '🩺'),
  SpecialtyItem('Cardiology', '❤️'),
  SpecialtyItem('Dermatology', '🧴'),
  SpecialtyItem('Pediatrics', '🧸'),
  SpecialtyItem('Orthopedic', '🦴'),
  SpecialtyItem('Neurology', '🧠'),
  SpecialtyItem('Dental', '🦷'),
  SpecialtyItem('ENT', '👂'),
];

class MockDoctor {
  final String name;
  final String specialty;
  final double rating;
  final int experienceYears;
  final String fee;
  const MockDoctor({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.experienceYears,
    required this.fee,
  });
}

const List<MockDoctor> mockDoctors = [
  MockDoctor(
    name: 'Dr. Ananya Sharma',
    specialty: 'Cardiologist',
    rating: 4.8,
    experienceYears: 9,
    fee: '₹499',
  ),
  MockDoctor(
    name: 'Dr. Rohan Mehta',
    specialty: 'Dermatologist',
    rating: 4.6,
    experienceYears: 6,
    fee: '₹399',
  ),
  MockDoctor(
    name: 'Dr. Priya Nair',
    specialty: 'General Physician',
    rating: 4.9,
    experienceYears: 12,
    fee: '₹299',
  ),
];