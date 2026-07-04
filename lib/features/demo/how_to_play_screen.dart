import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../game/presentation/bloc/game_bloc.dart';
import '../questions/domain/entities/question.dart';
import '../teams/domain/entities/team.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

void showHowToPlay(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => BlocProvider.value(
      value: context.read<GameBloc>(),
      child: const HowToPlayScreen(),
    ),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _total = 5;

  void _next() {
    if (_page < _total - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _prev() {
    if (_page > 0) {
      _controller.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: const Color(0xFF0D1428),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 760,
        height: 560,
        child: Column(
          children: [
            // ── Header bar ─────────────────────────────────────────────────
            _Header(
                page: _page,
                total: _total,
                onClose: () => Navigator.of(context).pop()),

            // ── Pages ──────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _PageOverview(),
                  _PageRound1(),
                  _PageRound2(),
                  _PageRound3(),
                  _PageDemo(),
                ],
              ),
            ),

            // ── Footer nav ─────────────────────────────────────────────────
            _Footer(
              page: _page,
              total: _total,
              onPrev: _prev,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int page;
  final int total;
  final VoidCallback onClose;

  const _Header(
      {required this.page, required this.total, required this.onClose});

  static const _titles = [
    'كيف تلعب؟',
    'الفقرة الأولى — أسئلة الفرق',
    'الفقرة الثانية — ضربات جزاء',
    'الفقرة الثالثة — تحت الضغط',
    'جرب الديمو',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E2A45))),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/Logo.png', width: 32, height: 32),
          const SizedBox(width: 12),
          Text(
            _titles[page],
            textDirection: TextDirection.rtl,
            style: GoogleFonts.alexandria(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const Spacer(),
          // Progress dots
          Row(
            children: List.generate(
                total,
                (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == page ? 20 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i == page
                            ? const Color(0xFFFF6B2B)
                            : const Color(0xFF2A3A5E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final int page;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _Footer(
      {required this.page,
      required this.total,
      required this.onPrev,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E2A45))),
      ),
      child: Row(
        children: [
          if (page > 0)
            _NavBtn(label: '← السابق', onTap: onPrev, filled: false)
          else
            const SizedBox(width: 100),
          const Spacer(),
          Text(
            '${page + 1} / $total',
            style: GoogleFonts.alexandria(color: Colors.white38, fontSize: 13),
          ),
          const Spacer(),
          if (page < total - 1)
            _NavBtn(label: 'التالي →', onTap: onNext, filled: true)
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _NavBtn(
      {required this.label, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF6B2B) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: filled ? const Color(0xFFFF6B2B) : const Color(0xFF2A3A5E),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.alexandria(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Page 1 — Overview
// ══════════════════════════════════════════════════════════════════════════════

class _PageOverview extends StatelessWidget {
  const _PageOverview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        children: [
          // Left: big trophy / logo area
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _TrophyAnimation(),
                const SizedBox(height: 20),
                Text(
                  'مهرجان العباقرة',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alexandria(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 3000.ms, color: const Color(0xFFFF6B2B)),
                const SizedBox(height: 8),
                Text(
                  'المسابقة تتكون من ٣ فقرات',
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.alexandria(
                      fontSize: 14, color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Right: round cards
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _RoundBadge(
                  number: '١',
                  title: 'أسئلة الفرق',
                  subtitle: 'كل فريق يجيب على أسئلته الخاصة',
                  icon: Icons.quiz_rounded,
                  color: Color(0xFF2E7D32),
                  delay: 0,
                ),
                SizedBox(height: 12),
                _RoundBadge(
                  number: '٢',
                  title: 'ضربات جزاء',
                  subtitle: 'تنافس بين زوجين من الفرق',
                  icon: Icons.sports_soccer_rounded,
                  color: Color(0xFF1565C0),
                  delay: 150,
                ),
                SizedBox(height: 12),
                _RoundBadge(
                  number: '٣',
                  title: 'تحت الضغط',
                  subtitle: 'متسابقون ضد الوقت',
                  icon: Icons.speed_rounded,
                  color: Color(0xFFC62828),
                  delay: 300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyAnimation extends StatelessWidget {
  const _TrophyAnimation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFF6B2B).withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 8),
        ],
      ),
      child: const Icon(Icons.emoji_events_rounded,
          size: 80, color: Color(0xFFFF6B2B)),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1.1, 1.1),
        duration: 2000.ms,
        curve: Curves.easeInOut);
  }
}

class _RoundBadge extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int delay;

  const _RoundBadge({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.alexandria(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(subtitle,
                    style: GoogleFonts.alexandria(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(number,
                  style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Page 2 — Round 1
// ══════════════════════════════════════════════════════════════════════════════

class _PageRound1 extends StatelessWidget {
  const _PageRound1();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        children: [
          // Animated illustration
          Expanded(
            flex: 2,
            child: const _BuzzerRaceAnimation(color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 32),
          // Rules
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RuleRow(
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF2E7D32),
                    text: 'كل فريق يجيب على أسئلته الخاصة واحداً تلو الآخر'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.timer_rounded,
                    color: const Color(0xFF2E7D32),
                    text: 'لكل سؤال وقت محدد — اضغط الزرار قبل انتهاء الوقت'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.greenSuccess,
                    text: 'إجابة صحيحة → تُضاف النقاط للفريق'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.cancel_rounded,
                    color: AppColors.redError,
                    text: 'إجابة خاطئة → تُخصم نقاط من رصيد الفريق'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.star_rounded,
                    color: const Color(0xFFFF6B2B),
                    text: 'نقطة مضاعفة ✕٢ متاحة مرة واحدة لكل فريق'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Page 3 — Round 2
// ══════════════════════════════════════════════════════════════════════════════

class _PageRound2 extends StatelessWidget {
  const _PageRound2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: const _PairCompeteAnimation(),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RuleRow(
                    icon: Icons.people_rounded,
                    color: const Color(0xFF1565C0),
                    text: 'الفرق تتنافس في أزواج — كل مباراة بين فريقين'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.touch_app_rounded,
                    color: const Color(0xFF1565C0),
                    text: 'اللي يضغط الزرار أول ويجاوب صح يكسب نقاط المباراة'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.replay_rounded,
                    color: const Color(0xFFFF6B2B),
                    text: 'إجابة خاطئة → الفريق الثاني يحصل على فرصة للإجابة'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.quiz_rounded,
                    color: const Color(0xFF1565C0),
                    text: 'كل مباراة تتكون من عدة أسئلة متتالية'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.greenSuccess,
                    text: 'بعد كل الأزواج تنتهي الفقرة الثانية وتبدأ الثالثة'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Page 4 — Round 3
// ══════════════════════════════════════════════════════════════════════════════

class _PageRound3 extends StatelessWidget {
  const _PageRound3();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: const _PressureTimerAnimation(),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RuleRow(
                    icon: Icons.person_rounded,
                    color: const Color(0xFFC62828),
                    text: 'كل فريق يختار عدداً من المتسابقين قبل بدء اللعبة'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.timer_rounded,
                    color: const Color(0xFFC62828),
                    text: 'وقت مشترك لكل الفريق — كل الأسئلة من نفس المؤقت'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.swap_horiz_rounded,
                    color: const Color(0xFFFF6B2B),
                    text: 'كل متسابق يجيب على سؤال واحد فقط بالترتيب'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.greenSuccess,
                    text: 'إجابة صحيحة → نقاط + انتقال للمتسابق التالي'),
                const SizedBox(height: 14),
                _RuleRow(
                    icon: Icons.access_alarm_rounded,
                    color: const Color(0xFFC62828),
                    text: 'انتهاء الوقت = انتهاء دور الفريق'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Page 5 — Demo launcher
// ══════════════════════════════════════════════════════════════════════════════

class _PageDemo extends StatelessWidget {
  const _PageDemo();

  static final _demoTeams = [
    const Team(
        id: 'demo_red',
        name: 'الفريق الأحمر',
        color: 0xFFE53935,
        members: ['مرقس', 'بطرس', 'مارينا']),
    const Team(
        id: 'demo_blue',
        name: 'الفريق الأزرق',
        color: 0xFF1E88E5,
        members: ['جورج', 'ماريا', 'مينا']),
  ];

  static final _r1Questions = [
    const Question(
        id: 'dr1_1',
        text: 'ما هي عاصمة جمهورية مصر العربية؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.easy,
        points: 10,
        correctAnswer: 'القاهرة',
        options: ['القاهرة', 'الإسكندرية', 'أسوان', 'الأقصر']),
    const Question(
        id: 'dr1_2',
        text: 'كم عدد أضلاع المثلث؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.easy,
        points: 10,
        correctAnswer: '٣',
        options: ['٣', '٤', '٥', '٦']),
    const Question(
        id: 'dr1_3',
        text: 'ما هو أكبر كوكب في المجموعة الشمسية؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.medium,
        points: 15,
        correctAnswer: 'المشتري',
        options: ['المشتري', 'زحل', 'الأرض', 'المريخ']),
    const Question(
        id: 'dr1_4',
        text: 'كم عدد أيام شهر رمضان في الغالب؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.easy,
        points: 10,
        correctAnswer: '٣٠',
        options: ['٢٨', '٢٩', '٣٠', '٣١']),
  ];

  static final _r2Questions = [
    const Question(
        id: 'dr2_1',
        text: 'كم يوماً في السنة الكبيسة؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.medium,
        points: 20,
        correctAnswer: '٣٦٦',
        options: ['٣٦٥', '٣٦٦', '٣٦٤', '٣٦٧']),
    const Question(
        id: 'dr2_2',
        text: 'ما هو أسرع حيوان بري على وجه الأرض؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.easy,
        points: 20,
        correctAnswer: 'الفهد',
        options: ['الفهد', 'الأسد', 'الحصان', 'الغزال']),
    const Question(
        id: 'dr2_3',
        text: 'كم عدد حواس الإنسان الأساسية؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.easy,
        points: 20,
        correctAnswer: '٥',
        options: ['٣', '٤', '٥', '٦']),
  ];

  static final _r3Questions = [
    const Question(
        id: 'dr3_1',
        text: 'ما هو اسم نهر مصر الشهير؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.easy,
        points: 10,
        correctAnswer: 'النيل'),
    const Question(
        id: 'dr3_2',
        text: 'كم عدد أشهر السنة؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.easy,
        points: 10,
        correctAnswer: '١٢'),
    const Question(
        id: 'dr3_3',
        text: 'ما هو لون السماء في النهار؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.easy,
        points: 10,
        correctAnswer: 'الأزرق'),
    const Question(
        id: 'dr3_4',
        text: 'ما هي عاصمة المملكة العربية السعودية؟',
        categoryId: 'demo',
        type: QuestionType.text,
        difficulty: DifficultyLevel.easy,
        points: 10,
        correctAnswer: 'الرياض'),
  ];

  void _startDemo(BuildContext context) {
    Navigator.of(context).pop(); // close dialog
    context.read<GameBloc>().add(StartCompetition(
          teams: _demoTeams,
          round1Questions: _r1Questions,
          round1Timer: 30,
          questionsPerTeam: 2,
          round2Questions: _r2Questions,
          round2Timer: 20,
          r2QuestionsPerPair: 3,
          round3Questions: _r3Questions,
          sharedTimer: 60,
          contestantsPerTeam: const [2, 2],
        ));
    context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        children: [
          // Celebration animation
          Expanded(
            flex: 2,
            child: const _CelebrationAnimation(),
          ),
          const SizedBox(width: 32),
          // Actions
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'جاهز للمنافسة؟',
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.alexandria(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'جرّب الديمو لتتعرف على طريقة اللعب\nبفريقين وأسئلة تجريبية جاهزة',
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.alexandria(
                      fontSize: 14, color: Colors.white60, height: 1.6),
                ),
                const SizedBox(height: 28),
                // Demo teams preview
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _TeamPill(
                        name: 'الفريق الأزرق', color: const Color(0xFF1E88E5)),
                    const SizedBox(width: 10),
                    Text('ضد',
                        style: GoogleFonts.alexandria(
                            color: Colors.white38, fontSize: 12)),
                    const SizedBox(width: 10),
                    _TeamPill(
                        name: 'الفريق الأحمر', color: const Color(0xFFE53935)),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startDemo(context),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('ابدأ الديمو الآن',
                        style: GoogleFonts.alexandria(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B2B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '٢ فريق • ٢ سؤال لكل فريق (ف١) • ٣ أسئلة ضربات جزاء • ٢ متسابق لكل فريق (ف٣)',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.alexandria(
                      fontSize: 11, color: Colors.white30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPill extends StatelessWidget {
  final String name;
  final Color color;
  const _TeamPill({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
              radius: 8,
              backgroundColor: color,
              child: Text(name[0],
                  style: const TextStyle(color: Colors.white, fontSize: 8))),
          const SizedBox(width: 8),
          Text(name,
              style: GoogleFonts.alexandria(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Animations
// ══════════════════════════════════════════════════════════════════════════════

/// Animated buzzer + score counter for R1
class _BuzzerRaceAnimation extends StatefulWidget {
  final Color color;
  const _BuzzerRaceAnimation({required this.color});

  @override
  State<_BuzzerRaceAnimation> createState() => _BuzzerRaceAnimationState();
}

class _BuzzerRaceAnimationState extends State<_BuzzerRaceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _buzz;
  late final Animation<double> _score;
  int _scoreVal = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() => _scoreVal = 0);
              _ctrl.forward(from: 0);
            }
          });
        }
      });
    _buzz = CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.6));
    _score = CurvedAnimation(parent: _ctrl, curve: const Interval(0.65, 0.9));
    _ctrl.addListener(() {
      final s = (_score.value * 10).round();
      if (s != _scoreVal) setState(() => _scoreVal = s);
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Question card
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _ctrl.value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1428),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2A45)),
              ),
              child: Text(
                'ما هي عاصمة مصر؟',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: GoogleFonts.alexandria(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Buzzer
        AnimatedBuilder(
          animation: _buzz,
          builder: (_, __) {
            final lit = _buzz.value > 0.5;
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lit ? widget.color : widget.color.withOpacity(0.2),
                boxShadow: lit
                    ? [
                        BoxShadow(
                            color: widget.color.withOpacity(0.6),
                            blurRadius: 24,
                            spreadRadius: 4)
                      ]
                    : [],
              ),
              child: Icon(Icons.radio_button_checked_rounded,
                  color: lit ? Colors.white : Colors.white38, size: 36),
            );
          },
        ),
        const SizedBox(height: 16),
        // Score
        AnimatedBuilder(
          animation: _score,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.color.withOpacity(0.4)),
            ),
            child: Text(
              '+$_scoreVal نقطة',
              style: GoogleFonts.alexandria(
                  color: widget.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated pair competition for R2
class _PairCompeteAnimation extends StatefulWidget {
  const _PairCompeteAnimation();

  @override
  State<_PairCompeteAnimation> createState() => _PairCompeteAnimationState();
}

class _PairCompeteAnimationState extends State<_PairCompeteAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _redWins = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _redWins = !_redWins);
            _ctrl.forward(from: 0);
          });
        }
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final winnerGlow = _ctrl.value > 0.7;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TeamBlock(
                  name: 'الأحمر',
                  color: const Color(0xFFE53935),
                  glowing: winnerGlow && _redWins,
                  buzzFraction: _redWins ? _ctrl.value : 0,
                ),
                Column(children: [
                  const Icon(Icons.compare_arrows_rounded,
                      color: Colors.white24, size: 28),
                  const SizedBox(height: 4),
                  Text('vs',
                      style: GoogleFonts.alexandria(
                          color: Colors.white24, fontSize: 11)),
                ]),
                _TeamBlock(
                  name: 'الأزرق',
                  color: const Color(0xFF1E88E5),
                  glowing: winnerGlow && !_redWins,
                  buzzFraction: !_redWins ? _ctrl.value : 0,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (winnerGlow)
              Text(
                _redWins
                    ? '🔴 الفريق الأحمر يجاوب!'
                    : '🔵 الفريق الأزرق يجاوب!',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.alexandria(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ).animate().fadeIn(duration: 300.ms),
          ],
        );
      },
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String name;
  final Color color;
  final bool glowing;
  final double buzzFraction;

  const _TeamBlock(
      {required this.name,
      required this.color,
      required this.glowing,
      required this.buzzFraction});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: glowing ? color.withOpacity(0.25) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: glowing ? color : color.withOpacity(0.25),
            width: glowing ? 2 : 1),
        boxShadow: glowing
            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20)]
            : [],
      ),
      child: Column(
        children: [
          CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Text(name[0],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Text(name,
              style: GoogleFonts.alexandria(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Icon(
            glowing
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: glowing ? color : Colors.white24,
            size: 28,
          ),
        ],
      ),
    );
  }
}

/// Animated pressure timer for R3
class _PressureTimerAnimation extends StatefulWidget {
  const _PressureTimerAnimation();

  @override
  State<_PressureTimerAnimation> createState() =>
      _PressureTimerAnimationState();
}

class _PressureTimerAnimationState extends State<_PressureTimerAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static const _contestants = ['مرقس', 'جورج', 'ماريا'];
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              setState(() => _idx = (_idx + 1) % _contestants.length);
              _ctrl.forward(from: 0);
            }
          });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final remaining = (60 * (1 - _ctrl.value)).round();
        final danger = remaining < 20;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer arc
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: _ArcPainter(
                      fraction: 1 - _ctrl.value,
                      color: danger
                          ? const Color(0xFFE53935)
                          : const Color(0xFFC62828),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$remaining',
                            style: GoogleFonts.alexandria(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: danger
                                    ? const Color(0xFFE53935)
                                    : Colors.white)),
                        Text('ثانية',
                            style: GoogleFonts.alexandria(
                                fontSize: 9, color: Colors.white54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Contestant name
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_idx),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFC62828).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_rounded,
                        color: Color(0xFFC62828), size: 16),
                    const SizedBox(width: 8),
                    Text(_contestants[_idx],
                        style: GoogleFonts.alexandria(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double fraction;
  final Color color;
  const _ArcPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..color = const Color(0xFF1E2A45)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.fraction != fraction || old.color != color;
}

/// Celebration animation for the demo page
class _CelebrationAnimation extends StatelessWidget {
  const _CelebrationAnimation();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events_rounded,
                size: 80, color: Color(0xFFFF6B2B))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.15, 1.15),
                duration: 1500.ms,
                curve: Curves.easeInOut),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Icon(Icons.star_rounded,
                    color: const Color(0xFFFF6B2B), size: 22)
                .animate(
                    delay: Duration(milliseconds: i * 120),
                    onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.3, end: 0, duration: 400.ms),
          ),
        ),
      ],
    );
  }
}

// ── Shared rule row ───────────────────────────────────────────────────────────

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _RuleRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.alexandria(
                color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ],
    );
  }
}
