import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/checkpoint.dart';
import '../models/vote.dart';
import '../providers/governorate_provider.dart';
import '../services/checkpoint_service.dart';
import '../services/auth_service.dart';
import '../services/haptic_service.dart';
import '../utils/constants.dart';
import '../widgets/skeleton_loaders.dart';

class VoteScreen extends StatefulWidget {
  final Checkpoint checkpoint;
  final Position? userPosition;

  const VoteScreen({Key? key, required this.checkpoint, this.userPosition}) : super(key: key);

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final CheckpointService _checkpointService = CheckpointService();
  final AuthService _authService = AuthService();

  String? _entranceStatus;
  String? _exitStatus;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasVotedOnce = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: AppBar(
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.onPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.how_to_vote, color: colorScheme.onPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Text('تسجيل تصويت جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onPrimary)),
            ]),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: colorScheme.onPrimary), onPressed: () => Navigator.pop(context)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Checkpoint Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.location_on, size: 32, color: colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Text(widget.checkpoint.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gps_fixed, size: 12, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        context.watch<GovernorateProvider>().currentRegionAr ?? widget.checkpoint.region,
                        style: TextStyle(fontSize: 13, color: colorScheme.primary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.info_outline, size: 18, color: colorScheme.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يمكنك التصويت للحاجز من أي مكان. صوتك يساعد المجتمع في معرفة الحالة الحقيقية.',
                        style: TextStyle(fontSize: 12, color: colorScheme.onTertiaryContainer, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                ),
              ]),
            ),

            // Entrance Vote
            _buildDirectionVoteCard(
              title: 'للداخل',
              subtitle: 'من الطريق الخارجة دخولا بالمنطقة',
              icon: Icons.arrow_forward,
              selectedStatus: _entranceStatus,
              onStatusSelected: (s) { HapticService.voteSelected(context, s); setState(() { _entranceStatus = s; _hasVotedOnce = true; }); },
            ),
            const SizedBox(height: 16),

            // Exit Vote
            _buildDirectionVoteCard(
              title: 'للخارج',
              subtitle: 'خارج من المنطقة باتجاه شارع رئيسي أو خط سريع',
              icon: Icons.arrow_back,
              selectedStatus: _exitStatus,
              onStatusSelected: (s) { HapticService.voteSelected(context, s); setState(() { _exitStatus = s; _hasVotedOnce = true; }); },
            ),
            const SizedBox(height: 24),

            // Comment
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.comment, size: 20, color: colorScheme.onTertiaryContainer)),
                  const SizedBox(width: 12),
                  Text('تعليق إضافي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                    child: Text('اختياري', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commentController,
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'مثال: الحاجز مزدحم جداً بسبب التفتيش الدقيق...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                    filled: true,
                    fillColor: colorScheme.surface,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 32),

            // Submit
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || !_hasVotedOnce ? null : _submitVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
                ),
                child: _isSubmitting
                    ? SkeletonShimmer(child: Container(height: 22, width: 120, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(11))))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.send_rounded, size: 22),
                        const SizedBox(width: 12),
                        const Text('إرسال التصويت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ]),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionVoteCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? selectedStatus,
    required Function(String) onStatusSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusOptions = [
      {'value': 'OPEN', 'label': 'سالك', 'icon': Icons.check_circle},
      {'value': 'CROWDED', 'label': 'أزمة', 'icon': Icons.warning_amber},
      {'value': 'CLOSED', 'label': 'مغلق', 'icon': Icons.block},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ])),
          if (selectedStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppConstants.statusColorFor(context, selectedStatus).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_localizedStatus(selectedStatus), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.statusColorFor(context, selectedStatus))),
            ),
        ]),
        const SizedBox(height: 20),
        Divider(height: 1, color: colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Row(
          children: statusOptions.map((option) {
            final isSelected = selectedStatus == option['value'];
            final color = AppConstants.statusColorFor(context, option['value'] as String);
            return Expanded(
              child: GestureDetector(
                onTap: () => onStatusSelected(option['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    left: option == statusOptions.first ? 0 : 6,
                    right: option == statusOptions.last ? 0 : 6,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.15) : colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? color : colorScheme.outlineVariant, width: isSelected ? 2 : 1),
                  ),
                  child: Column(children: [
                    Icon(option['icon'] as IconData, color: isSelected ? color : colorScheme.onSurfaceVariant, size: 28),
                    const SizedBox(height: 8),
                    Text(option['label'] as String, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? color : colorScheme.onSurfaceVariant)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  String _localizedStatus(String status) {
    switch (status) {
      case 'OPEN': return 'سالك';
      case 'CROWDED': return 'أزمة';
      case 'CLOSED': return 'مغلق';
      default: return status;
    }
  }

  Future<void> _submitVote() async {
    setState(() => _isSubmitting = true);
    try {
      final userId = _authService.currentUser!.uid;
      final List<Future> votes = [];

      if (_entranceStatus != null) {
        votes.add(_checkpointService.submitVote(Vote(id: '', checkpointId: widget.checkpoint.id, userId: userId, direction: 'ENTRANCE', status: _entranceStatus!, comment: _commentController.text.isNotEmpty ? _commentController.text : null, timestamp: DateTime.now(), userLatitude: widget.userPosition?.latitude, userLongitude: widget.userPosition?.longitude)));
      }
      if (_exitStatus != null) {
        votes.add(_checkpointService.submitVote(Vote(id: '', checkpointId: widget.checkpoint.id, userId: userId, direction: 'EXIT', status: _exitStatus!, comment: _commentController.text.isNotEmpty ? _commentController.text : null, timestamp: DateTime.now(), userLatitude: widget.userPosition?.latitude, userLongitude: widget.userPosition?.longitude)));
      }

      await Future.wait(votes);
      if (mounted) {
        HapticService.voteConfirmed(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Expanded(child: Text('✓ تم تسجيل تصويتك بنجاح! شكراً لمشاركتك'))]), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('🔴 Vote submission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ حدث خطأ: $e'), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
