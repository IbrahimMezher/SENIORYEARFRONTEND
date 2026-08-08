import 'dart:math';
import 'package:flutter/material.dart';

// ─── Box geometry ─────────────────────────────────────────────────────────────
//
// The letter 'I' is decomposed into three rectangular boxes that together form
// an I-beam profile.  Each box is described by its axis-aligned bounding
// coordinates plus grid-subdivision counts (nx, ny, nz) that control how many
// wire-mesh cells appear on each face.
//
// Coordinate space: Y-up, Z towards viewer, all values roughly in [−0.5, 0.5].

class _Box {
  final double x0, y0, z0, x1, y1, z1;
  final int nx, ny, nz;
  const _Box(this.x0, this.y0, this.z0, this.x1, this.y1, this.z1,
      this.nx, this.ny, this.nz);
}

const _kLetterI = <_Box>[
  _Box(-0.38, 0.36, -0.14, 0.38, 0.50, 0.14, 8, 2, 2), // top cap
  _Box(-0.11, -0.36, -0.14, 0.11, 0.36, 0.14, 2, 8, 2), // vertical stem
  _Box(-0.38, -0.50, -0.14, 0.38, -0.36, 0.14, 8, 2, 2), // bottom cap
];

// ─── Splash screen ────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotCtrl;
  late final Animation<double> _rot;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _rot = Tween<double>(begin: 0.0, end: 2 * pi).animate(_rotCtrl);
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const bgColor   = Color(0xFF0A0E21); // dark navy
    const meshColor = Color(0xFF00C8CC); // cyan

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _rot,
          builder: (_, __) => SizedBox(
            width:  w * 0.74,
            height: w * 0.74,
            child: CustomPaint(
              painter: _LetterIPainter(color: meshColor, rotY: _rot.value),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _LetterIPainter extends CustomPainter {
  final Color color;
  final double rotY;

  // A slight downward tilt so the viewer sees the top face's depth.
  static const double _kRotX = 0.22; // ≈ 13°
  // Perspective focal distance in normalised units (larger = less distortion).
  static const double _kFov = 3.2;

  _LetterIPainter({required this.color, required this.rotY});

  @override
  void paint(Canvas canvas, Size size) {
    final s  = min(size.width, size.height) * 0.46; // world → pixel scale
    final cx = size.width  / 2;
    final cy = size.height / 2;

    // Precompute trig once per frame
    final cosX = cos(_kRotX);
    final sinX = sin(_kRotX);
    final cosY = cos(rotY);
    final sinY = sin(rotY);

    // ── Transform + project one 3-D point ────────────────────────────────────
    // Rotation order: rotX (fixed tilt) → rotY (animated spin).
    Offset proj(double x, double y, double z) {
      final y1 = y * cosX - z * sinX;
      final z1 = y * sinX + z * cosX;
      final x2 = x * cosY + z1 * sinY;
      final pz = -x * sinY + z1 * cosY;
      final w  = _kFov / (_kFov + pz);
      return Offset(cx + x2 * s * w, cy - y1 * s * w);
    }

    // Camera-space Z used for depth shading.
    // Smaller value = closer to viewer = front face.
    double camZ(double x, double y, double z) {
      final z1 = y * sinX + z * cosX;
      return -x * sinY + z1 * cosY;
    }

    // ── Pass 1: determine global depth range across all boxes ─────────────────
    // Normalise depth globally so alpha is consistent between the three boxes.
    double minD = double.infinity;
    double maxD = double.negativeInfinity;
    for (final b in _kLetterI) {
      for (int xi = 0; xi <= b.nx; xi++) {
        for (int yi = 0; yi <= b.ny; yi++) {
          for (int zi = 0; zi <= b.nz; zi++) {
            final d = camZ(
              b.x0 + (b.x1 - b.x0) * xi / b.nx,
              b.y0 + (b.y1 - b.y0) * yi / b.ny,
              b.z0 + (b.z1 - b.z0) * zi / b.nz,
            );
            if (d < minD) minD = d;
            if (d > maxD) maxD = d;
          }
        }
      }
    }
    final dRange = (maxD - minD).clamp(1e-6, double.infinity);

    // nd → 1 = closest (bright), 0 = farthest (dim)
    double nd(double d) => 1.0 - (d - minD) / dRange;

    // ── Pass 2: build vertex cache + render each box ──────────────────────────
    for (final b in _kLetterI) {
      final dx  = b.x1 - b.x0;
      final dy  = b.y1 - b.y0;
      final dz  = b.z1 - b.z0;
      final nx1 = b.nx + 1;
      final ny1 = b.ny + 1;
      final nz1 = b.nz + 1;

      // Flat vertex arrays indexed by ix(xi,yi,zi)
      final total = nx1 * ny1 * nz1;
      final pts = List<Offset>.filled(total, Offset.zero);
      final nds = List<double>.filled(total, 0.0);

      int ix(int xi, int yi, int zi) => xi * ny1 * nz1 + yi * nz1 + zi;

      for (int xi = 0; xi < nx1; xi++) {
        for (int yi = 0; yi < ny1; yi++) {
          for (int zi = 0; zi < nz1; zi++) {
            final x = b.x0 + dx * xi / b.nx;
            final y = b.y0 + dy * yi / b.ny;
            final z = b.z0 + dz * zi / b.nz;
            final i = ix(xi, yi, zi);
            pts[i] = proj(x, y, z);
            nds[i] = nd(camZ(x, y, z));
          }
        }
      }

      // ── Wire-mesh lines ─────────────────────────────────────────────────────
      final lp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.65;

      for (int xi = 0; xi < nx1; xi++) {
        for (int yi = 0; yi < ny1; yi++) {
          for (int zi = 0; zi < nz1; zi++) {
            final i = ix(xi, yi, zi);
            final p = pts[i];
            final d = nds[i];

            void seg(int j) {
              final a = (0.10 + (d + nds[j]) * 0.5 * 0.76).clamp(0.0, 1.0);
              lp.color = color.withValues(alpha: a * 0.58);
              canvas.drawLine(p, pts[j], lp);
            }

            if (xi < b.nx) seg(ix(xi + 1, yi, zi));
            if (yi < b.ny) seg(ix(xi, yi + 1, zi));
            if (zi < b.nz) seg(ix(xi, yi, zi + 1));
          }
        }
      }

      // ── Glowing dots at grid vertices ────────────────────────────────────────
      // MaskFilter.blur is expensive; restrict glow to the front-facing ⅓.
      for (int xi = 0; xi < nx1; xi++) {
        for (int yi = 0; yi < ny1; yi++) {
          for (int zi = 0; zi < nz1; zi++) {
            final i = ix(xi, yi, zi);
            final p = pts[i];
            final d = nds[i];
            final a = (0.15 + d * 0.85).clamp(0.0, 1.0);
            final r = 0.55 + d * 1.9; // dots grow as they approach the viewer

            if (d > 0.60) {
              canvas.drawCircle(
                p, r * 3.6,
                Paint()
                  ..color = color.withValues(alpha: a * 0.22)
                  ..maskFilter =
                      const MaskFilter.blur(BlurStyle.normal, 6.0),
              );
            }

            canvas.drawCircle(
              p, r,
              Paint()
                ..color = color.withValues(alpha: a)
                ..style = PaintingStyle.fill,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LetterIPainter old) =>
      rotY != old.rotY || color != old.color;
}
