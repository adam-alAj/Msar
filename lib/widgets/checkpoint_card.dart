import 'package:flutter/material.dart';
import '../models/checkpoint.dart';
import '../models/checkpoint_status.dart';
import '../utils/app_icons.dart';
import '../utils/constants.dart';
import '../utils/neu_glass.dart';

class CheckpointCard extends StatelessWidget {
  final Checkpoint checkpoint;
  final CheckpointStatus? status;
  final VoidCallback onTap;

  const CheckpointCard({Key? key, required this.checkpoint, required this.status, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entranceStatus = status?.entrance.status ?? 'OPEN';
    final exitStatus = status?.exit.status ?? 'OPEN';
    final entrancePercentage = status?.entrance.percentage ?? 0;
    final exitPercentage = status?.exit.percentage ?? 0;
    final entranceVotes = status?.entrance.totalVotes ?? 0;
    final exitVotes = status?.exit.totalVotes ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: NeuDecoration.box(context, radius: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  Hero(
                    tag: 'cp-icon-${checkpoint.id}',
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                      child: Icon(AppIcons.location, color: colorScheme.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Hero(
                      tag: 'cp-name-${checkpoint.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(checkpoint.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    Hero(
                      tag: 'cp-region-${checkpoint.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(AppIcons.place, size: 10, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(checkpoint.region, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                        ]),
                      ),
                    ),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                    child: Text('${entranceVotes + exitVotes}', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  ),
                ]),
                const SizedBox(height: 10),

                // Direction tiles
                Row(children: [
                  Expanded(child: _buildDirectionTile(context, 'للداخل', entranceStatus, entrancePercentage, entranceVotes, AppIcons.arrowForward)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDirectionTile(context, 'للخارج', exitStatus, exitPercentage, exitVotes, AppIcons.arrowBack)),
                ]),
                const SizedBox(height: 8),

                // Action button
                Container(
                  width: double.infinity, height: 32,
                  decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('تفاصيل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.primary)),
                    const SizedBox(width: 4),
                    Icon(AppIcons.arrowBackIos, size: 10, color: colorScheme.primary),
                  ])),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildDirectionTile(BuildContext context, String title, String status, double percentage, int votes, IconData icon) {
    final statusColor = AppConstants.statusColorFor(context, status);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 0.5),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 4),
        Container(
          width: double.infinity, height: 3,
          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(2)),
          child: FractionallySizedBox(
            widthFactor: percentage / 100,
            child: Container(decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
          ),
        ),
        const SizedBox(height: 4),
        Text(_localizedStatus(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
        if (votes > 0) Text('${percentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant)),
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
}
