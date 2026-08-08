import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';

enum IbalIconType {
  // Navigation
  navHome,
  navCoverage,
  navClaims,
  navProfile,
  navClients,
  navReports,
  navSettings,
  // Category
  catHealth,
  catMotor,
  catHome,
  catTravel,
  catLife,
  catProperty,
  // Misc
  notifications,
  search,
  renewal,
  broker,
}

/// Two-tone IbAl icon — Navy base + Policy Green accent badge.
///
/// [filled] = true → active two-tone style (nav active state, cards)
/// [filled] = false → outline stroke style (nav inactive state)
class IbalIcon extends StatelessWidget {
  final IbalIconType type;
  final double size;
  final bool filled;
  final Color? baseColor;
  final Color? accentColor;

  const IbalIcon(
    this.type, {
    super.key,
    this.size = 24,
    this.filled = true,
    this.baseColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final Color base;
    if (baseColor != null) {
      base = baseColor!;
    } else if (filled) {
      base = dark ? const Color(0xFFCBD5E1) : AppTheme.brand;
    } else {
      base = dark ? const Color(0xFF94A3B8) : AppTheme.brand;
    }
    final accent = accentColor ?? (dark ? AppTheme.greenDarkAccent : AppTheme.sienna);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IbalIconPainter(
          type: type,
          filled: filled,
          baseColor: base,
          accentColor: accent,
        ),
      ),
    );
  }
}

class _IbalIconPainter extends CustomPainter {
  final IbalIconType type;
  final bool filled;
  final Color baseColor;
  final Color accentColor;

  const _IbalIconPainter({
    required this.type,
    required this.filled,
    required this.baseColor,
    required this.accentColor,
  });

  @override
  bool shouldRepaint(_IbalIconPainter old) =>
      old.type != type ||
      old.filled != filled ||
      old.baseColor != baseColor ||
      old.accentColor != accentColor;

  // ── Paint helpers ───────────────────────────────────────────────────────────
  Paint get _fill => Paint()
    ..color = baseColor
    ..style = PaintingStyle.fill;

  Paint get _stroke => Paint()
    ..color = baseColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get _accent => Paint()
    ..color = accentColor
    ..style = PaintingStyle.fill;

  Paint _white({double alpha = 1.0}) => Paint()
    ..color = Colors.white.withValues(alpha: alpha)
    ..style = PaintingStyle.fill;

  Paint _whiteStroke(double w) => Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // ── Badge ───────────────────────────────────────────────────────────────────
  void _badge(Canvas c, {double cx = 73, double cy = 73, double r = 19}) {
    // Rounded square badge (cleaner than shield at small sizes)
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
        Radius.circular(r * 0.45),
      ),
      _accent,
    );
    // White checkmark
    final s = r * 0.52;
    final p = _whiteStroke(r * 0.24)..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(cx - s * 0.55, cy - s * 0.05)
      ..lineTo(cx - s * 0.10, cy + s * 0.50)
      ..lineTo(cx + s * 0.65, cy - s * 0.45);
    c.drawPath(path, p);
  }

  // ── Outline badge (circular) ────────────────────────────────────────────────
  void _dotBadge(Canvas c, {double cx = 73, double cy = 27, double r = 10}) {
    c.drawCircle(Offset(cx, cy), r, _accent);
  }

  // ── Per-icon draw ───────────────────────────────────────────────────────────
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 100, size.height / 100);
    if (filled) {
      _paintFilled(c);
    } else {
      _paintOutline(c);
    }
    c.restore();
  }

  void _paintFilled(Canvas c) {
    switch (type) {
      case IbalIconType.navHome:
        _filledHome(c);
      case IbalIconType.navCoverage:
        _filledPolicy(c);
      case IbalIconType.navClaims:
        _filledClaims(c);
      case IbalIconType.navProfile:
      case IbalIconType.navClients:
        _filledPerson(c);
      case IbalIconType.navReports:
        _filledReports(c);
      case IbalIconType.navSettings:
        _filledSettings(c);
      case IbalIconType.catHealth:
        _filledHealth(c);
      case IbalIconType.catMotor:
        _filledMotor(c);
      case IbalIconType.catHome:
        _filledHomeCategory(c);
      case IbalIconType.catTravel:
        _filledTravel(c);
      case IbalIconType.catLife:
        _filledLife(c);
      case IbalIconType.catProperty:
        _filledProperty(c);
      case IbalIconType.notifications:
        _filledBell(c);
      case IbalIconType.search:
        _filledSearch(c);
      case IbalIconType.renewal:
        _filledRenewal(c);
      case IbalIconType.broker:
        _filledBroker(c);
    }
  }

  void _paintOutline(Canvas c) {
    switch (type) {
      case IbalIconType.navHome:
        _outlineHome(c);
      case IbalIconType.navCoverage:
        _outlinePolicy(c);
      case IbalIconType.navClaims:
        _outlineClaims(c);
      case IbalIconType.navProfile:
      case IbalIconType.navClients:
        _outlinePerson(c);
      case IbalIconType.navReports:
        _outlineReports(c);
      case IbalIconType.navSettings:
        _outlineSettings(c);
      default:
        _filledPerson(c); // fallback to filled for non-nav types
    }
  }

  // ── FILLED ICONS ────────────────────────────────────────────────────────────

  void _filledHome(Canvas c) {
    // Roof
    final roof = Path()
      ..moveTo(50, 10)
      ..lineTo(90, 48)
      ..lineTo(10, 48)
      ..close();
    c.drawPath(roof, _fill);
    // Chimney
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(62, 22, 74, 46), const Radius.circular(3)),
      _fill,
    );
    // Walls
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(18, 44, 82, 86), const Radius.circular(5)),
      _fill,
    );
    // Door
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(38, 60, 62, 86), const Radius.circular(4)),
      _white(alpha: 0.55),
    );
    // Badge
    _badge(c, cx: 74, cy: 74, r: 18);
  }

  void _filledPolicy(Canvas c) {
    // Clipboard body
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(15, 22, 78, 88), const Radius.circular(7)),
      _fill,
    );
    // Top clip bar
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(30, 12, 63, 30), const Radius.circular(5)),
      _fill,
    );
    // Paper lines
    final lp = _whiteStroke(3.5)..style = PaintingStyle.stroke;
    c.drawLine(const Offset(24, 46), const Offset(62, 46), lp);
    c.drawLine(const Offset(24, 57), const Offset(62, 57), lp);
    c.drawLine(const Offset(24, 67), const Offset(50, 67), lp);
    // Badge
    _badge(c, cx: 73, cy: 74, r: 19);
  }

  void _filledClaims(Canvas c) {
    // Document with top-right corner fold
    final doc = Path()
      ..moveTo(14, 10)
      ..lineTo(67, 10)
      ..lineTo(86, 29)
      ..lineTo(86, 84)
      ..arcToPoint(const Offset(78, 92), radius: const Radius.circular(8))
      ..lineTo(22, 92)
      ..arcToPoint(const Offset(14, 84), radius: const Radius.circular(8))
      ..close();
    c.drawPath(doc, _fill);
    // Fold crease
    final fold = Path()
      ..moveTo(67, 10)
      ..lineTo(86, 29)
      ..lineTo(67, 29)
      ..close();
    c.drawPath(fold, Paint()..color = baseColor.withValues(alpha: 0.45)..style = PaintingStyle.fill);
    // Lines
    final lp = _whiteStroke(3.5)..style = PaintingStyle.stroke;
    c.drawLine(const Offset(24, 46), const Offset(72, 46), lp);
    c.drawLine(const Offset(24, 58), const Offset(72, 58), lp);
    c.drawLine(const Offset(24, 70), const Offset(55, 70), lp);
    // Badge
    _badge(c, cx: 75, cy: 76, r: 18);
  }

  void _filledPerson(Canvas c) {
    // Head
    c.drawCircle(const Offset(50, 30), 19, _fill);
    // Shoulders/body
    final body = Path()
      ..moveTo(8, 94)
      ..quadraticBezierTo(8, 60, 50, 60)
      ..quadraticBezierTo(92, 60, 92, 94)
      ..close();
    c.drawPath(body, _fill);
    // Badge
    _badge(c, cx: 75, cy: 75, r: 18);
  }

  void _filledReports(Canvas c) {
    // Chart axes
    final axisPaint = _fill..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(16, 82), const Offset(16, 12), axisPaint..style = PaintingStyle.stroke);
    c.drawLine(const Offset(14, 82), const Offset(88, 82), axisPaint);
    // Bars
    final bars = [
      [26.0, 45.0, 40.0],
      [44.0, 30.0, 40.0],
      [62.0, 60.0, 40.0],
    ];
    axisPaint.style = PaintingStyle.fill;
    for (final b in bars) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(b[0], 82 - b[1], b[0] + b[2] * 0.45, 82),
          const Radius.circular(3),
        ),
        _fill..style = PaintingStyle.fill,
      );
    }
    // Trend badge — green circle with up-right arrow
    c.drawCircle(const Offset(74, 34), 19, _accent);
    final arrowP = _whiteStroke(4.5);
    c.drawLine(const Offset(66, 42), const Offset(80, 26), arrowP);
    c.drawLine(const Offset(68, 26), const Offset(80, 26), arrowP);
    c.drawLine(const Offset(80, 26), const Offset(80, 38), arrowP);
  }

  void _filledSettings(Canvas c) {
    // Circle body
    c.drawCircle(const Offset(50, 50), 32, _fill);
    // Inner circle cut (white)
    c.drawCircle(const Offset(50, 50), 14, _white(alpha: 0.9));
    // 8 gear teeth
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final x = 50 + 30 * math.cos(a);
      final y = 50 + 30 * math.sin(a);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 10, height: 10),
          const Radius.circular(3),
        ),
        _fill,
      );
    }
    // Badge
    _badge(c, cx: 74, cy: 74, r: 18);
  }

  void _filledHealth(Canvas c) {
    // Medical cross
    final cross = Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(34, 10, 66, 82), const Radius.circular(7)))
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(10, 34, 90, 66), const Radius.circular(7)));
    c.drawPath(cross, _fill);
    _badge(c, cx: 74, cy: 74, r: 19);
  }

  void _filledMotor(Canvas c) {
    // Car body
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(8, 46, 92, 78), const Radius.circular(7)),
      _fill,
    );
    // Roof
    final roof = Path()
      ..moveTo(24, 46)
      ..lineTo(30, 22)
      ..lineTo(70, 22)
      ..lineTo(76, 46)
      ..close();
    c.drawPath(roof, _fill);
    // Windows
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(33, 25, 48, 44), const Radius.circular(3)), _white(alpha: 0.5));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(52, 25, 67, 44), const Radius.circular(3)), _white(alpha: 0.5));
    // Wheels
    for (final wx in [26.0, 74.0]) {
      c.drawCircle(Offset(wx, 80), 12, _fill);
      c.drawCircle(Offset(wx, 80), 6, _white(alpha: 0.6));
    }
    _badge(c, cx: 76, cy: 60, r: 18);
  }

  void _filledHomeCategory(Canvas c) {
    // Identical to nav home but larger badge
    _filledHome(c);
  }

  void _filledTravel(Canvas c) {
    // Airplane silhouette (top-down view)
    final plane = Path()
      ..moveTo(50, 6)    // nose
      ..cubicTo(58, 6, 66, 18, 66, 32)   // right fuselage
      ..lineTo(90, 55)   // right wing tip
      ..lineTo(88, 62)
      ..lineTo(66, 48)   // right wing root
      ..lineTo(64, 74)   // right tail root
      ..lineTo(76, 80)   // right tail tip
      ..lineTo(75, 86)
      ..lineTo(50, 76)   // tail center
      ..lineTo(25, 86)
      ..lineTo(24, 80)
      ..lineTo(36, 74)   // left tail root
      ..lineTo(34, 48)   // left wing root
      ..lineTo(12, 62)
      ..lineTo(10, 55)
      ..lineTo(34, 32)   // left fuselage
      ..cubicTo(34, 18, 42, 6, 50, 6)
      ..close();
    c.drawPath(plane, _fill);
    _badge(c, cx: 74, cy: 74, r: 18);
  }

  void _filledLife(Canvas c) {
    // Shield body
    final shield = Path()
      ..moveTo(50, 8)
      ..lineTo(86, 22)
      ..lineTo(86, 54)
      ..quadraticBezierTo(86, 82, 50, 94)
      ..quadraticBezierTo(14, 82, 14, 54)
      ..lineTo(14, 22)
      ..close();
    c.drawPath(shield, _fill);
    // Heart inside
    final heart = Path();
    const cx = 50.0, cy = 52.0;
    heart.moveTo(cx, cy + 18);
    heart.cubicTo(cx - 28, cy - 2, cx - 28, cy - 22, cx, cy - 10);
    heart.cubicTo(cx + 28, cy - 22, cx + 28, cy - 2, cx, cy + 18);
    c.drawPath(heart, _white(alpha: 0.82));
    // Green plus badge
    c.drawCircle(const Offset(74, 74), 18, _accent);
    final pp = _whiteStroke(5.5);
    c.drawLine(const Offset(74, 63), const Offset(74, 85), pp);
    c.drawLine(const Offset(63, 74), const Offset(85, 74), pp);
  }

  void _filledProperty(Canvas c) {
    // Building
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(18, 24, 82, 88), const Radius.circular(5)),
      _fill,
    );
    // Rooftop bar
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(10, 16, 90, 28), const Radius.circular(4)),
      _fill,
    );
    // Windows (2×3 grid)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(28 + col * 28.0, 34 + row * 17.0, 16, 10),
            const Radius.circular(2),
          ),
          _white(alpha: 0.55),
        );
      }
    }
    _badge(c, cx: 74, cy: 76, r: 18);
  }

  void _filledBell(Canvas c) {
    // Bell shape
    final bell = Path()
      ..moveTo(50, 10)
      ..cubicTo(72, 10, 84, 26, 84, 50)
      ..lineTo(84, 64)
      ..quadraticBezierTo(90, 70, 90, 74)
      ..lineTo(10, 74)
      ..quadraticBezierTo(10, 70, 16, 64)
      ..lineTo(16, 50)
      ..cubicTo(16, 26, 28, 10, 50, 10)
      ..close();
    c.drawPath(bell, _fill);
    // Clapper
    c.drawCircle(const Offset(50, 82), 8, _fill);
    // Notification badge (top-right dot)
    _dotBadge(c, cx: 76, cy: 24, r: 14);
    // Small number "1" implied by solid dot
  }

  void _filledSearch(Canvas c) {
    // Glass circle
    c.drawCircle(const Offset(40, 40), 28, _fill);
    c.drawCircle(const Offset(40, 40), 18, _white(alpha: 0.35));
    // Handle
    final handlePath = Path()
      ..moveTo(60, 60)
      ..lineTo(82, 82);
    c.drawPath(handlePath, Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round);
    _badge(c, cx: 76, cy: 76, r: 18);
  }

  void _filledRenewal(Canvas c) {
    // Clock
    c.drawCircle(const Offset(50, 50), 38, _fill);
    c.drawCircle(const Offset(50, 50), 28, _white(alpha: 0.15));
    // Clock hands
    final hp = _whiteStroke(5)..style = PaintingStyle.stroke;
    c.drawLine(const Offset(50, 50), const Offset(50, 24), hp); // hour → 12
    c.drawLine(const Offset(50, 50), const Offset(68, 50), hp); // minute → 3
    c.drawCircle(const Offset(50, 50), 4.5, Paint()..color = Colors.white);
    // Green refresh badge
    c.drawCircle(const Offset(74, 74), 18, _accent);
    _drawRefreshArrow(c, cx: 74, cy: 74, r: 11);
  }

  void _drawRefreshArrow(Canvas c, {required double cx, required double cy, required double r}) {
    final paint = _whiteStroke(3.5)..style = PaintingStyle.stroke;
    c.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi * 0.25,
      math.pi * 1.5,
      false,
      paint,
    );
    // Arrowhead
    final endAngle = -math.pi * 0.25 + math.pi * 1.5;
    final ex = cx + r * math.cos(endAngle);
    final ey = cy + r * math.sin(endAngle);
    c.drawLine(Offset(ex, ey), Offset(ex - 4, ey - 5), _whiteStroke(3.5));
    c.drawLine(Offset(ex, ey), Offset(ex + 5, ey - 2), _whiteStroke(3.5));
  }

  void _filledBroker(Canvas c) {
    // Briefcase
    // Handle
    final handle = Path()
      ..moveTo(35, 30)
      ..arcToPoint(const Offset(65, 30),
          radius: const Radius.circular(15),
          largeArc: false,
          clockwise: false);
    c.drawPath(
      handle,
      Paint()
        ..color = baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.butt,
    );
    // Case body
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(14, 30, 86, 82), const Radius.circular(7)),
      _fill,
    );
    // Center divider
    c.drawLine(
      const Offset(14, 56),
      const Offset(86, 56),
      _whiteStroke(3.5)..style = PaintingStyle.stroke..color = Colors.white.withValues(alpha: 0.4),
    );
    // Latch
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(41, 49, 59, 63), const Radius.circular(4)),
      _white(alpha: 0.6),
    );
    _badge(c, cx: 74, cy: 74, r: 18);
  }

  // ── OUTLINE ICONS (nav inactive state) ─────────────────────────────────────

  void _outlineHome(Canvas c) {
    final p = _stroke;
    // Roof outline
    final roof = Path()
      ..moveTo(10, 50)
      ..lineTo(50, 12)
      ..lineTo(90, 50);
    c.drawPath(roof, p);
    // Walls
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(20, 46, 80, 86), const Radius.circular(5)),
      p..style = PaintingStyle.stroke,
    );
    // Door
    final doorPath = Path()
      ..moveTo(38, 86)
      ..lineTo(38, 64)
      ..arcToPoint(const Offset(62, 64), radius: const Radius.circular(12))
      ..lineTo(62, 86);
    c.drawPath(doorPath, p..strokeWidth = 5);
  }

  void _outlinePolicy(Canvas c) {
    final p = _stroke;
    // Clipboard outline
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(15, 22, 80, 88), const Radius.circular(7)),
      p,
    );
    // Top clip
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(30, 12, 70, 30), const Radius.circular(5)),
      p..strokeWidth = 5,
    );
    // Lines
    c.drawLine(const Offset(24, 48), const Offset(62, 48), p..strokeWidth = 4);
    c.drawLine(const Offset(24, 59), const Offset(62, 59), p);
    c.drawLine(const Offset(24, 70), const Offset(50, 70), p);
  }

  void _outlineClaims(Canvas c) {
    final p = _stroke;
    // Document outline
    final doc = Path()
      ..moveTo(14, 10)
      ..lineTo(67, 10)
      ..lineTo(86, 29)
      ..lineTo(86, 88)
      ..arcToPoint(const Offset(78, 94), radius: const Radius.circular(8))
      ..lineTo(22, 94)
      ..arcToPoint(const Offset(14, 88), radius: const Radius.circular(8))
      ..close();
    c.drawPath(doc, p);
    c.drawLine(const Offset(67, 10), const Offset(67, 29), p..strokeWidth = 4);
    c.drawLine(const Offset(67, 29), const Offset(86, 29), p);
    // Lines
    c.drawLine(const Offset(24, 48), const Offset(72, 48), p);
    c.drawLine(const Offset(24, 60), const Offset(72, 60), p);
  }

  void _outlinePerson(Canvas c) {
    final p = _stroke;
    // Head circle
    c.drawCircle(const Offset(50, 30), 19, p);
    // Shoulders arc
    final body = Path()
      ..moveTo(8, 96)
      ..quadraticBezierTo(8, 62, 50, 62)
      ..quadraticBezierTo(92, 62, 92, 96);
    c.drawPath(body, p);
  }

  void _outlineReports(Canvas c) {
    final p = _stroke;
    // Axes
    c.drawLine(const Offset(16, 82), const Offset(16, 12), p);
    c.drawLine(const Offset(14, 82), const Offset(88, 82), p);
    // Bar outlines
    final bars = [[26.0, 45.0], [44.0, 30.0], [62.0, 60.0]];
    for (final b in bars) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(b[0], 82 - b[1], b[0] + 18, 82),
          const Radius.circular(3),
        ),
        p..strokeWidth = 5,
      );
    }
  }

  void _outlineSettings(Canvas c) {
    final p = _stroke..strokeWidth = 5;
    // Outer gear circle
    c.drawCircle(const Offset(50, 50), 30, p);
    // Inner circle
    c.drawCircle(const Offset(50, 50), 12, p);
    // 4 teeth (top, right, bottom, left)
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      c.drawLine(
        Offset(50 + 30 * math.cos(a), 50 + 30 * math.sin(a)),
        Offset(50 + 42 * math.cos(a), 50 + 42 * math.sin(a)),
        p..strokeWidth = 8,
      );
    }
  }
}
