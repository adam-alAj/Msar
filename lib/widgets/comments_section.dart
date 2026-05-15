import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/vote.dart';
import '../utils/app_icons.dart';
import '../utils/constants.dart';

/// Fetches recent votes that have comments for a checkpoint.
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<List<Vote>>> getRecentComments(String checkpointId, {int limit = 5}) async {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 60));
    final snapshot = await _firestore.collection(AppConstants.votesCollection).get();

    final votes = snapshot.docs
        .map(Vote.fromFirestore)
        .where((v) =>
            v.checkpointId == checkpointId &&
            v.comment != null &&
            v.comment!.trim().length > 1 &&
            v.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Group by user + comment text
    final Map<String, List<Vote>> grouped = {};
    for (final v in votes) {
      final key = '${v.userId}|${v.comment!.trim()}';
      grouped.putIfAbsent(key, () => []).add(v);
    }

    return grouped.values.take(limit).toList();
  }

  Future<List<List<Vote>>> getAllComments(String checkpointId) async {
    final snapshot = await _firestore.collection(AppConstants.votesCollection).get();

    final votes = snapshot.docs
        .map(Vote.fromFirestore)
        .where((v) => v.checkpointId == checkpointId && v.comment != null && v.comment!.trim().length > 1)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final Map<String, List<Vote>> grouped = {};
    for (final v in votes) {
      final key = '${v.userId}|${v.comment!.trim()}';
      grouped.putIfAbsent(key, () => []).add(v);
    }

    return grouped.values.toList();
  }
}

// ─── ARABIC RELATIVE TIME ─────────────────────────────────────────────────────

String arabicRelativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes == 1) return 'منذ دقيقة';
  if (diff.inMinutes == 2) return 'منذ دقيقتين';
  if (diff.inMinutes <= 10) return 'منذ ${diff.inMinutes} دقائق';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours == 1) return 'منذ ساعة';
  if (diff.inHours == 2) return 'منذ ساعتين';
  if (diff.inHours <= 10) return 'منذ ${diff.inHours} ساعات';
  return 'منذ ${diff.inHours} ساعة';
}

// ─── COMMENT CARD ─────────────────────────────────────────────────────────────

class CommentCard extends StatefulWidget {
  final List<Vote> votes;

  const CommentCard({super.key, required this.votes});

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = widget.votes.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment text
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              primary.comment!,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface, height: 1.5),
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: 8),
          // Footer: badges + timestamp
          Row(
            children: [
              ...widget.votes.map((v) {
                final statusColor = AppConstants.statusColorFor(context, v.status);
                final dirLabel = v.direction == 'ENTRANCE' ? 'داخل' : 'خارج';
                final statusLabel = v.status == 'OPEN' ? 'سالك' : v.status == 'CROWDED' ? 'أزمة' : 'مغلق';
                return Padding(
                  padding: const EdgeInsetsDirectional.only(start: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$dirLabel · $statusLabel',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                );
              }),
              const Spacer(),
              Icon(AppIcons.clock, size: 11, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 3),
              Text(
                arabicRelativeTime(primary.timestamp),
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── COMMENTS SECTION ─────────────────────────────────────────────────────────

class CommentsSection extends StatefulWidget {
  final String checkpointId;

  const CommentsSection({super.key, required this.checkpointId});

  @override
  State<CommentsSection> createState() => CommentsSectionState();
}

class CommentsSectionState extends State<CommentsSection> {
  final CommentService _service = CommentService();
  List<List<Vote>>? _comments;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refresh() async {
    setState(() { _loading = true; _error = false; });
    await _load();
  }

  Future<void> _load() async {
    try {
      final comments = await _service.getRecentComments(widget.checkpointId);
      if (mounted) setState(() { _comments = comments; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = true; _loading = false; });
    }
  }

  void _showAllComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllCommentsSheet(checkpointId: widget.checkpointId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(AppIcons.comment, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text('آراء المسافرين', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
            const Spacer(),
            if (_comments != null && _comments!.isNotEmpty)
              GestureDetector(
                onTap: _showAllComments,
                child: Text('عرض الكل', style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Content
        if (_loading)
          Center(child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)),
          ))
        else if (_error)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('تعذر تحميل التعليقات', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          )
        else if (_comments == null || _comments!.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Icon(AppIcons.comment, size: 28, color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
              const SizedBox(height: 8),
              Text('لا توجد تعليقات في الساعة الأخيرة', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ]),
          )
        else
          ..._comments!.map((group) => CommentCard(votes: group)),
      ],
    );
  }
}

// ─── ALL COMMENTS BOTTOM SHEET ────────────────────────────────────────────────

class _AllCommentsSheet extends StatefulWidget {
  final String checkpointId;
  const _AllCommentsSheet({required this.checkpointId});

  @override
  State<_AllCommentsSheet> createState() => _AllCommentsSheetState();
}

class _AllCommentsSheetState extends State<_AllCommentsSheet> {
  final CommentService _service = CommentService();
  List<List<Vote>>? _comments;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.getAllComments(widget.checkpointId).then((c) {
      if (mounted) setState(() { _comments = c; _loading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(AppIcons.comment, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('جميع آراء المسافرين', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context), child: Icon(AppIcons.close, size: 20, color: colorScheme.onSurfaceVariant)),
              ]),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments == null || _comments!.isEmpty
                      ? Center(child: Text('لا توجد تعليقات', style: TextStyle(color: colorScheme.onSurfaceVariant)))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _comments!.length,
                          itemBuilder: (_, i) => CommentCard(votes: _comments![i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
