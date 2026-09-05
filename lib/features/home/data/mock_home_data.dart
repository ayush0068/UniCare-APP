import 'package:flutter/material.dart';

/// TEMPORARY placeholder data so the home page has something to show.
/// Once we build the doctor-discovery API call (/api/doctor/list), this
/// file goes away and DoctorCard gets fed real data from the backend.

class SpecialtyItem {
  final String label;
  final IconData icon;
  const SpecialtyItem(this.label, this.icon);
}

const List<SpecialtyItem> mockSpecialties = [
  SpecialtyItem('General', Icons.local_hospital_rounded),
  SpecialtyItem('Cardiology', Icons.favorite_rounded),
  SpecialtyItem('Dermatology', Icons.face_retouching_natural_rounded),
  SpecialtyItem('Pediatrics', Icons.child_friendly_rounded),
  SpecialtyItem('Orthopedic', Icons.accessibility_new_rounded),
  SpecialtyItem('Neurology', Icons.psychology_rounded),
  SpecialtyItem('Dental', Icons.medical_information_rounded),
  SpecialtyItem('ENT', Icons.hearing_rounded),
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