import 'dart:math';
import 'package:flutter/material.dart';

/// Animated 3-D wire-mesh nautilus / ammonite spiral.
///
/// The spiral lies in the XY plane (viewed nearly face-on, like an ammonite
/// fossil). Tube cross-sections extend into the Z depth axis, revealed by a
/// small fixed rotX tilt. A slow Y-axis spin and gentle float are animated.
class WireMeshSpiral extends StatefulWidget {
  final Color color;
  final double size;

  const WireMeshSpiral({super.key, required this.color, this.size = 280});

  @override
  State<WireMeshSpiral> createState() => _WireMeshSpiralState();
}

class _WireMeshSpiralState extends State<WireMeshSpiral>
    with TickerProviderStateMixin {
  late final AnimationController _rotCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _rot;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();

    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _rot = Tween<double>(begin: 0, end: 2 * pi).animate(_rotCtrl);

    _float = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rot, _float]),
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _float.value),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _NautilusPainter(
              color: widget.color,
              rotYanim: _rot.value,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NautilusPainter extends CustomPainter {
  final Color color;
  final double rotYanim;

  _NautilusPainter({required this.color, required this.rotYanim});

  @override
  void paint(Canvas canvas, Size size) {
    // ── shape constants ───────────────────────────────────────
    const nU = 64;      // arc samples along the spiral
    const nV = 20;      // samples around the tube cross-section
    const nTurns = 3.5; // full spiral revolutions (outer → inner)
    const b = -0.11;    // log-spiral decay constant (each turn ≈ halves R)

    // Precompute normal-vector normalisation factor: √(1 + b²)
    final sqrtBSq = sqrt(1.0 + b * b); // ≈ 1.006

    // ── viewing angles ────────────────────────────────────────
    // rotX is fixed: small downward tilt that reveals the Z depth of the tube.
    // rotY is the animated spin.
    const rotX = 0.18;             // ≈ 10° fixed tilt
    final rotY = -0.25 + rotYanim; // animated full Y rotation

    final s = min(size.width, size.height);
    final R0 = s * 0.38;   // outer-most spiral radius
    final cx = size.width * 0.50;
    final cy = size.height * 0.50;
    final fov = s * 2.8;   // perspective focal length

    // ── vertex grid ───────────────────────────────────────────
    final verts = List.generate(nU + 1, (_) => <Offset>[]);
    final zdepths = List.generate(nU + 1, (_) => <double>[]);

    for (int ui = 0; ui <= nU; ui++) {
      final t = ui / nU * nTurns * 2 * pi;

      // Logarithmic spiral: radius shrinks as t grows (b is negative)
      final R = R0 * exp(b * t);
      final r = R * 0.25; // tube radius = 25 % of spiral radius at this step

      // Outward-pointing in-plane normal to the log-spiral tangent.
      //
      // For  P(t) = R(t)·(cos t, sin t)  with  R(t) = R₀·eᵇᵗ:
      //   tangent direction ∝ (b·cos t − sin t,  b·sin t + cos t)
      //   CW 90° rotation gives the outward normal (outward for b < 0):
      //   N = ( (b·sin t + cos t),  (sin t − b·cos t) ) / √(1+b²)
      final Nx = (b * sin(t) + cos(t)) / sqrtBSq;
      final Ny = (sin(t) - b * cos(t)) / sqrtBSq;

      for (int vi = 0; vi <= nV; vi++) {
        final phi = vi / nV * 2 * pi;

        // ── 3-D tube surface point ─────────────────────────────
        //
        // Cross-section lies in the (N, Z) plane:
        //   cos(phi) * N  →  visible face-on as the "arm width"
        //   sin(phi) * Ẑ  →  depth, revealed by the rotX tilt
        double px = R * cos(t) + r * Nx * cos(phi);
        double py = R * sin(t) + r * Ny * cos(phi);
        double pz = r * sin(phi); // ← depth component

        // Rotate around X axis (fixed tilt to show depth)
        final py2 = py * cos(rotX) - pz * sin(rotX);
        final pz2 = py * sin(rotX) + pz * cos(rotX);

        // Rotate around Y axis (animated spin; py2 is unchanged by rotY)
        final px3 = px * cos(rotY) + pz2 * sin(rotY);
        final pz3 = -px * sin(rotY) + pz2 * cos(rotY);

        // Perspective projection
        final persp = fov / (fov + pz3);
        verts[ui].add(Offset(cx + px3 * persp, cy + py2 * persp));
        zdepths[ui].add(pz3);
      }
    }

    // ── depth normalisation ───────────────────────────────────
    double minZ = double.infinity, maxZ = double.negativeInfinity;
    for (final row in zdepths) {
      for (final d in row) {
        if (d < minZ) minZ = d;
        if (d > maxZ) maxZ = d;
      }
    }
    final zRange = maxZ - minZ;
    double normZ(double z) => zRange > 0 ? (z - minZ) / zRange : 0.5;

    // ── mesh lines ────────────────────────────────────────────
    // Two families: rings around the tube (vi direction) and
    // spiral arms along the arc (ui direction).
    for (int ui = 0; ui < nU; ui++) {
      for (int vi = 0; vi < nV; vi++) {
        final d = normZ(zdepths[ui][vi]);
        final a = (0.08 + d * 0.60).clamp(0.0, 1.0);
        final lp = Paint()
          ..color = color.withValues(alpha: a * 0.55)
          ..strokeWidth = 0.6
          ..style = PaintingStyle.stroke;
        canvas.drawLine(verts[ui][vi], verts[ui][vi + 1], lp); // ring
        canvas.drawLine(verts[ui][vi], verts[ui + 1][vi], lp); // arm
      }
    }

    // ── glowing dots at every-other vertex ───────────────────
    // Blur is applied only to the front-facing dots (d > 0.68)
    // to keep per-frame cost manageable.
    for (int ui = 0; ui <= nU; ui += 2) {
      for (int vi = 0; vi <= nV; vi += 2) {
        final d = normZ(zdepths[ui][vi]);
        final a = (0.15 + d * 0.85).clamp(0.0, 1.0);
        final r2 = (0.7 + d * 2.2).clamp(0.7, 2.9);

        if (d > 0.68) {
          canvas.drawCircle(
            verts[ui][vi],
            r2 * 3.0,
            Paint()
              ..color = color.withValues(alpha: a * 0.18)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5),
          );
        }

        canvas.drawCircle(
          verts[ui][vi],
          r2,
          Paint()
            ..color = color.withValues(alpha: a)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_NautilusPainter old) =>
      color != old.color || rotYanim != old.rotYanim;
}
