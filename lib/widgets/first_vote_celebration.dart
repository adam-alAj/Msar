import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time confetti celebration for first vote. Palestinian palette, dignified.
class FirstVoteCelebration extends StatefulWidget {
  final Widget child;
  const FirstVoteCelebration({super.key, required this.child});

  static final _controller = ConfettiController(duration: const Duration(milliseconds: 2500));
  static bool _hasTriggered = false;

  /// Call after first successful vote. Returns true if celebration shown.
  static Future<bool> trigger(BuildContext context) async {
    if (_hasTriggered) return false;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('has_celebrated_first_vote') == true) return false;

    _hasTriggered = true;
    await prefs.setBool('has_celebrated_first_vote', true);

    if (!context.mounted) return false;
    if (MediaQuery.of(context).disableAnimations) return false;

    _controller.play();
    return true;
  }

  @override
  State<FirstVoteCelebration> createState() => _FirstVoteCelebrationState();
}

class _FirstVoteCelebrationState extends State<FirstVoteCelebration> {
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    FirstVoteCelebration._controller.addListener(_onConfetti);
  }

  void _onConfetti() {
    if (FirstVoteCelebration._controller.state == ConfettiControllerState.playing && !_showText) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showText = true);
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) setState(() => _showText = false);
        });
      });
    }
  }

  @override
  void dispose() {
    FirstVoteCelebration._controller.removeListener(_onConfetti);
    super.dispose();
  }

  static const _colors = [
    Color(0xFFCE1126), // Red
    Color(0xFF007A3D), // Green
    Color(0xFF000000), // Black
    Color(0xE6FFFFFF), // White 90%
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: FirstVoteCelebration._controller,
            blastDirection: -pi / 2, // Upward
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 60,
            gravity: 0.2,
            colors: _colors,
            shouldLoop: false,
          ),
        ),
        if (_showText)
          Positioned(
            bottom: 120,
            left: 32,
            right: 32,
            child: AnimatedOpacity(
              opacity: _showText ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                'شكراً — صوتك يساعد مسافراً الآن',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
