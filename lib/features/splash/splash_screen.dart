import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/domain/auth_provider.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';

/// Animated app-open sequence, similar in spirit to YouTube / JioHotstar's
/// splash: logo scales/bounces in with a soft glow pulse behind it, the
/// wordmark + tagline reveal with a staggered fade+slide, then a brief
/// loading beat before handing off to the right destination. Session
/// restoration happens in parallel underneath so the animation never
/// waits on the network — it only waits on itself, then navigates.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Logo: bounces in with a slight overshoot, like a soft "pop".
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // Soft glow ring behind the logo, gently pulsing outward.
  late final Animation<double> _glowScale;
  late final Animation<double> _glowFade;

  // Wordmark ("UniCare+") slides up and fades in just after the logo.
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  // Tagline fades in last.
  late final Animation<double> _taglineFade;

  // Bottom loading dots fade in once everything else has settled.
  late final Animation<double> _loaderFade;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.08).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.45)));

    _logoFade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.25));

    _glowScale = Tween<double>(begin: 0.6, end: 1.6).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.05, 0.55, curve: Curves.easeOut)),
    );
    _glowFade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.05, 0.6)));

    _titleFade = CurvedAnimation(parent: _controller, curve: const Interval(0.32, 0.62, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.32, 0.62, curve: Curves.easeOutCubic)),
    );

    _taglineFade = CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.75, curve: Curves.easeOut));

    _loaderFade = CurvedAnimation(parent: _controller, curve: const Interval(0.7, 0.9, curve: Curves.easeOut));

    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // First-ever launch (or a fresh install) -> show the notice/terms/
    // permissions screen before anything else, regardless of session.
    final hasAcceptedTerms = await SecureStorage.hasAcceptedTerms();
    if (!hasAcceptedTerms) {
      await Future.delayed(_controller.duration!);
      if (!mounted || _navigated) return;
      _navigated = true;
      context.go('/first-launch');
      return;
    }

    // Restore session in parallel with the animation, then wait for
    // whichever finishes last so the splash never feels rushed or stalled.
    final results = await Future.wait([
      ref.read(authStateProvider.notifier).checkExistingSession(),
      Future.delayed(_controller.duration!),
    ]);
    // results[0] is void from checkExistingSession — nothing to unpack.
    if (!mounted || _navigated) return;
    _navigated = true;

    final isLoggedIn = ref.read(authStateProvider).status == AuthStatus.authenticated;
    if (!isLoggedIn) {
      context.go('/role-selection');
      return;
    }

    final role = await SecureStorage.getRole();
    if (!mounted) return;
    context.go(role == 'doctor' ? '/doctor/home' : '/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glow ring + logo stack
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: _glowFade.value,
                            child: Transform.scale(
                              scale: _glowScale.value,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: _logoFade.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.health_and_safety_rounded,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: const Text(
                          'UniCare+',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _taglineFade,
                      child: const Text(
                        'Healthcare, whenever you need it',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 56,
                child: FadeTransition(
                  opacity: _loaderFade,
                  child: const _LoadingDots(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Three dots pulsing in sequence — a lightweight loading indicator that
/// matches the splash's playful, modern tone better than a spinner.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final t = (_controller.value - (i * 0.18)) % 1.0;
            final scale = 0.6 + 0.4 * (1 - (2 * t - 1).abs()).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}