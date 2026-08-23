import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/doctors/presentation/doctor_list_screen.dart';
import '../../features/doctors/presentation/doctor_detail_screen.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/booking/presentation/booking_success_screen.dart';

/// All navigation routes in one place.
///
/// Home is the default landing screen (not login). Splash runs first
/// (checks stored JWT) then always lands on /home — HomeScreen decides
/// what to show/gate based on auth status.
///
/// STEP 1 DONE: Doctor list -> Doctor detail -> Booking -> Success.
/// Routes still marked "// TODO" below are referenced from HomeScreen's
/// quick actions but aren't built yet — next steps in the roadmap.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
        path: '/register', builder: (context, state) => const RegisterScreen()),

    // --- Doctors + Booking (Step 1) ---
    GoRoute(path: '/doctors', builder: (context, state) => const DoctorListScreen()),
    GoRoute(
      path: '/doctors/:id',
      builder: (context, state) =>
          DoctorDetailScreen(doctorId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/booking/:doctorId',
      builder: (context, state) =>
          BookingScreen(doctorId: state.pathParameters['doctorId']!),
    ),
    GoRoute(
      path: '/booking-success',
      builder: (context, state) => BookingSuccessScreen(
        appointment: state.extra as Map<String, dynamic>?,
      ),
    ),

    // TODO: build these next, one feature at a time (see roadmap)
    // GoRoute(path: '/appointments', builder: (context, state) => const AppointmentsScreen()),
    // GoRoute(path: '/consultation', builder: (context, state) => const ConsultationScreen()),
    // GoRoute(path: '/ai-assistant', builder: (context, state) => const AiAssistantScreen()),
    // GoRoute(path: '/prescriptions', builder: (context, state) => const PrescriptionsScreen()),
    // GoRoute(path: '/aftercare', builder: (context, state) => const AftercareScreen()),
    // GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    // GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],

  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Coming soon')),
    body: const Center(
      child: Text('This screen isn\'t built yet — coming in the next step.'),
    ),
  ),
);