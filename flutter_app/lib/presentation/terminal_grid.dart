import 'package:flutter/material.dart';

/// A subtle character-cell grid that scales with the configured desktop font.
class TerminalGrid extends StatelessWidget {
  const TerminalGrid({required this.fontSize, required this.child, super.key});

  final double fontSize;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _TerminalGridPainter(fontSize), child: child);
}

class _TerminalGridPainter extends CustomPainter {
  const _TerminalGridPainter(this.fontSize);

  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final row = fontSize * 1.55;
    final column = fontSize * .82;
    final paint = Paint()
      ..color = const Color(0xff767c94).withValues(alpha: .10)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += column) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += row) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_TerminalGridPainter oldDelegate) =>
      oldDelegate.fontSize != fontSize;
}
