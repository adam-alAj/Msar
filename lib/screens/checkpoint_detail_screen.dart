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
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _statusStream = _checkpointService.watchCheckpointStatus(widget.checkpoint.id);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkAdmin();
  }

  void _checkAdmin() async {
    final admin = await _authService.isAdmin();
    if (mounted) setState(() => _isAdmin = admin);
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
          if (_isAdmin) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.more_vert_rounded, size: 18, color: colorScheme.onSurface),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              offset: const Offset(0, 40),
              onSelected: (value) {
                if (value == 'edit') _showEditCheckpointDialog();
                if (value == 'delete') _showDeleteConfirmation();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: Colors.blue.shade600), const SizedBox(width: 10), const Text('تعديل الحاجز', style: TextStyle(fontWeight: FontWeight.w500))])),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red.shade600), const SizedBox(width: 10), Text('حذف الحاجز', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red.shade600))])),
              ],
            ),
          ],
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
          // Admin override section
          if (_isAdmin) ...[
            const SizedBox(height: 20),
            _buildAdminOverrideSection(colorScheme),
          ],
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

  // ─── ADMIN OVERRIDE ──────────────────────────────────────────────────────

  Widget _buildAdminOverrideSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.withOpacity(0.06), Colors.orange.withOpacity(0.03)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.orange.shade800),
              const SizedBox(width: 6),
              Text('تغيير الحالة يدوياً', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange.shade800)),
            ]),
          ),
          const SizedBox(height: 16),
          // Entrance override
          _buildOverrideRow('للداخل', 'ENTRANCE', AppIcons.arrowForward, const Color(0xFF26A69A), colorScheme),
          const SizedBox(height: 12),
          // Exit override
          _buildOverrideRow('للخارج', 'EXIT', AppIcons.arrowBack, const Color(0xFF7E57C2), colorScheme),
        ],
      ),
    );
  }

  Widget _buildOverrideRow(String label, String direction, IconData dirIcon, Color dirColor, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(dirIcon, size: 14, color: dirColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dirColor)),
        ]),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusChip('سالك', 'OPEN', direction, const Color(0xFF4CAF50), Icons.check_circle_rounded),
            const SizedBox(width: 8),
            _buildStatusChip('أزمة', 'CROWDED', direction, const Color(0xFFFFA726), Icons.warning_rounded),
            const SizedBox(width: 8),
            _buildStatusChip('مغلق', 'CLOSED', direction, const Color(0xFFE53935), Icons.cancel_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String status, String direction, Color color, IconData icon) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _overrideStatus(direction, status),
          splashColor: color.withOpacity(0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _overrideStatus(String direction, String status) async {
    final dirLabel = direction == 'ENTRANCE' ? 'للداخل' : 'للخارج';
    final statusLabel = status == 'OPEN' ? 'سالك' : status == 'CROWDED' ? 'أزمة' : 'مغلق';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.admin_panel_settings_rounded, size: 22, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('تأكيد التغيير', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: Text('تغيير حالة "$dirLabel" إلى "$statusLabel"؟', style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _checkpointService.overrideStatus(widget.checkpoint.id, direction, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('تم تحديث "$dirLabel" → "$statusLabel"'),
          ]),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('فشل التحديث: $e')),
          ]),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
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

  // ─── ADMIN EDIT/DELETE ────────────────────────────────────────────────────

  void _showEditCheckpointDialog() {
    final nameController = TextEditingController(text: widget.checkpoint.name);
    final regionController = TextEditingController(text: widget.checkpoint.region);
    final latController = TextEditingController(text: widget.checkpoint.latitude.toString());
    final lngController = TextEditingController(text: widget.checkpoint.longitude.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_rounded, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          const Text('تعديل الحاجز', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'اسم الحاجز',
                prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: regionController,
              decoration: InputDecoration(
                labelText: 'المنطقة',
                prefixIcon: const Icon(Icons.map_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: latController,
                  decoration: InputDecoration(
                    labelText: 'خط العرض',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: lngController,
                  decoration: InputDecoration(
                    labelText: 'خط الطول',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ]),
          ]),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final updated = Checkpoint(
                    id: widget.checkpoint.id,
                    name: nameController.text.trim(),
                    region: regionController.text.trim(),
                    latitude: double.tryParse(latController.text) ?? widget.checkpoint.latitude,
                    longitude: double.tryParse(lngController.text) ?? widget.checkpoint.longitude,
                    createdBy: widget.checkpoint.createdBy,
                    createdAt: widget.checkpoint.createdAt,
                  );
                  try {
                    await _checkpointService.updateCheckpoint(updated);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('تم تعديل الحاجز بنجاح')]),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ));
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ فشل التعديل: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_forever_rounded, size: 22, color: Colors.red),
          ),
          const SizedBox(width: 10),
          const Text('حذف الحاجز', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('سيتم حذف "${widget.checkpoint.name}" نهائياً.\nلا يمكن التراجع عن هذا الإجراء.', style: const TextStyle(fontSize: 13, height: 1.5))),
            ]),
          ),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        actions: [
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  try {
                    await _checkpointService.deleteCheckpoint(widget.checkpoint.id);
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('تم حذف الحاجز')]),
                        backgroundColor: Colors.green.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ));
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ فشل الحذف: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('حذف نهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ],
      ),
    );
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
