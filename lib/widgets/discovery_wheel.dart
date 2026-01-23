import 'package:flutter/material.dart';

class DiscoveryWheel extends StatefulWidget {
  const DiscoveryWheel({super.key});

  @override
  State<DiscoveryWheel> createState() => _DiscoveryWheelState();
}

class _DiscoveryWheelState extends State<DiscoveryWheel> {
  double _rotation = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotation += details.delta.dx * 0.01;
        });
      },
      onPanEnd: (_) {
        _onSpinEnd(context);
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
            color: theme.colorScheme.primary.withOpacity(0.15),
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
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

  void _onSpinEnd(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yeni bir öneri geliyor 👀'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
