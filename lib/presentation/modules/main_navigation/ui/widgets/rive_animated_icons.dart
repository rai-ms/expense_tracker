import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// Enum for the 5 navigation tabs
enum RiveNavTab {
  dashboard,
  transactions,
  khata,
  analytics,
  reminders,
}

/// Dynamic Rive-style Interactive Animated Icon Widget
class RiveNavIcon extends StatefulWidget {
  final RiveNavTab tab;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  const RiveNavIcon({
    super.key,
    required this.tab,
    required this.isSelected,
    this.activeColor = AppColors.primaryLight,
    this.inactiveColor = AppColors.textTertiaryDark,
  });

  @override
  State<RiveNavIcon> createState() => _RiveNavIconState();
}

class _RiveNavIconState extends State<RiveNavIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant RiveNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final color = Color.lerp(widget.inactiveColor, widget.activeColor, progress)!;

        return SizedBox(
          width: 28,
          height: 28,
          child: CustomPaint(
            painter: _getRivePainter(widget.tab, progress, color, widget.activeColor),
          ),
        );
      },
    );
  }

  CustomPainter _getRivePainter(
    RiveNavTab tab,
    double progress,
    Color color,
    Color activeColor,
  ) {
    switch (tab) {
      case RiveNavTab.dashboard:
        return _RiveDashboardPainter(progress: progress, color: color, activeColor: activeColor);
      case RiveNavTab.transactions:
        return _RiveTransactionsPainter(progress: progress, color: color, activeColor: activeColor);
      case RiveNavTab.khata:
        return _RiveKhataPainter(progress: progress, color: color, activeColor: activeColor);
      case RiveNavTab.analytics:
        return _RiveAnalyticsPainter(progress: progress, color: color, activeColor: activeColor);
      case RiveNavTab.reminders:
        return _RiveRemindersPainter(progress: progress, color: color, activeColor: activeColor);
    }
  }
}

// ==========================================
// 1. DASHBOARD: Morphing 4-Grid Pods & Pulsing Core
// ==========================================
class _RiveDashboardPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color activeColor;

  _RiveDashboardPainter({
    required this.progress,
    required this.color,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final gap = 3.5;
    final halfW = (w - gap) / 2;
    final halfH = (h - gap) / 2;

    final curve = Curves.elasticOut.transform(progress.clamp(0.0, 1.0));

    // Top-Left: Expands width dynamically
    final tlWidth = halfW + (curve * 3);
    final tlRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, tlWidth, halfH),
      Radius.circular(2.5 + curve * 3.5),
    );
    canvas.drawRRect(tlRRect, paint);

    // Top-Right: Pill / dot morph
    final trLeft = tlWidth + gap;
    final trWidth = w - trLeft;
    final trRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(trLeft, 0, trWidth, halfH),
      Radius.circular(2.5 + curve * 4),
    );
    canvas.drawRRect(trRRect, paint);

    // Bottom-Left: Shrinks / morphs
    final blHeight = halfH + (curve * 2);
    final blTop = h - blHeight;
    final blRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, blTop, halfW - (curve * 2), blHeight),
      Radius.circular(2.5 + curve * 3.5),
    );
    canvas.drawRRect(blRRect, paint);

    // Bottom-Right: Rotates slightly with energy glow
    final brLeft = halfW + gap - (curve * 2);
    final brRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(brLeft, halfH + gap, w - brLeft, halfH),
      Radius.circular(2.5 + curve * 3.5),
    );
    canvas.drawRRect(brRRect, paint);

    // Center Energy Dot (Pulsing ring when active)
    if (progress > 0.1) {
      final centerPaint = Paint()
        ..color = activeColor.withValues(alpha: (progress * 0.9).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w / 2, h / 2), 2.0 * curve, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RiveDashboardPainter old) =>
      old.progress != progress || old.color != color;
}

// ==========================================
// 2. TRANSACTIONS: Receipt Card & Dynamic Transfer Arrows
// ==========================================
class _RiveTransactionsPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color activeColor;

  _RiveTransactionsPainter({
    required this.progress,
    required this.color,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final curve = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));

    // Outer Receipt Card Frame
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, w - 4, h - 4),
      const Radius.circular(5),
    );
    canvas.drawRRect(cardRect, strokePaint);

    // Line 1: Header Line
    canvas.drawLine(
      Offset(6, 7),
      Offset(w - 6 - (1 - progress) * 4, 7),
      strokePaint..strokeWidth = 1.8,
    );

    // Line 2: Middle transaction text line
    final line2Width = 8.0 + (curve * 6);
    canvas.drawLine(
      Offset(6, 12),
      Offset(6 + line2Width, 12),
      strokePaint..strokeWidth = 1.6,
    );

    // Animated In/Out Transfer Arrows & Tick
    if (progress > 0.05) {
      // Inflow Arrow (Green / Accent) jumping up
      final arrowY = 20 - (curve * 4);
      final arrowPaint = Paint()
        ..color = Color.lerp(color, AppColors.creditGreen, progress)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      // Up arrow path
      final arrowPath = Path()
        ..moveTo(w - 9, arrowY + 3)
        ..lineTo(w - 9, arrowY - 3)
        ..lineTo(w - 12, arrowY - 1)
        ..moveTo(w - 9, arrowY - 3)
        ..lineTo(w - 6, arrowY - 1);
      canvas.drawPath(arrowPath, arrowPaint);

      // Checkmark tick in bottom-left
      final tickProgress = Curves.elasticOut.transform(progress);
      final tickPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      final tickPath = Path()
        ..moveTo(6, 19)
        ..lineTo(8, 21 * tickProgress.clamp(0.8, 1.0))
        ..lineTo(12, 17);
      canvas.drawPath(tickPath, tickPaint);
    } else {
      // Resting dots
      canvas.drawCircle(Offset(7, 18), 1.2, fillPaint);
      canvas.drawCircle(Offset(12, 18), 1.2, fillPaint);
      canvas.drawCircle(Offset(17, 18), 1.2, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RiveTransactionsPainter old) =>
      old.progress != progress || old.color != color;
}

// ==========================================
// 3. KHATABOOK: 3D Opening Ledger Book & Bookmark Ribbon
// ==========================================
class _RiveKhataPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color activeColor;

  _RiveKhataPainter({
    required this.progress,
    required this.color,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final curve = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));

    // Book Spine (Left vertical edge)
    canvas.drawLine(
      const Offset(4, 3),
      Offset(4, h - 3),
      strokePaint..strokeWidth = 2.5,
    );

    // Base Cover / Pages Backing
    final bookPath = Path()
      ..moveTo(4, 4)
      ..lineTo(w - 4, 4)
      ..lineTo(w - 4, h - 4)
      ..lineTo(4, h - 4);
    canvas.drawPath(bookPath, strokePaint..strokeWidth = 1.8);

    // Front Cover Flip Opening Animation
    if (progress > 0.05) {
      // 3D Angle flip
      final openOffset = curve * 7.0;
      final flipCoverPath = Path()
        ..moveTo(4, 4)
        ..quadraticBezierTo(w / 2 - openOffset, 2 - openOffset * 0.4, w - 4 - openOffset, 4 - openOffset * 0.5)
        ..lineTo(w - 4 - openOffset, h - 4 - openOffset * 0.5)
        ..quadraticBezierTo(w / 2 - openOffset, h - 2 - openOffset * 0.4, 4, h - 4);

      final pagePaint = Paint()
        ..color = activeColor.withValues(alpha: 0.3 + progress * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(flipCoverPath, pagePaint);

      // Ledger Entry Lines inside the book
      final linePaint = Paint()
        ..color = activeColor.withValues(alpha: progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(8, 9), Offset(w - 8, 9), linePaint);
      canvas.drawLine(Offset(8, 14), Offset(w - 11, 14), linePaint);
      canvas.drawLine(Offset(8, 19), Offset(w - 7, 19), linePaint);
    } else {
      // Bookmark Ribbon hanging down
      final ribbonPath = Path()
        ..moveTo(10, 4)
        ..lineTo(10, 14)
        ..lineTo(13, 11)
        ..lineTo(16, 14)
        ..lineTo(16, 4);
      canvas.drawPath(ribbonPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RiveKhataPainter old) =>
      old.progress != progress || old.color != color;
}

// ==========================================
// 4. ANALYTICS: Dynamic Equalizer Bars & Surging Sparkline
// ==========================================
class _RiveAnalyticsPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color activeColor;

  _RiveAnalyticsPainter({
    required this.progress,
    required this.color,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final curve = Curves.elasticOut.transform(progress.clamp(0.0, 1.0));

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 3 Dynamic Graph Bars with height surge
    final barWidth = 4.5;
    final baseBottom = h - 3.0;

    // Bar 1 (Left): Heights: 8 -> 13
    final bar1H = 7.0 + (curve * 6.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3.5, baseBottom - bar1H, barWidth, bar1H),
        const Radius.circular(2.5),
      ),
      barPaint,
    );

    // Bar 2 (Middle): Heights: 14 -> 20 (Highest surge)
    final bar2H = 12.0 + (curve * 8.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3.5 + barWidth + 3.0, baseBottom - bar2H, barWidth, bar2H),
        const Radius.circular(2.5),
      ),
      Paint()..color = Color.lerp(color, activeColor, progress)!,
    );

    // Bar 3 (Right): Heights: 10 -> 16
    final bar3H = 9.0 + (curve * 7.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3.5 + (barWidth + 3.0) * 2, baseBottom - bar3H, barWidth, bar3H),
        const Radius.circular(2.5),
      ),
      barPaint,
    );

    // Sparkline Trend Wave over the bars
    if (progress > 0.1) {
      final sparkPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final sparkPath = Path()
        ..moveTo(3.5 + barWidth / 2, baseBottom - bar1H)
        ..quadraticBezierTo(
          11,
          baseBottom - bar2H - 3,
          3.5 + barWidth + 3.0 + barWidth / 2,
          baseBottom - bar2H,
        )
        ..quadraticBezierTo(
          19,
          baseBottom - bar2H + 2,
          3.5 + (barWidth + 3.0) * 2 + barWidth / 2,
          baseBottom - bar3H,
        );

      canvas.drawPath(sparkPath, sparkPaint);

      // Glowing peak dot
      canvas.drawCircle(
        Offset(3.5 + barWidth + 3.0 + barWidth / 2, baseBottom - bar2H),
        2.2,
        Paint()..color = activeColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RiveAnalyticsPainter old) =>
      old.progress != progress || old.color != color;
}

// ==========================================
// 5. REMINDERS: Harmonic Swinging Bell, Clapper & Sonic Waves
// ==========================================
class _RiveRemindersPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color activeColor;

  _RiveRemindersPainter({
    required this.progress,
    required this.color,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // Harmonic damped oscillation for realistic bell chime
    final swingAngle = progress > 0.0
        ? math.sin(progress * 4.0 * math.pi) * (1.0 - progress) * 0.35
        : 0.0;

    canvas.save();
    // Pivot at the top suspension point
    canvas.translate(w / 2, 4);
    canvas.rotate(swingAngle);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Bell Top Loop / Hook
    canvas.drawCircle(const Offset(0, -1), 1.5, strokePaint..strokeWidth = 1.5);

    // Bell Dome Contour
    final bellPath = Path()
      ..moveTo(0, 1)
      ..cubicTo(4, 2, 7, 7, 8.5, 13)
      ..lineTo(-8.5, 13)
      ..cubicTo(-7, 7, -4, 2, 0, 1);
    canvas.drawPath(bellPath, strokePaint..strokeWidth = 1.8);

    // Bottom Rim
    final rimPath = Path()
      ..moveTo(-10, 13)
      ..lineTo(10, 13);
    canvas.drawPath(rimPath, strokePaint..strokeWidth = 2.0);

    // Clapper (Pendulum swings in opposite direction)
    final clapperSwing = -swingAngle * 1.6;
    final clapperX = math.sin(clapperSwing) * 3;
    canvas.drawCircle(Offset(clapperX, 15.5), 2.2, fillPaint);

    canvas.restore();

    // Soundwave Acoustic Arcs when bell rings (Rive sonic pulse)
    if (progress > 0.1 && progress < 0.95) {
      final waveAlpha = math.sin(progress * math.pi);
      final wavePaint = Paint()
        ..color = activeColor.withValues(alpha: (waveAlpha * 0.85).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      // Left wave
      final leftArc = Path()
        ..addArc(
          Rect.fromCircle(center: Offset(w / 2, 12), radius: 13.0 + progress * 3),
          math.pi * 0.75,
          math.pi * 0.35,
        );
      canvas.drawPath(leftArc, wavePaint);

      // Right wave
      final rightArc = Path()
        ..addArc(
          Rect.fromCircle(center: Offset(w / 2, 12), radius: 13.0 + progress * 3),
          -math.pi * 0.1,
          math.pi * 0.35,
        );
      canvas.drawPath(rightArc, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RiveRemindersPainter old) =>
      old.progress != progress || old.color != color;
}
