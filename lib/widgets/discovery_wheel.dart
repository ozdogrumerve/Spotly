import 'package:flutter/material.dart';

class DiscoveryWheel extends StatefulWidget {
  final VoidCallback onSpin;

  const DiscoveryWheel({
    super.key,
    required this.onSpin,
  });

  @override
  State<DiscoveryWheel> createState() => _DiscoveryWheelState();
}

class _DiscoveryWheelState extends State<DiscoveryWheel> {
  double _rotation = 0;
  double _dragAmount = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotation += details.delta.dx * 0.01;
          _dragAmount += details.delta.dx.abs();
        });
      },

      onPanEnd: (_) {
        // 🔑 Eşik: gerçekten çevrilmiş mi?
        if (_dragAmount > 40) {
          widget.onSpin(); // 
        }

        // reset
        _dragAmount = 0;
      },

      child: AnimatedRotation(
        turns: _rotation,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withAlpha(35),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.explore,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
