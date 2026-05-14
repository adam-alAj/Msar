import 'package:flutter/material.dart';
import '../models/checkpoint.dart';
import '../models/checkpoint_status.dart';
import '../utils/app_icons.dart';
import '../utils/constants.dart';

enum SearchMode { map, list }

/// Reusable search bar for both map (suggestions dropdown) and list (live filter) modes.
class CheckpointSearchBar extends StatefulWidget {
  final SearchMode mode;
  final List<Checkpoint> checkpoints;
  final Map<String, CheckpointStatus> statuses;
  final ValueChanged<String> onChanged;
  final ValueChanged<Checkpoint>? onCheckpointSelected; // map mode
  final VoidCallback? onClear;
  final String? hint;

  const CheckpointSearchBar({
    super.key,
    required this.mode,
    required this.checkpoints,
    required this.statuses,
    required this.onChanged,
    this.onCheckpointSelected,
    this.onClear,
    this.hint,
  });

  @override
  State<CheckpointSearchBar> createState() => _CheckpointSearchBarState();
}

class _CheckpointSearchBarState extends State<CheckpointSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Checkpoint> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _removeOverlay();
  }

  void _onTextChanged(String query) {
    widget.onChanged(query);
    if (widget.mode == SearchMode.map) {
      _updateSuggestions(query);
    }
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      _removeOverlay();
      setState(() => _suggestions = []);
      return;
    }
    _suggestions = widget.checkpoints
        .where((cp) => cp.name.contains(query) || cp.region.contains(query))
        .take(5)
        .toList();
    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty) return;
    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectCheckpoint(Checkpoint cp) {
    _controller.text = cp.name;
    _removeOverlay();
    _focusNode.unfocus();
    widget.onCheckpointSelected?.call(cp);
  }

  void _clear() {
    _controller.clear();
    _removeOverlay();
    setState(() => _suggestions = []);
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(AppIcons.locationSearching, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: widget.hint ?? 'ابحث عن حاجز...',
                  hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: _clear,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(AppIcons.close, size: 16, color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    final renderBox = context.findRenderObject() as RenderBox;
    final width = renderBox.size.width;

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        offset: const Offset(0, 48),
        showWhenUnlinked: false,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          color: colorScheme.surfaceContainerHighest,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions.map((cp) {
                final status = widget.statuses[cp.id];
                final statusStr = status?.entrance.status ?? 'OPEN';
                final statusColor = AppConstants.statusColorFor(context, statusStr);
                return InkWell(
                  onTap: () => _selectCheckpoint(cp),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cp.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                              Text(cp.region, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Icon(AppIcons.arrowForwardIos, size: 12, color: colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
