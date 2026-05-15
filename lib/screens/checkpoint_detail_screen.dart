import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/checkpoint.dart';
import '../models/checkpoint_status.dart';
import '../services/checkpoint_service.dart';
import '../services/favorites_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../utils/app_icons.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/comments_section.dart';
import 'vote_screen.dart';

class CheckpointDetailScreen extends StatefulWidget {
  final Checkpoint checkpoint;

  const CheckpointDetailScreen({Key? key, required this.checkpoint}) : super(key: key);

  @override
  State<CheckpointDetailScreen> createState() => _CheckpointDetailScreenState();
}

class _CheckpointDetailScreenState extends State<CheckpointDetailScreen>
    with SingleTickerProviderStateMixin {
  final CheckpointService _checkpointService = CheckpointService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();

  late Stream<CheckpointStatus> _statusStream;
  late AnimationController _pulseController;
  final GlobalKey<CommentsSectionState> _commentsKey = GlobalKey<CommentsSectionState>();

  @override
  void initState() {
    super.initState();
    _statusStream = _checkpointService.watchCheckpointStatus(widget.checkpoint.id);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(colorScheme),
            Expanded(
              child: StreamBuilder<CheckpointStatus>(
                stream: _statusStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
                  if (snapshot.hasError) return _buildErrorState(snapshot.error, colorScheme);
                  if (!snapshot.hasData) return _buildNoDataState(colorScheme);
                  return _buildContent(snapshot.data!, colorScheme);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildVoteButton(colorScheme),
    );
  }

  // ─── APP BAR ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Directionality(textDirection: TextDirection.ltr, child: Icon(AppIcons.arrowForward, size: 18, color: colorScheme.onSurface)),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.checkpoint.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface, letterSpacing: -0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(AppIcons.place, size: 12, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(widget.checkpoint.region, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ]),
              ],
            ),
          ),
          // Live badge with pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final opacity = 0.6 + (_pulseController.value * 0.4);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(opacity),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(opacity * 0.5), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('مباشر', style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w700)),
                ]),
              );
            },
          ),
          const SizedBox(width: 8),
          // Favorite heart toggle
          ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesService().favorites,
            builder: (context, favs, _) {
              final isFav = favs.contains(widget.checkpoint.id);
              return GestureDetector(
                onTap: () => FavoritesService().toggle(widget.checkpoint.id),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFav),
                    size: 24,
                    color: isFav ? Colors.red : colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── CONTENT ────────────────────────────────────────────────────────────────

  Widget _buildContent(CheckpointStatus status, ColorScheme colorScheme) {
    final totalVotes = status.entrance.totalVotes + status.exit.totalVotes;
    final lastUpdate = status.entrance.lastUpdated.isAfter(status.exit.lastUpdated)
        ? status.entrance.lastUpdated
        : status.exit.lastUpdated;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Stats row
          _buildStatsRow(totalVotes, lastUpdate, colorScheme),
          const SizedBox(height: 20),
          // Direction cards side by side
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _buildDirectionCard(
                  title: AppLocalizations.tr('entrance'),
                  icon: AppIcons.arrowForward,
                  status: status.entrance,
                  accentColor: const Color(0xFF26A69A), // teal for inbound
                  colorScheme: colorScheme,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildDirectionCard(
                  title: AppLocalizations.tr('exit'),
                  icon: AppIcons.arrowBack,
                  status: status.exit,
                  accentColor: const Color(0xFF7E57C2), // purple for outbound
                  colorScheme: colorScheme,
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Info section
          _buildInfoSection(colorScheme),
          const SizedBox(height: 20),
          // Comments feed
          CommentsSection(key: _commentsKey, checkpointId: widget.checkpoint.id),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── STATS ROW ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow(int totalVotes, DateTime lastUpdate, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary.withOpacity(0.15), colorScheme.primary.withOpacity(0.05)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Total votes
          Icon(AppIcons.voteOutlined, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text('$totalVotes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colorScheme.primary)),
          const SizedBox(width: 4),
          Text('صوت', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const Spacer(),
          // Last update
          Icon(AppIcons.clock, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(_formatTimeAgo(lastUpdate), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── DIRECTION CARD ─────────────────────────────────────────────────────────

  Widget _buildDirectionCard({
    required String title,
    required IconData icon,
    required DirectionStatus status,
    required Color accentColor,
    required ColorScheme colorScheme,
  }) {
    final statusColor = AppConstants.statusColorFor(context, status.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Direction label
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: accentColor),
            ),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          ]),
          const SizedBox(height: 12),

          // Status indicator — the hero element
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
            ),
            child: Column(children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Icon(
                  status.status == 'OPEN' ? AppIcons.checkpointOpen
                      : status.status == 'CROWDED' ? AppIcons.checkpointCrowded
                      : AppIcons.checkpointClosed,
                  size: 22,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status.localizedStatus,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: statusColor),
              ),
            ]),
          ),
          const SizedBox(height: 10),

          // Progress bar
          if (status.totalVotes > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.percentage / 100,
                backgroundColor: statusColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(statusColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Meta
          Text(
            '${status.totalVotes} ${AppLocalizations.tr('votes')}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(AppIcons.clock, size: 10, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 3),
            Text(_formatTimeAgo(status.lastUpdated), style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
          ]),
        ],
      ),
    );
  }

  // ─── INFO SECTION ───────────────────────────────────────────────────────────

  Widget _buildInfoSection(ColorScheme colorScheme) {
    final items = [
      (AppIcons.globe, 'يمكنك التصويت من أي مكان'),
      (AppIcons.voteOutlined, 'الحالة تعتمد على نسبة التصويتات الأعلى'),
      (AppIcons.clock, 'تُحتسب أصوات آخر ${AppLocalizations.tr('vote_window_minutes')} دقيقة فقط'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(AppIcons.info, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text('معلومات التصويت', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.primary)),
          ]),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$1, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(item.$2, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─── VOTE BUTTON ────────────────────────────────────────────────────────────

  Widget _buildVoteButton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 56),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2))),
      ),
      child: ElevatedButton(
        onPressed: () => _handleVote(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(AppIcons.vote, size: 20),
          SizedBox(width: 10),
          Text('تصويت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // ─── STATES ─────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() => const CheckpointDetailSkeleton();

  Widget _buildErrorState(Object? error, ColorScheme colorScheme) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(AppIcons.error, size: 48, color: colorScheme.error),
        const SizedBox(height: 16),
        Text('فشل تحميل البيانات', style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => setState(() { _statusStream = _checkpointService.watchCheckpointStatus(widget.checkpoint.id); }),
          icon: const Icon(AppIcons.refresh, size: 18),
          label: const Text('إعادة المحاولة'),
        ),
      ]),
    );
  }

  Widget _buildNoDataState(ColorScheme colorScheme) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(AppIcons.info, size: 48, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text('لا توجد بيانات حالياً', style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: () => _handleVote(context), icon: const Icon(AppIcons.vote, size: 18), label: const Text('كن أول من يصوّت')),
      ]),
    );
  }

  // ─── NAVIGATION ─────────────────────────────────────────────────────────────

  Future<void> _handleVote(BuildContext context) async {
    if (!mounted) return;
    Position? position;
    try { position = await _locationService.getCurrentPosition(); } catch (_) {}

    final voted = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => VoteScreen(checkpoint: widget.checkpoint, userPosition: position)));
    if (voted == true && mounted) {
      _commentsKey.currentState?.refresh();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [Directionality(textDirection: TextDirection.ltr, child: Icon(AppIcons.checkpointOpen, color: Colors.white)), SizedBox(width: 12), Expanded(child: Text('✓ تم تسجيل تصويتك بنجاح! شكراً لمشاركتك'))]),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
  }
}
