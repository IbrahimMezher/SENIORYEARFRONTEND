import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/features/broker/dashboard/services/broker_service.dart';
import 'package:fluttertest/features/broker/claims/services/broker_claims_service.dart';

class LinePainter extends CustomPainter {

final Color color, bgColor;
  const LinePainter({required this.color, required this.bgColor});
  @override
  void paint(Canvas canvas, Size size) {
    final pts = [
      0.3,
      0.35,
      0.32,
      0.4,
      0.38,
      0.45,
      0.5,
      0.55,
      0.6,
      0.65,
      0.7,
      0.75
    ];
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgColor, bgColor.withValues(alpha: 0)])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path();
    final fill = Path();
    for (int i = 0; i < pts.length; i++) {
      final x = size.width * i / (pts.length - 1);
      final y = size.height * (1 - pts[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.lineTo(0, size.height);
    fill.close();
    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(path, paint);

    final lastX = size.width * (pts.length - 1) / (pts.length - 1);
    final lastY = size.height * (1 - pts.last);
    canvas.drawCircle(Offset(lastX * 0.84, size.height * (1 - pts[10])), 5,
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(_) => false;
}
