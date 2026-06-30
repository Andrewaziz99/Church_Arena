import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';
import '../constants/app_colors.dart';
import '../../services/arduino/arduino_service.dart';
import '../../services/sync/supabase_sync_service.dart';

class AppNavSidebar extends StatefulWidget {
  final String activeRoute;
  const AppNavSidebar({super.key, required this.activeRoute});

  @override
  State<AppNavSidebar> createState() => _AppNavSidebarState();
}

class _AppNavSidebarState extends State<AppNavSidebar> {
  Timer? _clockTimer;
  Timer? _pollTimer;

  String _time = '';
  bool _arduinoOk = false;
  bool _syncOk = false;
  bool _onlineOk = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _poll();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _pollTimer  = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _time = DateFormat('HH:mm').format(DateTime.now()));
  }

  Future<void> _poll() async {
    final arduino = GetIt.I<ArduinoService>().isConnected;
    // fetchTeams is lightweight (returns cached data when offline quickly)
    await SupabaseSyncService.instance.fetchTeams();
    final online = SupabaseSyncService.instance.isOnline;
    if (mounted) {
      setState(() {
        _arduinoOk = arduino;
        _onlineOk  = online;
        _syncOk    = online; // sync = online for now
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border:
            Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // ── Back button ─────────────────────────────────────────
          GestureDetector(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/'),
            child: Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(height: 4),
                  Text('BACK',
                      style: GoogleFonts.alexandria(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // ── Nav items ───────────────────────────────────────────
          _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'HOME',
              route: '/',
              activeRoute: widget.activeRoute),
          _NavItem(
              icon: Icons.emoji_events_rounded,
              label: 'COMP',
              route: '/scoreboard',
              activeRoute: widget.activeRoute),
          _NavItem(
              icon: Icons.groups_rounded,
              label: 'TEAMS',
              route: '/teams',
              activeRoute: widget.activeRoute),
          _NavItem(
              icon: Icons.quiz_rounded,
              label: 'QUIZ',
              route: '/questions',
              activeRoute: widget.activeRoute),
          _NavItem(
              icon: Icons.live_tv_rounded,
              label: 'LIVE',
              route: '/game',
              activeRoute: widget.activeRoute),

          const Spacer(),

          // ── Status cluster ──────────────────────────────────────
          _StatusCluster(
            arduinoOk: _arduinoOk,
            syncOk: _syncOk,
            onlineOk: _onlineOk,
            time: _time,
            roomId: appRoomId,
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.border),

          _NavItem(
              icon: Icons.settings_rounded,
              label: 'SETUP',
              route: '/settings',
              activeRoute: widget.activeRoute),
          // ── Exit button ──────────────────────────────────────
          GestureDetector(
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Exit App?'),
                  content: const Text('Close Church Arena?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) await windowManager.close();
            },
            child: Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.power_settings_new_rounded,
                      size: 20, color: AppColors.error),
                  const SizedBox(height: 4),
                  Text('EXIT',
                      style: GoogleFonts.alexandria(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Status cluster ─────────────────────────────────────────────────────────────

class _StatusCluster extends StatelessWidget {
  final bool arduinoOk;
  final bool syncOk;
  final bool onlineOk;
  final String time;
  final String roomId;

  const _StatusCluster({
    required this.arduinoOk,
    required this.syncOk,
    required this.onlineOk,
    required this.time,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          // Three status icons side by side
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatusDot(
                icon: Icons.bolt_rounded,
                active: arduinoOk,
                tooltip: arduinoOk ? 'Buzzer connected' : 'Buzzer offline',
              ),
              _StatusDot(
                icon: Icons.sync_rounded,
                active: syncOk,
                tooltip: syncOk ? 'Sync active' : 'Sync offline',
              ),
              _StatusDot(
                icon: Icons.wifi_rounded,
                active: onlineOk,
                tooltip: onlineOk ? 'Online' : 'Offline',
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Room ID pill
          Tooltip(
            message: 'Room: $roomId',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.blueContent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.blueContent.withOpacity(0.3)),
              ),
              child: Text(
                roomId,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alexandria(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueContent,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Clock pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orangeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              time,
              style: GoogleFonts.alexandria(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String tooltip;

  const _StatusDot({
    required this.icon,
    required this.active,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 16,
        color: active ? AppColors.greenSuccess : AppColors.border,
      ),
    );
  }
}

// ── Nav item ───────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String activeRoute;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeRoute == route;

    return GestureDetector(
      onTap: () => context.go(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.orangeBg.withOpacity(0.25)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color:
                  isActive ? AppColors.orangeDark : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? AppColors.orangeDark
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.alexandria(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? AppColors.orangeDark
                    : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
