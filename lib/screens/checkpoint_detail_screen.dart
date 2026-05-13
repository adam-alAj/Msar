import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/checkpoint.dart';
import '../models/checkpoint_status.dart';
import '../services/checkpoint_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../utils/localization.dart';
import '../widgets/direction_status_card.dart';
import '../widgets/skeleton_loaders.dart';
import 'vote_screen.dart';

class CheckpointDetailScreen extends StatefulWidget {
  final Checkpoint checkpoint;

  const CheckpointDetailScreen({Key? key, required this.checkpoint}) : super(key: key);

  @override
  State<CheckpointDetailScreen> createState() => _CheckpointDetailScreenState();
}

class _CheckpointDetailScreenState extends State<CheckpointDetailScreen> {
  final CheckpointService _checkpointService = CheckpointService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();

  late Stream<CheckpointStatus> _statusStream;

  @override
  void initState() {
    super.initState();
    _statusStream = _checkpointService.watchCheckpointStatus(widget.checkpoint.id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        color: colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(colorScheme),
              Expanded(
                child: StreamBuilder<CheckpointStatus>(
                  stream: _statusStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingState();
                    if (snapshot.hasError) return _buildErrorState(snapshot.error, colorScheme);
                    if (!snapshot.hasData) return _buildNoDataState(colorScheme);
                    return _buildContent(context, snapshot.data!, colorScheme);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildVoteButton(colorScheme),
    );
  }

  Widget _buildModernAppBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
              color: colorScheme.primary,
              iconSize: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.checkpoint.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(children: [
                  Icon(Icons.place, size: 12, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(widget.checkpoint.region, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('مباشر', style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const CheckpointDetailSkeleton();
  }

  Widget _buildErrorState(Object? error, ColorScheme colorScheme) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 64, color: colorScheme.error),
        const SizedBox(height: 16),
        Text('حدث خطأ في تحميل البيانات', style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => setState(() { _statusStream = _checkpointService.watchCheckpointStatus(widget.checkpoint.id); }),
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
        ),
      ]),
    );
  }

  Widget _buildNoDataState(ColorScheme colorScheme) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.info_outline, size: 64, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text('لا توجد بيانات حالياً', style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: () => _handleVote(context), icon: const Icon(Icons.how_to_vote), label: const Text('كن أول من يصوّت')),
      ]),
    );
  }

  Widget _buildContent(BuildContext context, CheckpointStatus status, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroStatsCard(status, colorScheme),
          const SizedBox(height: 20),
          _buildSectionHeader('الحالة الحالية', colorScheme),
          const SizedBox(height: 12),
          DirectionStatusCard(title: AppLocalizations.tr('entrance'), status: status.entrance, icon: Icons.arrow_forward, onVotePressed: () => _handleVote(context)),
          const SizedBox(height: 16),
          DirectionStatusCard(title: AppLocalizations.tr('exit'), status: status.exit, icon: Icons.arrow_back, onVotePressed: () => _handleVote(context)),
          const SizedBox(height: 20),
          _buildVotingInfoCard(colorScheme),
          const SizedBox(height: 20),
          _buildLastUpdateInfo(status, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeroStatsCard(CheckpointStatus status, ColorScheme colorScheme) {
    final totalVotes = status.entrance.totalVotes + status.exit.totalVotes;
    final lastUpdate = status.entrance.lastUpdated.isAfter(status.exit.lastUpdated) ? status.entrance.lastUpdated : status.exit.lastUpdated;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('إجمالي التصويتات', totalVotes.toString(), Icons.how_to_vote_outlined, colorScheme),
          Container(width: 1, height: 40, color: colorScheme.onPrimary.withOpacity(0.3)),
          _buildStatItem('آخر تحديث', _formatTimeAgo(lastUpdate), Icons.update_rounded, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Column(children: [
      Icon(icon, color: colorScheme.onPrimary, size: 22),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onPrimary)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onPrimary.withOpacity(0.8))),
    ]);
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Row(children: [
      Container(width: 4, height: 24, decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
    ]);
  }

  Widget _buildVotingInfoCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.how_to_vote, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text('معلومات التصويت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary)),
        ]),
        const SizedBox(height: 12),
        Text(
          '• يمكنك التصويت من أي مكان\n• الحالة تعتمد على نسبة التصويتات الأعلى\n• صوتك يساعد الآخرين في معرفة حالة الحاجز\n• تُحتسب أصوات آخر ${AppLocalizations.tr('vote_window_minutes')} دقيقة فقط',
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5),
        ),
      ]),
    );
  }

  Widget _buildLastUpdateInfo(CheckpointStatus status, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.timer_outlined, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('للداخل: ${_formatTimeAgo(status.entrance.lastUpdated)}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ]),
        Row(children: [
          Icon(Icons.timer_outlined, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('للخارج: ${_formatTimeAgo(status.exit.lastUpdated)}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ]),
      ]),
    );
  }

  Widget _buildVoteButton(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: ElevatedButton(
        onPressed: () => _handleVote(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.how_to_vote, size: 22), SizedBox(width: 12), Text('تصويت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Future<void> _handleVote(BuildContext context) async {
    if (!mounted) return;
    Position? position;
    try { position = await _locationService.getCurrentPosition(); } catch (_) {}

    await Navigator.push(context, MaterialPageRoute(builder: (_) => VoteScreen(checkpoint: widget.checkpoint, userPosition: position)));
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
  }
}
