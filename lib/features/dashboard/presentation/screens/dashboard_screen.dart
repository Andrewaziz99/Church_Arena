import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/database/database_seeder.dart';
import '../../../../core/widgets/app_nav_sidebar.dart';
import '../../../../injection/injection.dart';
import '../../../../services/arduino/arduino_service.dart';
import '../../../../services/sync/connection_log_service.dart';
import '../../../../services/sync/supabase_sync_service.dart';
import '../../../questions/presentation/bloc/questions_bloc.dart';
import '../../../teams/presentation/bloc/teams_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.orangeBg,
      body: Row(
        children: [
          const AppNavSidebar(activeRoute: '/'),
          const Expanded(child: _DashboardContent()),
        ],
      ),
    );
  }
}

// ── Live dashboard content ────────────────────────────────────────────────────

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  Timer? _pollingTimer;
  Timer? _clockTimer;

  bool _isOnline = false;
  int? _latencyMs;
  bool _arduinoConnected = false;
  Duration _sessionTime = Duration.zero;
  final DateTime _sessionStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _poll(); // immediate first check
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _sessionTime = DateTime.now().difference(_sessionStart));
      }
    });
  }

  Future<void> _poll() async {
    final arduinoConnected = GetIt.I<ArduinoService>().isConnected;

    // Ping Supabase and measure round-trip time
    final sw = Stopwatch()..start();
    await SupabaseSyncService.instance.fetchTeams();
    sw.stop();
    final online = SupabaseSyncService.instance.isOnline;

    if (mounted) {
      setState(() {
        _arduinoConnected = arduinoConnected;
        _isOnline = online;
        _latencyMs = online ? sw.elapsedMilliseconds : null;
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeamsBloc, TeamsState>(
      builder: (context, teamsState) {
        return BlocBuilder<QuestionsBloc, QuestionsState>(
          builder: (context, questionsState) {
            final teamCount = teamsState is TeamsLoaded
                ? '${teamsState.teams.length}'
                : '—';
            final qCount = questionsState is QuestionsLoaded
                ? '${questionsState.questions.length}'
                : '—';
            final latencyLabel = _latencyMs == null
                ? '—'
                : '${_latencyMs}ms';
            final syncLabel = _isOnline ? 'ONLINE' : 'OFFLINE';
            final syncColor =
                _isOnline ? AppColors.greenSuccess : const Color(0xFFD32F2F);
            final buzzerLabel = _arduinoConnected ? 'YES' : 'NO';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event info
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.greenSuccess.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: AppColors.greenSuccess),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                        color: AppColors.greenSuccess,
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ACTIVE EVENT',
                                    style: GoogleFonts.alexandria(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.greenSuccess,
                                        letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'مهرجان\nالعباقرة',
                              style: GoogleFonts.alexandria(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.3),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const _PillChip(
                                    icon: Icons.place_rounded,
                                    label: 'Main Hall'),
                                const SizedBox(width: 10),
                                _PillChip(
                                  icon: Icons.podcasts_rounded,
                                  label: _arduinoConnected
                                      ? 'Buzzer ✓'
                                      : 'No Buzzer',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Stats grid
                      Expanded(
                        flex: 3,
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                          children: [
                            _StatCard(
                              icon: Icons.groups_rounded,
                              label: 'TEAMS JOINED',
                              value: teamCount,
                              accentColor: AppColors.blueContent
                                  .withOpacity(teamCount != '—' ? 0 : 0),
                            ),
                            _StatCard(
                              icon: Icons.quiz_rounded,
                              label: 'QUESTIONS POOL',
                              value: qCount,
                              valueColor: AppColors.blueContent,
                            ),
                            _StatCard(
                              icon: _isOnline
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_off_rounded,
                              label: 'GLOBAL SYNC',
                              value: syncLabel,
                              accentColor: syncColor,
                              isAccent: true,
                            ),
                            _StatCard(
                              icon: Icons.speed_rounded,
                              label: 'LATENCY',
                              value: latencyLabel,
                              valueColor: _latencyMs == null
                                  ? null
                                  : _latencyMs! < 200
                                      ? AppColors.greenSuccess
                                      : _latencyMs! < 500
                                          ? const Color(0xFFF57C00)
                                          : const Color(0xFFD32F2F),
                            ),
                            _StatCard(
                              icon: Icons.touch_app_rounded,
                              label: 'BUZZERS ACTIVE',
                              value: buzzerLabel,
                              valueColor: _arduinoConnected
                                  ? AppColors.greenSuccess
                                  : AppColors.textSecondary,
                            ),
                            _StatCard(
                              icon: Icons.timer_rounded,
                              label: 'SESSION TIME',
                              value: _formatDuration(_sessionTime),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Connection log ────────────────────────────────
                  const _ConnectionLog(),

                  const SizedBox(height: 32),

                  // ── Production actions ────────────────────────────
                  Text(
                    '⚡  PRODUCTION ACTIONS',
                    style: GoogleFonts.alexandria(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orangeDark,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ActionButton(
                        label: 'START FESTIVAL',
                        icon: Icons.play_arrow_rounded,
                        primary: true,
                        onTap: () =>
                            context.go('/game/setup?category='),
                      ),
                      _ActionButton(
                        label: 'RESUME SESSION',
                        icon: Icons.play_circle_outline_rounded,
                        onTap: () => context.go('/game'),
                      ),
                      _ActionButton(
                        label: 'NEW QUIZ',
                        icon: Icons.add_rounded,
                        onTap: () => context.go('/questions'),
                      ),
                      _ActionButton(
                        label: 'SCOREBOARD',
                        icon: Icons.leaderboard_rounded,
                        onTap: () => context.go('/scoreboard'),
                      ),
                      _ActionButton(
                        label: 'SEED DATA',
                        icon: Icons.dataset_rounded,
                        onTap: () => _seedData(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Grade group banners ───────────────────────────
                  Text(
                    '🎯  GRADE GROUPS',
                    style: GoogleFonts.alexandria(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orangeDark,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      _BannerRow(
                          assetPath: 'assets/images/Banners/1&2.jpeg',
                          label: 'اولى وثانية'),
                      const SizedBox(height: 10),
                      _BannerRow(
                          assetPath: 'assets/images/Banners/3&4.jpeg',
                          label: 'ثالثة ورابعة'),
                      const SizedBox(height: 10),
                      _BannerRow(
                          assetPath: 'assets/images/Banners/5&6.jpeg',
                          label: 'خامسة وسادسة'),
                    ],
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Connection log ─────────────────────────────────────────────────────────────

class _ConnectionLog extends StatefulWidget {
  const _ConnectionLog();

  @override
  State<_ConnectionLog> createState() => _ConnectionLogState();
}

class _ConnectionLogState extends State<_ConnectionLog> {
  final _svc = ConnectionLogService.instance;
  List<ConnectionLogEntry> _entries = [];
  StreamSubscription<List<ConnectionLogEntry>>? _sub;

  @override
  void initState() {
    super.initState();
    _entries = List.of(_svc.entries);
    _sub = _svc.stream.listen((entries) {
      if (mounted) setState(() => _entries = List.of(entries));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.success: return AppColors.greenSuccess;
      case LogLevel.warning: return const Color(0xFFF57C00);
      case LogLevel.error:   return const Color(0xFFD32F2F);
      case LogLevel.info:    return AppColors.textSecondary;
    }
  }

  IconData _levelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.success: return Icons.check_circle_outline_rounded;
      case LogLevel.warning: return Icons.warning_amber_rounded;
      case LogLevel.error:   return Icons.error_outline_rounded;
      case LogLevel.info:    return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '🔌  CONNECTION LOG',
              style: GoogleFonts.alexandria(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orangeDark,
                  letterSpacing: 1),
            ),
            const Spacer(),
            if (_entries.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _svc.clear();
                  setState(() => _entries = []);
                },
                child: Text(
                  'CLEAR',
                  style: GoogleFonts.alexandria(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: _entries.isEmpty
              ? Center(
                  child: Text(
                    'No events yet',
                    style: GoogleFonts.alexandria(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: _entries.length,
                  itemBuilder: (context, i) {
                    final e = _entries[i];
                    final color = _levelColor(e.level);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 3),
                      child: Row(
                        children: [
                          Icon(_levelIcon(e.level), size: 13, color: color),
                          const SizedBox(width: 6),
                          Text(
                            e.timeLabel,
                            style: GoogleFonts.alexandria(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ]),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.message,
                              style: GoogleFonts.alexandria(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: i == 0
                                      ? FontWeight.w700
                                      : FontWeight.w400),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Pill chip ──────────────────────────────────────────────────────────────────

class _PillChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PillChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.alexandria(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isAccent;
  final Color? accentColor;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isAccent = false,
    this.accentColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isAccent
        ? (accentColor ?? AppColors.greenSuccess)
        : AppColors.surface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: isAccent ? Colors.white : AppColors.blueContent),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.alexandria(
              fontSize: value.length > 6 ? 16 : 22,
              fontWeight: FontWeight.w900,
              color: isAccent
                  ? Colors.white
                  : (valueColor ?? AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.alexandria(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isAccent ? Colors.white70 : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seed helper ────────────────────────────────────────────────────────────────

Future<void> _seedData(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(
        content: Text('جارٍ إضافة الأسئلة التجريبية…'),
        duration: Duration(seconds: 2)),
  );
  await DatabaseSeeder.seed(getIt<DatabaseHelper>());
  if (context.mounted) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('✅  تمت إضافة ٣٦ سؤالاً في ٣ فئات'),
        backgroundColor: AppColors.greenSuccess,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.primary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: primary ? AppColors.blueContent : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: primary
              ? null
              : Border.all(color: AppColors.border, width: 1.5),
          boxShadow: primary
              ? [
                  BoxShadow(
                      color: AppColors.blueContent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: primary ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.alexandria(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primary ? Colors.white : AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner row ─────────────────────────────────────────────────────────────────

class _BannerRow extends StatefulWidget {
  final String assetPath;
  final String label;
  const _BannerRow({required this.assetPath, required this.label});

  @override
  State<_BannerRow> createState() => _BannerRowState();
}

class _BannerRowState extends State<_BannerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context
            .go('/game/setup?category=${Uri.encodeComponent(widget.label)}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? AppColors.blueContent
                  : Colors.white.withOpacity(0.3),
              width: _hovered ? 2.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: AppColors.blueContent.withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                AnimatedScale(
                  scale: _hovered ? 1.03 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Image.asset(widget.assetPath,
                      width: double.infinity, fit: BoxFit.fitWidth),
                ),
                Container(
                    color: Colors.black
                        .withOpacity(_hovered ? 0.2 : 0.35)),
                Positioned(
                  right: 28,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.alexandria(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
                if (_hovered)
                  Positioned(
                    left: 28,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                            color: AppColors.blueContent,
                            borderRadius: BorderRadius.circular(30)),
                        child: Text(
                          'ابدأ اللعبة',
                          style: GoogleFonts.alexandria(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
