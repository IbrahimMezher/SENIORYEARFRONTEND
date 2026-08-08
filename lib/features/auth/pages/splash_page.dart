import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/aurora_backdrop.dart';

// ── interval helper ───────────────────────────────────────────────────────────

double _iv(double t, double s, double e, [Curve c = Curves.linear]) =>
    c.transform(((t - s) / (e - s)).clamp(0.0, 1.0));

// ── particle data (deterministic, fixed seeds) ────────────────────────────────

class _Pd {
  final double angle, speed, sz, ph;
  const _Pd(this.angle, this.speed, this.sz, this.ph);
}

List<_Pd> _buildPd(int n, int seed) {
  final r = Random(seed);
  return List.unmodifiable(List.generate(
    n,
    (_) => _Pd(
      r.nextDouble() * 2 * pi,
      0.4 + r.nextDouble() * 0.9,
      1.2 + r.nextDouble() * 2.8,
      r.nextDouble(),
    ),
  ));
}

final _kShieldParts = _buildPd(14, 7);
final _kBgParts     = _buildPd(18, 31);

// ── shield + checkmark painter ────────────────────────────────────────────────

class _ShieldLogoPainter extends CustomPainter {
  final double progress;   // _seqCtrl 0→1
  final double scale;      // entrance scale-in (may exceed 1 briefly for bounce)
  final double floatDy;    // ±px breathing float
  final double pulse;      // 0→1 repeating, drives glow + particles
  final double bgPhase;    // 0→1 repeating, drives bg particles
  final Color shieldColor;
  final Color checkColor;

  const _ShieldLogoPainter({
    required this.progress,
    required this.scale,
    required this.floatDy,
    required this.pulse,
    required this.bgPhase,
    required this.shieldColor,
    required this.checkColor,
  });

  Path _shieldOutline(double l, double t, double w, double h) {
    final cx = l + w * 0.5;
    return Path()
      ..moveTo(l, t)
      ..lineTo(l + w, t)
      ..lineTo(l + w, t + h * 0.55)
      ..cubicTo(l + w, t + h * 0.84, cx, t + h * 0.96, cx, t + h)
      ..cubicTo(cx, t + h * 0.96, l, t + h * 0.84, l, t + h * 0.55)
      ..lineTo(l, t);
  }

  Path _checkmark(double W, double H) => Path()
    ..moveTo(W * 0.19, H * 0.57)
    ..lineTo(W * 0.37, H * 0.79)
    ..lineTo(W * 0.83, H * 0.33);

  void _drawTrimmed(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    if (t >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * t), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width, H = size.height;

    // ── background particles ─────────────────────────────────────────────────
    final bgPaint = Paint()..style = PaintingStyle.fill;
    for (final d in _kBgParts) {
      final ph = (bgPhase + d.ph) % 1.0;
      final cx = W * (0.05 + d.ph * 0.90) +
          cos(d.angle + ph * 2 * pi) * W * 0.05 * d.speed;
      final cy = H * (0.05 + d.speed * 0.50) +
          sin(ph * 2 * pi) * H * 0.10;
      final a = (0.03 + 0.05 * sin(ph * pi)).clamp(0.0, 1.0);
      bgPaint.color = checkColor.withValues(alpha: a);
      canvas.drawCircle(Offset(cx, cy), d.sz, bgPaint);
    }

    // ── combined float + scale transform ────────────────────────────────────
    canvas.save();
    canvas.translate(W / 2, H / 2 + floatDy);
    canvas.scale(scale);
    canvas.translate(-W / 2, -H / 2);

    final sL = W * 0.07, sT = H * 0.04, sW = W * 0.55, sH = H * 0.87;
    final shieldPath = _shieldOutline(sL, sT, sW, sH);

    // ── Phase 1: shield draw (0.05 → 0.42) ──────────────────────────────────
    final sP = _iv(progress, 0.05, 0.42, Curves.easeOut);
    if (sP > 0) {
      if (sP > 0.78) {
        final a = ((sP - 0.78) / 0.22).clamp(0.0, 1.0) * 0.12;
        canvas.drawPath(
          shieldPath,
          Paint()
            ..style = PaintingStyle.fill
            ..color = shieldColor.withValues(alpha: a),
        );
      }
      _drawTrimmed(
        canvas,
        shieldPath,
        sP,
        Paint()
          ..style      = PaintingStyle.stroke
          ..strokeWidth = W * 0.075
          ..strokeCap  = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color      = shieldColor,
      );
    }

    // ── Phase 2: document lines (0.38 → 0.66) ───────────────────────────────
    final lRaw = _iv(progress, 0.38, 0.66);
    if (lRaw > 0) {
      const relW   = [1.00, 1.00, 1.00, 0.68];
      final xL     = sL + sW * 0.18;
      final xR     = sL + sW * 0.82;
      final fullW  = xR - xL;
      final yStart = sT + sH * 0.20;
      final yStep  = sH * 0.135;
      final lp     = Paint()
        ..style      = PaintingStyle.stroke
        ..strokeWidth = W * 0.042
        ..strokeCap  = StrokeCap.round
        ..color      = shieldColor;
      for (int i = 0; i < 4; i++) {
        final ps = i / 4, pe = (i + 1) / 4;
        if (lRaw <= ps) break;
        final lt  = Curves.easeOut.transform(((lRaw - ps) / (pe - ps)).clamp(0.0, 1.0));
        final lw  = fullW * relW[i];
        final lxL = xL + (fullW - lw) / 2;
        final y   = yStart + yStep * i;
        canvas.drawLine(Offset(lxL, y), Offset(lxL + lw * lt, y), lp);
      }
    }

    // ── Phase 3: checkmark (0.60 → 0.80) ────────────────────────────────────
    final cT     = _iv(progress, 0.60, 0.80, Curves.easeInOut);
    final ckPath = _checkmark(W, H);
    if (cT > 0) {
      // Glow pulse — only after checkmark is mostly visible
      if (cT > 0.75) {
        final glowFade = (cT - 0.75) / 0.25;
        final ga = (0.07 + 0.10 * sin(pulse * 2 * pi)).clamp(0.0, 1.0) * glowFade;
        _drawTrimmed(
          canvas,
          ckPath,
          cT,
          Paint()
            ..style      = PaintingStyle.stroke
            ..strokeWidth = W * 0.24
            ..strokeCap  = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color      = checkColor.withValues(alpha: ga)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      _drawTrimmed(
        canvas,
        ckPath,
        cT,
        Paint()
          ..style      = PaintingStyle.stroke
          ..strokeWidth = W * 0.088
          ..strokeCap  = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color      = checkColor,
      );
    }

    // ── Shield particles: fly outward after checkmark ────────────────────────
    if (progress > 0.76) {
      final cx   = sL + sW * 0.50;
      final cy   = sT + sH * 0.52;
      final pp   = Paint()..style = PaintingStyle.fill;
      for (final d in _kShieldParts) {
        final ph = (pulse + d.ph) % 1.0;
        final r  = ph * W * 0.35 * d.speed;
        final a  = ((1 - ph) * 0.50).clamp(0.0, 1.0);
        if (a < 0.02) continue;
        pp.color = checkColor.withValues(alpha: a);
        canvas.drawCircle(
          Offset(cx + cos(d.angle) * r, cy + sin(d.angle) * r),
          d.sz * (1 - ph * 0.55),
          pp,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShieldLogoPainter o) =>
      progress   != o.progress   ||
      scale      != o.scale      ||
      floatDy    != o.floatDy    ||
      pulse      != o.pulse      ||
      bgPhase    != o.bgPhase    ||
      shieldColor != o.shieldColor ||
      checkColor != o.checkColor;
}

// ── letter-by-letter widget ───────────────────────────────────────────────────

class _LetterFadeIn extends StatelessWidget {
  final String text;
  final double progress; // 0→1: cascades letters left to right
  final TextStyle style;

  const _LetterFadeIn({
    required this.text,
    required this.progress,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final chars = text.split('');
    final n     = chars.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(n, (i) {
        final t = Curves.easeOut
            .transform((progress * n - i).clamp(0.0, 1.0));
        return Transform.translate(
          offset: Offset(0, -7 * (1 - t)),
          child: Opacity(opacity: t, child: Text(chars[i], style: style)),
        );
      }),
    );
  }
}

// ── SplashPage ────────────────────────────────────────────────────────────────

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _seqCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _bgCtrl;
  late final CurvedAnimation _floatCurve;

  @override
  void initState() {
    super.initState();
    _seqCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _bgCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000));

    _floatCurve = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

    _pulseCtrl.repeat();
    _bgCtrl.repeat(reverse: true);
    _seqCtrl.forward().then((_) {
      if (mounted) _floatCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _floatCurve.dispose();
    _seqCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = AppTheme.isDark(context);
    final shieldColor = isDark ? const Color(0xFF2060C0) : const Color(0xFF0A1628);
    final checkColor  = AppTheme.sienna;
    final screenW     = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: AuroraBackdrop(
        orbAlignment: const Alignment(0.4, -0.55),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Shield logo ─────────────────────────────────────────────────
              Expanded(
                flex: 50,
                child: Center(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _seqCtrl,
                        _floatCtrl,
                        _pulseCtrl,
                        _bgCtrl,
                      ]),
                      builder: (_, __) {
                        final floatDy = (_floatCurve.value - 0.5) * 14.0;
                        final scale   = _iv(_seqCtrl.value, 0.0, 0.08, Curves.easeOutBack);
                        return SizedBox(
                          width:  screenW * 0.68,
                          height: screenW * 0.68,
                          child: CustomPaint(
                            isComplex: true,
                            painter: _ShieldLogoPainter(
                              progress:    _seqCtrl.value,
                              scale:       scale,
                              floatDy:     floatDy,
                              pulse:       _pulseCtrl.value,
                              bgPhase:     _bgCtrl.value,
                              shieldColor: shieldColor,
                              checkColor:  checkColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Text + CTA ──────────────────────────────────────────────────
              Expanded(
                flex: 50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
                  child: AnimatedBuilder(
                    animation: _seqCtrl,
                    builder: (_, __) {
                      final t = _seqCtrl.value;

                      // Timing windows (within 0→1 seq)
                      final eyebrowP  = _iv(t, 0.70, 0.86);           // letter cascade progress
                      final h1LeftT   = _iv(t, 0.82, 0.91, Curves.easeOut);
                      final h1RightT  = _iv(t, 0.86, 0.94, Curves.easeOut);
                      final subT      = _iv(t, 0.89, 0.96, Curves.easeOut);
                      final btnT      = _iv(t, 0.93, 1.00, Curves.elasticOut);

                      final eyebrowStyle =
                          AppTextStyle.eyebrow(color: AppTheme.sienna).copyWith(
                        fontSize:      11,
                        fontWeight:    FontWeight.w800,
                        letterSpacing: 3.5,
                      );

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LetterFadeIn(
                            text:     'IBAL',
                            progress: eyebrowP,
                            style:    eyebrowStyle,
                          ),

                          const SizedBox(height: 8),

                          // "Your cover," — slide in from left
                          Transform.translate(
                            offset: Offset(-40 * (1 - h1LeftT), 0),
                            child: Opacity(
                              opacity: h1LeftT,
                              child: Text(
                                'Your cover,',
                                textAlign: TextAlign.center,
                                style: AppTextStyle.h1(color: AppTheme.ink(context)),
                              ),
                            ),
                          ),

                          // "the right way." — slide in from right
                          Transform.translate(
                            offset: Offset(40 * (1 - h1RightT), 0),
                            child: Opacity(
                              opacity: h1RightT,
                              child: Text(
                                'the right way.',
                                textAlign: TextAlign.center,
                                style: AppTextStyle.h1(color: AppTheme.sienna),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle — fade up with dissolve blur
                          Transform.translate(
                            offset: Offset(0, 20 * (1 - subT)),
                            child: Opacity(
                              opacity: subT,
                              child: ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(
                                  sigmaX: (1 - subT) * 5,
                                  sigmaY: (1 - subT) * 5,
                                ),
                                child: Text(
                                  'Intelligent insurance management\n'
                                  'built for modern professionals.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyle.bodyMedium(
                                      color: AppTheme.muted(context)),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Button — scale up with elastic bounce
                          Transform.scale(
                            scale: btnT,
                            child: GestureDetector(
                              onTap: _navigate,
                              child: Container(
                                height:  50,
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: AppTheme.sienna.withValues(alpha: 0.70),
                                    width: 1.5,
                                  ),
                                  boxShadow: isDark
                                      ? [
                                          BoxShadow(
                                            color:       AppTheme.sienna.withValues(alpha: 0.22),
                                            blurRadius:  26,
                                            spreadRadius: -2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Get Started',
                                        style: AppTextStyle.button(
                                            color: AppTheme.sienna)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 16, color: AppTheme.sienna),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
