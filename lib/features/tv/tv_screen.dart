import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tv_controller.dart';

/// Full-screen presenter view shown on the TV.
/// Listens to [TvController] and renders:
///   • Idle  — animated logo / waiting screen
///   • Question — large text + A/B/C/D option grid
///   • Reveal  — same layout with correct answer highlighted green
class TvScreen extends StatefulWidget {
  const TvScreen({super.key});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  static const _bg = Color(0xFF050A18);
  static const _accent = Color(0xFFFF6B2B);

  @override
  void initState() {
    super.initState();
    TvController.instance.addListener(_onPayloadChanged);
  }

  void _onPayloadChanged() => setState(() {});

  @override
  void dispose() {
    TvController.instance.removeListener(_onPayloadChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payload = TvController.instance.payload;

    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: payload == null || payload.type == TvPayloadType.clear
            ? _IdleView(key: const ValueKey('idle'))
            : payload.type == TvPayloadType.buzzed
                ? _BuzzedTakeoverView(
                    key: ValueKey(
                        'buzzed_${payload.buzzedTeamName}_${payload.buzzCountdown}'),
                    payload: payload,
                  )
                : _QuestionView(
                    key: ValueKey('${payload.text}_${payload.type.name}'),
                    payload: payload,
                  ),
      ),
    );
  }
}

// ── Idle / waiting screen ─────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo with orange glow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B2B).withOpacity(0.35),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/Logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 40),
          Text(
            'مهرجان العباقرة',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.alexandria(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 3000.ms, color: const Color(0xFFFF6B2B)),
          const SizedBox(height: 16),
          Text(
            'استعد للمنافسة',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.alexandria(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white38,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 48),
          // Pulsing dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B2B),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(
                    delay: Duration(milliseconds: i * 200),
                    duration: 600.ms,
                  )
                  .then()
                  .fadeOut(duration: 600.ms),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Question / reveal view ────────────────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  final TvPayload payload;

  const _QuestionView({super.key, required this.payload});

  static const _optionColors = [
    Color(0xFF1565C0), // A — blue
    Color(0xFF2E7D32), // B — green
    Color(0xFF6A1B9A), // C — purple
    Color(0xFFE65100), // D — deep orange
  ];
  static const _correctColor = Color(0xFF43A047);

  @override
  Widget build(BuildContext context) {
    final isReveal = payload.type == TvPayloadType.reveal;
    final hasOptions = payload.options.isNotEmpty;
    final roundLabel = 'ROUND ${payload.roundNumber}';
    final hasTimer = !isReveal &&
        payload.timerTotal != null &&
        payload.timerTotal! > 0;

    return Stack(
      children: [
        _buildBody(isReveal, hasOptions, roundLabel),
        // ── Big, hard-to-miss countdown badge ─────────────────────────────
        if (hasTimer)
          Positioned(
            top: 78,
            right: 32,
            child: _TvTimerRing(
              remaining: payload.timerRemaining ?? 0,
              total: payload.timerTotal!,
              size: 120,
            ),
          ),
      ],
    );
  }

  Widget _buildBody(bool isReveal, bool hasOptions, String roundLabel) {
    return Column(
      children: [
        // ── Top bar ────────────────────────────────────────────────────────
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: const BoxDecoration(
            color: Color(0xFF0D1428),
            border: Border(
              bottom: BorderSide(color: Color(0xFF1E2A45), width: 1),
            ),
          ),
          child: Row(
            children: [
              Image.asset('assets/images/Logo.png', width: 40, height: 40),
              const SizedBox(width: 12),
              Text(
                'مهرجان العباقرة',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.alexandria(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _Chip(label: roundLabel, color: const Color(0xFF1E3A5F)),
              const SizedBox(width: 12),
              _Chip(
                label: '${payload.points} pts',
                color: const Color(0xFFFF6B2B).withOpacity(0.25),
                textColor: const Color(0xFFFF6B2B),
              ),
              if (isReveal) ...[
                const SizedBox(width: 12),
                _Chip(
                  label: '✓ REVEALED',
                  color: _correctColor.withOpacity(0.2),
                  textColor: _correctColor,
                ),
              ],
            ],
          ),
        ),

        // ── Question text ──────────────────────────────────────────────────
        Expanded(
          flex: hasOptions ? 4 : 7,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 32),
            child: Text(
              payload.text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.alexandria(
                fontSize: hasOptions ? 42 : 56,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.4,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0, duration: 400.ms),
          ),
        ),

        // ── Options grid ───────────────────────────────────────────────────
        if (hasOptions)
          Expanded(
            flex: 5,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(48, 0, 48, 48),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 4.5,
                ),
                itemCount: payload.options.length.clamp(0, 4),
                itemBuilder: (_, i) {
                  const letters = ['A', 'B', 'C', 'D'];
                  final optText = payload.options[i];
                  final isCorrect = isReveal &&
                      payload.correctAnswer != null &&
                      optText.trim().toLowerCase() ==
                          payload.correctAnswer!.trim().toLowerCase();

                  final baseColor = _optionColors[i % _optionColors.length];
                  final effectiveColor =
                      isCorrect ? _correctColor : baseColor;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    decoration: BoxDecoration(
                      color: effectiveColor.withOpacity(isCorrect ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: effectiveColor.withOpacity(isCorrect ? 1.0 : 0.5),
                        width: isCorrect ? 3 : 2,
                      ),
                      boxShadow: isCorrect
                          ? [
                              BoxShadow(
                                color: _correctColor.withOpacity(0.45),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Letter badge
                        Container(
                          width: 64,
                          decoration: BoxDecoration(
                            color: effectiveColor.withOpacity(isCorrect ? 0.6 : 0.35),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                          child: Center(
                            child: isCorrect
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 28)
                                : Text(
                                    letters[i],
                                    style: GoogleFonts.alexandria(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                    ),
                                  ),
                          ),
                        ),
                        // Option text
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              optText,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.alexandria(
                                fontSize: 20,
                                fontWeight: isCorrect
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isCorrect
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.87),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 80))
                      .fadeIn(duration: 350.ms)
                      .slideX(begin: 0.06, end: 0, duration: 350.ms);
                },
              ),
            ),
          ),

        // ── Text-only correct answer banner (no options) ───────────────────
        if (isReveal &&
            payload.correctAnswer != null &&
            payload.correctAnswer!.isNotEmpty &&
            !hasOptions)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(80, 0, 80, 48),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 24),
              decoration: BoxDecoration(
                color: _correctColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: _correctColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: _correctColor.withOpacity(0.35),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: _correctColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'CORRECT ANSWER',
                        style: GoogleFonts.alexandria(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _correctColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    payload.correctAnswer!,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alexandria(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                ),
          ),
      ],
    );
  }
}

// ── Buzzed-in full-screen takeover ────────────────────────────────────────────

class _BuzzedTakeoverView extends StatelessWidget {
  final TvPayload payload;
  const _BuzzedTakeoverView({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final teamColor = payload.buzzedTeamColor != null
        ? Color(payload.buzzedTeamColor!)
        : const Color(0xFFFF6B2B);
    final teamName = payload.buzzedTeamName ?? '';
    final count = payload.buzzCountdown ?? 0;

    return Container(
      key: const ValueKey('buzzed'),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            teamColor.withOpacity(0.55),
            const Color(0xFF050A18),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BUZZED IN',
              style: GoogleFonts.alexandria(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white54,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              teamName,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.alexandria(
                fontSize: 88,
                fontWeight: FontWeight.w900,
                color: teamColor,
                letterSpacing: 1,
                shadows: [
                  Shadow(color: teamColor.withOpacity(0.8), blurRadius: 40),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white38),
            const SizedBox(height: 56),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: teamColor, width: 5),
                color: teamColor.withOpacity(0.15),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: teamColor,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ).animate(key: ValueKey(count)).scale(
                  begin: const Offset(1.3, 1.3),
                  end: const Offset(1.0, 1.0),
                  duration: 300.ms,
                  curve: Curves.easeOut,
                ),
          ],
        ),
      ),
    );
  }
}

// ── On-screen countdown ring ──────────────────────────────────────────────────

class _TvTimerRing extends StatelessWidget {
  final int remaining;
  final int total;
  final double size;
  const _TvTimerRing({
    required this.remaining,
    required this.total,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (remaining.clamp(0, total)) / total : 0.0;
    final isLow = remaining <= 5;
    final color = isLow ? const Color(0xFFE53935) : const Color(0xFFFF6B2B);
    final strokeWidth = size / 11;
    final fontSize = size * 0.4;

    Widget ring = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0D1428).withOpacity(0.85),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.55),
            blurRadius: size * 0.35,
            spreadRadius: size * 0.03,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _TvTimerRingPainter(
          fraction: fraction,
          color: color,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Text(
            '$remaining',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: color.withOpacity(0.7), blurRadius: 12)],
            ),
          ),
        ),
      ),
    );

    if (isLow) {
      ring = ring
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.12, 1.12),
            duration: 400.ms,
          );
    }
    return ring;
  }
}

class _TvTimerRingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final double strokeWidth;
  _TvTimerRingPainter({
    required this.fraction,
    required this.color,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    final bgPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * 3.14159265 * fraction;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_TvTimerRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}

// ── Small chip label ──────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Chip({
    required this.label,
    required this.color,
    this.textColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.alexandria(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
