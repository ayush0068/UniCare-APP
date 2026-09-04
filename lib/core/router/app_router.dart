import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'page_transitions.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/first_launch/presentation/first_launch_screen.dart';
import '../../features/onboarding/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/patient_onboarding/presentation/patient_onboarding_screen.dart';
import '../../features/auth/presentation/doctor_login_screen.dart';
import '../../features/auth/presentation/doctor_register_screen.dart';
import '../../features/doctor_onboarding/presentation/doctor_onboarding_screen.dart';
import '../../features/doctor_onboarding/presentation/verification_pending_screen.dart';
import '../../features/doctor_home/presentation/doctor_home_screen.dart';
import '../../features/appointments/presentation/patient_dashboard_screen.dart';
import '../../features/appointments/presentation/doctor_appointments_screen.dart';
import '../../features/consultation/presentation/consultation_screen.dart';
import '../../features/prescription/presentation/prescription_form_screen.dart';
import '../../features/prescription/presentation/prescription_view_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/doctors/presentation/doctor_list_screen.dart';
import '../../features/doctors/presentation/doctor_detail_screen.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/booking/presentation/booking_success_screen.dart';
import '../../features/payments/presentation/payment_screen.dart';

/// All navigation routes in one place. Every route uses fadeSlidePage
/// (see page_transitions.dart) for a smooth, modern feel instead of the
/// default abrupt platform transition.
///
/// FLOW:
/// Splash (animated) -> checks stored session:
///   - no session          -> /role-selection
///   - role patient/guest  -> /home
///   - role doctor         -> /doctor/home

/// Root navigator key, also handed to [GoRouter] below. This lets
/// screens/services that sit outside the widget currently on top of the
/// stack (like the app-wide incoming-call overlay) push full-screen
/// routes — e.g. the ringing screen — no matter which page is showing.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const SplashScreen()),
    ),
    GoRoute(
      path: '/first-launch',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const FirstLaunchScreen()),
    ),
    GoRoute(
      path: '/role-selection',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const RoleSelectionScreen()),
    ),

    // --- Patient auth ---
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const HomeScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const LoginScreen()),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const RegisterScreen()),
    ),
    GoRoute(
      path: '/patient-onboarding',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const PatientOnboardingScreen()),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const ProfileScreen()),
    ),

    // --- Doctor auth + onboarding ---
    GoRoute(
      path: '/doctor-login',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const DoctorLoginScreen()),
    ),
    GoRoute(
      path: '/doctor-register',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const DoctorRegisterScreen()),
    ),
    GoRoute(
      path: '/doctor-onboarding',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const DoctorOnboardingScreen()),
    ),
    GoRoute(
      path: '/doctor-pending-verification',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const VerificationPendingScreen()),
    ),
    GoRoute(
      path: '/doctor/home',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const DoctorHomeScreen()),
    ),
    GoRoute(
      path: '/doctor/appointments',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const DoctorAppointmentsScreen()),
    ),
    GoRoute(
      path: '/appointments',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const PatientDashboardScreen()),
    ),
    GoRoute(
      path: '/consultation/:appointmentId',
      pageBuilder: (context, state) => fadeSlidePage(
        context, state,
        ConsultationScreen(appointmentId: state.pathParameters['appointmentId']!),
      ),
    ),
    GoRoute(
      path: '/prescription/new/:appointmentId',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return fadeSlidePage(
          context, state,
          PrescriptionFormScreen(
            appointmentId: state.pathParameters['appointmentId']!,
            patientName: extra['patientName'] as String? ?? 'the patient',
          ),
        );
      },
    ),
    GoRoute(
      path: '/prescription/view/:appointmentId',
      pageBuilder: (context, state) => fadeSlidePage(
        context, state,
        PrescriptionViewScreen(appointmentId: state.pathParameters['appointmentId']!),
      ),
    ),

    // --- Doctors + Booking (patient side) ---
    GoRoute(
      path: '/doctors',
      pageBuilder: (context, state) => fadeSlidePage(context, state, const DoctorListScreen()),
    ),
    GoRoute(
      path: '/doctors/:id',
      pageBuilder: (context, state) => fadeSlidePage(
        context, state,
        DoctorDetailScreen(doctorId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/booking/:doctorId',
      pageBuilder: (context, state) => fadeSlidePage(
        context, state,
        BookingScreen(doctorId: state.pathParameters['doctorId']!),
      ),
    ),
    GoRoute(
      path: '/booking-success',
      pageBuilder: (context, state) => fadeSlidePage(
        context, state,
        BookingSuccessScreen(appointment: state.extra as Map<String, dynamic>?),
      ),
    ),

    // --- Payments (Razorpay) ---
    GoRoute(
      path: '/payment/:appointmentId',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return fadeSlidePage(
          context, state,
          PaymentScreen(
            appointmentId: state.pathParameters['appointmentId']!,
            amount: (extra['amount'] as num?) ?? 0,
            doctorName: extra['doctorName'] as String?,
            patientName: extra['patientName'] as String?,
            patientEmail: extra['patientEmail'] as String?,
            patientPhone: extra['patientPhone'] as String?,
          ),
        );
      },
    ),

    // TODO: build these next, one feature at a time (see roadmap)
    // GoRoute(path: '/appointments', ...),
    // GoRoute(path: '/consultation', ...),
    // GoRoute(path: '/ai-assistant', ...),
    // GoRoute(path: '/prescriptions', ...),
    // GoRoute(path: '/aftercare', ...),
    // GoRoute(path: '/notifications', ...),
    // GoRoute(path: '/profile', ...),
  ],

  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Coming soon')),
    body: const Center(
      child: Text('This screen isn\'t built yet — coming in the next step.'),
    ),
  ),
);