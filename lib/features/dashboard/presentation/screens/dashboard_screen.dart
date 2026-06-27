import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen background ────────────────────────────────────
          Image.asset('assets/images/Background.png', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.45)),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo
                Image.asset(
                  'assets/images/Logo.png',
                  height: 110,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 32),

                // ── Banner category buttons ───────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BannerButton(
                          assetPath: 'assets/images/Banners/1&2.jpeg',
                          label: 'اولى وثانية',
                          delay: 0,
                        ),
                        const SizedBox(width: 20),
                        _BannerButton(
                          assetPath: 'assets/images/Banners/3&4.jpeg',
                          label: 'ثالثة ورابعة',
                          delay: 120,
                        ),
                        const SizedBox(width: 20),
                        _BannerButton(
                          assetPath: 'assets/images/Banners/5&6.jpeg',
                          label: 'خامسة وسادسة',
                          delay: 240,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Secondary nav row ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _IconNavButton(
                        icon: Icons.quiz,
                        label: AppStrings.questions,
                        route: '/questions',
                        color: AppColors.accent,
                        delay: 300,
                      ),
                      const SizedBox(width: 32),
                      _IconNavButton(
                        icon: Icons.group,
                        label: AppStrings.teams,
                        route: '/teams',
                        color: AppColors.success,
                        delay: 380,
                      ),
                      const SizedBox(width: 32),
                      _IconNavButton(
                        icon: Icons.settings,
                        label: AppStrings.settings,
                        route: '/settings',
                        color: AppColors.textSecondary,
                        delay: 460,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner button ─────────────────────────────────────────────────────────────

class _BannerButton extends StatefulWidget {
  final String assetPath;
  final String label;
  final int delay;

  const _BannerButton({
    required this.assetPath,
    required this.label,
    required this.delay,
  });

  @override
  State<_BannerButton> createState() => _BannerButtonState();
}

class _BannerButtonState extends State<_BannerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go(
            '/game/setup?category=${Uri.encodeComponent(widget.label)}',
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovered
                    ? AppColors.primary.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.2),
                width: _hovered ? 3 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 24,
                        spreadRadius: 4,
                      )
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner image
                  AnimatedScale(
                    scale: _hovered ? 1.04 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Image.asset(
                      widget.assetPath,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Bottom gradient + label
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedOpacity(
                            opacity: _hovered ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ابدأ اللعبة',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.15, end: 0);
  }
}

// ── Small icon nav button ─────────────────────────────────────────────────────

class _IconNavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final int delay;

  const _IconNavButton({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
    required this.delay,
  });

  @override
  State<_IconNavButton> createState() => _IconNavButtonState();
}

class _IconNavButtonState extends State<_IconNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 20, color: widget.color),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: _hovered ? widget.color : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 400.ms);
  }
}
