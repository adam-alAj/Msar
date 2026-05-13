import 'package:flutter/material.dart';
import '../models/checkpoint_status.dart';
import '../utils/app_icons.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';

class DirectionStatusCard extends StatelessWidget {
  final String title;
  final DirectionStatus status;
  final IconData icon;
  final VoidCallback? onVotePressed;

  const DirectionStatusCard({Key? key, required this.title, required this.status, required this.icon, this.onVotePressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = AppConstants.statusColorFor(context, status.status);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: statusColor.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: colorScheme.shadow.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(right: 0, top: 0, bottom: 0, child: Container(width: 6, color: statusColor)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Direction header
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  ]),
                  const SizedBox(height: 16),

                  // Big status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(status.localizedStatus, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 14),

                  // Progress bar
                  if (status.totalVotes > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: status.percentage / 100,
                        backgroundColor: statusColor.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(statusColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Stats row
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(AppIcons.voteOutlined, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${status.totalVotes} ${AppLocalizations.tr('votes')}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    if (status.totalVotes > 0) ...[
                      Text('  ·  ', style: TextStyle(color: colorScheme.outlineVariant)),
                      Text('${status.percentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                    ],
                    Text('  ·  ', style: TextStyle(color: colorScheme.outlineVariant)),
                    Icon(AppIcons.clock, size: 12, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(_formatTimeAgo(status.lastUpdated), style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ]),

                  // Vote button
                  if (onVotePressed != null) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: onVotePressed,
                      icon: const Icon(AppIcons.vote, size: 16),
                      label: Text(AppLocalizations.tr('vote')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: statusColor,
                        side: BorderSide(color: statusColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return AppLocalizations.tr('now');
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${AppLocalizations.tr('minutes_ago')}';
    if (diff.inHours < 24) return '${diff.inHours} ساعة مضت';
    return '${diff.inDays} يوم مضت';
  }
}
