import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PillNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const PillNavItem({required this.icon, required this.activeIcon, required this.label});
}

/// A floating, Apple-style "liquid glass" pill-shaped bottom navigation
/// bar — heavy backdrop blur, translucent white fill, a soft glossy
/// highlight along the top edge, and a hairline border, so content
/// scrolling underneath it stays visible through the frost. Meant to
/// float above page content (wrap the screen in a Stack and position
/// this at the bottom) rather than replace the Scaffold's own
/// bottomNavigationBar.
class PillNavBar extends StatefulWidget {
  final int currentIndex;
  final List<PillNavItem> items;
  final ValueChanged<int> onTap;

  const PillNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  State<PillNavBar> createState() => _PillNavBarState();
}

class _PillNavBarState extends State<PillNavBar> with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceFade = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceFade,
      child: SlideTransition(
        position: _entranceSlide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              // Heavier blur than a typical Material bar — this is what
              // sells the "frosted glass" look; content behind the bar
              // should read as a soft blur, not just a tinted overlay.
              filter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.38),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Glossy highlight along the top edge — a thin,
                    // brighter sliver that catches the eye like light
                    // reflecting off glass.
                    Positioned(
                      left: 8,
                      right: 8,
                      top: 0,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = constraints.maxWidth / widget.items.length;
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                              left: itemWidth * widget.currentIndex,
                              width: itemWidth,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Container(
                                  width: itemWidth - 12,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.primary.withValues(alpha: 0.95),
                                        AppColors.primaryDark.withValues(alpha: 0.95),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(widget.items.length, (i) {
                                final item = widget.items[i];
                                final isActive = i == widget.currentIndex;
                                return Expanded(
                                  child: _PillNavButton(
                                    item: item,
                                    isActive: isActive,
                                    onTap: () => widget.onTap(i),
                                  ),
                                );
                              }),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillNavButton extends StatefulWidget {
  final PillNavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _PillNavButton({required this.item, required this.isActive, required this.onTap});

  @override
  State<_PillNavButton> createState() => _PillNavButtonState();
}

class _PillNavButtonState extends State<_PillNavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          height: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Icon(
                  widget.isActive ? widget.item.activeIcon : widget.item.icon,
                  key: ValueKey(widget.isActive),
                  size: 21,
                  color: widget.isActive ? Colors.white : AppColors.textPrimary.withValues(alpha: 0.65),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: widget.isActive
                    ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.item.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}