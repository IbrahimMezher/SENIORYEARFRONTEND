import 'dart:math';
import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════════════
//  I.A. INSURANCE — PREMIUM WIREFRAME LOGO
//  lib/core/widgets/ia_logo.dart
//
//  Deliverables in this file
//  ─────────────────────────
//  1. IALogoPainter        Flutter CustomPainter (drop into any CustomPaint)
//  2. IALogo               Responsive widget — static or slow-spin animated
//  3. generateIaLogoSvg()  Returns a fully-editable SVG string
//
//  Visual specification
//  ────────────────────
//  • Colour      #33C6D8  (turquoise)
//  • Lines       0.55 px  hairline mesh strokes, round caps — no glow
//  • Nodes       1.2 px   filled circles at EVERY grid vertex intersection
//  • Alpha       depth-attenuated (near ≈ 1.0, far ≈ 0.18) for 3-D depth cue
//  • Background  transparent — no fill, no gradient, no shadow
//
//  Letter geometry
//  ───────────────
//  "I"  3 axis-aligned boxes   (top cap · stem · bottom cap)
//  "A"  7 bilinear patches     with progressive Z-twist → ribbon/scroll effect
//  "."  Small cube (×2)
//
//  All vertex positions are computed mathematically from subdivision counts.
//  No random or manually placed points.  Bezier-quality smoothness comes from
//  fine subdivision (nv ≥ 7 on legs) rather than explicit spline segments.
// ════════════════════════════════════════════════════════════════════════════

// ─── Shared projection constants ─────────────────────────────────────────────

/// Fixed downward tilt (≈10°) — reveals the top face of every letter.
const double _kRotX = 0.18;

/// Perspective focal length.  Higher value = less barrel distortion.
const double _kFov  = 3.8;

// ─── Geometry primitives ─────────────────────────────────────────────────────

/// Axis-aligned rectangular box subdivided into [nx]×[ny]×[nz] cells.
/// Edges are drawn between every adjacent pair of grid vertices.
class _Box {
  final double x0, y0, z0, x1, y1, z1;
  final int nx, ny, nz;
  const _Box(this.x0, this.y0, this.z0, this.x1, this.y1, this.z1,
      this.nx, this.ny, this.nz);
}

/// Bilinear quad patch in XY, extruded linearly in Z, with an optional
/// per-vertex Z-twist that creates a ribbon-scroll effect.
///
/// Corner labelling (u = 0..1 left→right, v = 0..1 bottom→top):
///   (x00,y00)=BL  (x10,y10)=BR  (x01,y01)=TL  (x11,y11)=TR
///
/// [twist] adds `twist × (u − 0.5) × v` to every vertex's Z coordinate.
/// At v=0 (bottom row) the surface is flat; at v=1 (top row) the left edge
/// is deflected by −twist/2 and the right edge by +twist/2, rolling the
/// face like a ribbon.  Use opposing signs on mirrored leg pairs.
class _Patch {
  final double x00, y00, x10, y10, x01, y01, x11, y11;
  final double z0, z1;
  final int nu, nv, nz;
  final double twist;

  const _Patch(
    this.x00, this.y00,
    this.x10, this.y10,
    this.x01, this.y01,
    this.x11, this.y11,
    this.z0,  this.z1,
    this.nu,  this.nv,  this.nz, {
    this.twist = 0.0,
  });
}

// ─── Letter "I" ──────────────────────────────────────────────────────────────
//
// Three axis-aligned boxes forming a classic I-beam column.
// Coordinate system: Y-up, units span ≈ [−0.5, +0.5] in every axis.
// Z-depth ±0.22 ensures the side faces are visible under the projection.
const _kLetterI = <_Box>[
  _Box(-0.36,  0.34, -0.22,  0.36,  0.50, 0.22,  9,  2, 4), // top cap
  _Box(-0.13, -0.34, -0.22,  0.13,  0.34, 0.22,  3, 11, 4), // stem
  _Box(-0.36, -0.50, -0.22,  0.36, -0.34, 0.22,  9,  2, 4), // bottom cap
];

// ─── Period "." ──────────────────────────────────────────────────────────────
const _kPeriod = <_Box>[
  _Box(-0.07, -0.50, -0.07, 0.07, -0.28, 0.07, 2, 3, 2),
];

// ─── Letter "A" ──────────────────────────────────────────────────────────────
//
// Seven seamlessly-connected bilinear patches.
//
// Connectivity — every junction pair shares the same XY coordinates so the
// wire mesh is continuous across patch boundaries:
//
//   lower-leg-top   = upper-arm-bottom  (y = −0.04)
//   upper-arm-top   = arch-bottom       (y = +0.26)
//   left-arch-top   = right-arch-top    = apex (0.00, 0.50)
//
// The [twist] parameter on leg and arm patches causes the mesh surface to
// roll like a ribbon as v increases, producing the organic sculptural quality
// visible in the reference image.  The crossbar has no twist (flat element).
const _kLetterA = <_Patch>[
  // ── Left lower leg: wide at base, tapers toward crossbar height ───────────
  // BL(−0.38,−0.50)  BR(−0.16,−0.50)  TL(−0.22,−0.04)  TR(−0.08,−0.04)
  _Patch(-0.38,-0.50, -0.16,-0.50, -0.22,-0.04, -0.08,-0.04,
         -0.22, 0.22, 4, 8, 4, twist:  0.18),

  // ── Right lower leg: mirror of left ──────────────────────────────────────
  _Patch( 0.16,-0.50,  0.38,-0.50,  0.08,-0.04,  0.22,-0.04,
         -0.22, 0.22, 4, 8, 4, twist: -0.18),

  // ── Left upper arm: continues from leg top, narrows toward arch ───────────
  // BL(−0.22,−0.04)  BR(−0.08,−0.04)  TL(−0.11,+0.26)  TR(−0.01,+0.26)
  _Patch(-0.22,-0.04, -0.08,-0.04, -0.11, 0.26, -0.01, 0.26,
         -0.22, 0.22, 3, 6, 4, twist:  0.12),

  // ── Right upper arm: mirror ───────────────────────────────────────────────
  _Patch( 0.08,-0.04,  0.22,-0.04,  0.01, 0.26,  0.11, 0.26,
         -0.22, 0.22, 3, 6, 4, twist: -0.12),

  // ── Left arch: curves from arm top up to the rounded apex ────────────────
  // BL(−0.11,+0.26)  BR(−0.01,+0.26)  TL(−0.04,+0.48)  TR(0.00,+0.50)
  _Patch(-0.11, 0.26, -0.01, 0.26, -0.04, 0.48,  0.00, 0.50,
         -0.22, 0.22, 3, 4, 4, twist:  0.06),

  // ── Right arch: mirror, shares apex (0.00, 0.50) with left arch TR/TL ────
  _Patch( 0.01, 0.26,  0.11, 0.26,  0.00, 0.50,  0.04, 0.48,
         -0.22, 0.22, 3, 4, 4, twist: -0.06),

  // ── Crossbar: flat horizontal element, no twist ───────────────────────────
  _Patch(-0.24,-0.12,  0.24,-0.12, -0.24, 0.04,  0.24, 0.04,
         -0.22, 0.22, 10, 2, 4),
];

// ─── Layout: x-offsets for "I.A." character sequence ─────────────────────────
const double _xI    = -0.60; // letter I
const double _xDot1 = -0.08; // period after I
const double _xA    =  0.42; // letter A
const double _xDot2 =  0.95; // period after A

// ─── Low-level projection helpers (shared by painter + SVG generator) ────────

/// Projects a 3-D point to 2-D canvas coordinates (Y-up world → Y-down screen).
List<double> _proj3d(
    double x, double y, double z, double xOff,
    double cosX, double sinX, double cosY, double sinY,
    double s, double cx, double cy) {
  final xp = x + xOff;
  final y1 = y * cosX - z * sinX;
  final z1 = y * sinX + z * cosX;
  final x2 = xp * cosY + z1 * sinY;
  final pz = -xp * sinY + z1 * cosY;
  final w  = _kFov / (_kFov + pz);
  return [cx + x2 * s * w, cy - y1 * s * w];
}

/// Camera-space Z — used for depth sorting and alpha attenuation.
double _camZ3d(
    double x, double y, double z, double xOff,
    double sinX, double cosX, double sinY, double cosY) {
  final xp = x + xOff;
  final z1 = y * sinX + z * cosX;
  return -xp * sinY + z1 * cosY;
}

// ════════════════════════════════════════════════════════════════════════════
//  1.  IALogoPainter  — Flutter CustomPainter
// ════════════════════════════════════════════════════════════════════════════

/// Renders the I.A. wireframe logo on a Flutter [Canvas].
///
/// All vertex positions are computed every frame from the subdivision grid.
/// Depth-attenuated alpha gives the 3-D depth cue (no shadows, no glow).
///
/// ```dart
/// CustomPaint(
///   painter: IALogoPainter(rotY: 0.30),
///   size: const Size(400, 220),
/// )
/// ```
class IALogoPainter extends CustomPainter {
  /// Mesh line + node colour.  Defaults to brand turquoise #33C6D8.
  final Color meshColor;

  /// Y-axis rotation angle in radians.  Feed an [Animation<double>] for spin,
  /// or use a fixed value for a static logo.
  final double rotY;

  /// Stroke width for mesh lines.  Keep ≤ 0.8 for a premium hairline feel.
  final double strokeWidth;

  /// Radius of the vertex-node circles.
  final double nodeRadius;

  const IALogoPainter({
    this.meshColor  = const Color(0xFF33C6D8),
    this.rotY       = 0.30,
    this.strokeWidth = 0.55,
    this.nodeRadius  = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale so the full ~2.0-unit-wide logo fills ≈88% of the widget width.
    final s  = size.width * 0.42;
    final cx = size.width  / 2;
    final cy = size.height / 2;

    final cosX = cos(_kRotX), sinX = sin(_kRotX);
    final cosY = cos(rotY),   sinY = sin(rotY);

    // ── Convenience closures ──────────────────────────────────────────────────

    Offset proj(double x, double y, double z, double xOff) {
      final p = _proj3d(x, y, z, xOff, cosX, sinX, cosY, sinY, s, cx, cy);
      return Offset(p[0], p[1]);
    }

    double camZ(double x, double y, double z, double xOff) =>
        _camZ3d(x, y, z, xOff, sinX, cosX, sinY, cosY);

    // ── Pass 1: determine global depth range ──────────────────────────────────
    // Normalising across ALL characters keeps alpha consistent throughout.
    double minD = double.infinity, maxD = double.negativeInfinity;

    void scanBoxes(List<_Box> boxes, double xOff) {
      for (final b in boxes) {
        for (int xi = 0; xi <= b.nx; xi++) {
          for (int yi = 0; yi <= b.ny; yi++) {
            for (int zi = 0; zi <= b.nz; zi++) {
              final d = camZ(
                b.x0 + (b.x1 - b.x0) * xi / b.nx,
                b.y0 + (b.y1 - b.y0) * yi / b.ny,
                b.z0 + (b.z1 - b.z0) * zi / b.nz,
                xOff,
              );
              if (d < minD) minD = d;
              if (d > maxD) maxD = d;
            }
          }
        }
      }
    }

    void scanPatches(List<_Patch> patches, double xOff) {
      for (final p in patches) {
        for (int ui = 0; ui <= p.nu; ui++) {
          for (int vi = 0; vi <= p.nv; vi++) {
            final u = ui / p.nu, v = vi / p.nv;
            final bx = p.x00*(1-u)*(1-v) + p.x10*u*(1-v)
                     + p.x01*(1-u)*v    + p.x11*u*v;
            final by = p.y00*(1-u)*(1-v) + p.y10*u*(1-v)
                     + p.y01*(1-u)*v    + p.y11*u*v;
            for (int zi = 0; zi <= p.nz; zi++) {
              final tz = p.twist * (u - 0.5) * v;
              final z  = p.z0 + (p.z1 - p.z0) * zi / p.nz + tz;
              final d  = camZ(bx, by, z, xOff);
              if (d < minD) minD = d;
              if (d > maxD) maxD = d;
            }
          }
        }
      }
    }

    scanBoxes(_kLetterI, _xI);
    scanBoxes(_kPeriod,  _xDot1);
    scanPatches(_kLetterA, _xA);
    scanBoxes(_kPeriod,  _xDot2);

    final dRange = (maxD - minD).clamp(1e-6, double.infinity);

    // nd(d) → 1.0 = front/near (fully opaque), 0.0 = back/far (translucent)
    double nd(double d) => 1.0 - (d - minD) / dRange;

    // ── Alpha functions ───────────────────────────────────────────────────────
    // Line alpha uses the average depth of both endpoints.
    // Near-face lines: ~90 % opaque.  Back-face lines: ~18 % opaque.
    double lineA(double da, double db) =>
        ((da + db) * 0.5 * 0.72 + 0.18).clamp(0.0, 1.0);

    // Node alpha: front nodes are solid; back nodes fade to 20 %.
    double nodeA(double d) => (d * 0.80 + 0.20).clamp(0.0, 1.0);

    // ── Shared paint objects (mutated per draw call for zero allocation) ──────
    final lp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final np = Paint()..style = PaintingStyle.fill;

    void drawEdge(Offset a, Offset b, double da, double db) {
      lp.color = meshColor.withValues(alpha: lineA(da, db));
      canvas.drawLine(a, b, lp);
    }

    void drawNode(Offset pt, double d) {
      np.color = meshColor.withValues(alpha: nodeA(d));
      canvas.drawCircle(pt, nodeRadius, np);
    }

    // ── Pass 2a: render axis-aligned boxes ────────────────────────────────────
    void renderBoxes(List<_Box> boxes, double xOff) {
      for (final b in boxes) {
        final nx1 = b.nx + 1, ny1 = b.ny + 1, nz1 = b.nz + 1;
        final N   = nx1 * ny1 * nz1;
        final pts = List<Offset>.filled(N, Offset.zero);
        final nds = List<double>.filled(N, 0.0);

        // Flat 3-D index: [xi, yi, zi] → linear slot
        int idx(int xi, int yi, int zi) => xi * ny1 * nz1 + yi * nz1 + zi;

        // Build vertex cache (project once, reuse for all edges through vertex)
        for (int xi = 0; xi < nx1; xi++) {
          for (int yi = 0; yi < ny1; yi++) {
            for (int zi = 0; zi < nz1; zi++) {
              final x = b.x0 + (b.x1 - b.x0) * xi / b.nx;
              final y = b.y0 + (b.y1 - b.y0) * yi / b.ny;
              final z = b.z0 + (b.z1 - b.z0) * zi / b.nz;
              final i = idx(xi, yi, zi);
              pts[i] = proj(x, y, z, xOff);
              nds[i] = nd(camZ(x, y, z, xOff));
            }
          }
        }

        // Draw edges in all three axis directions
        for (int xi = 0; xi < nx1; xi++) {
          for (int yi = 0; yi < ny1; yi++) {
            for (int zi = 0; zi < nz1; zi++) {
              final i = idx(xi, yi, zi);
              if (xi < b.nx) drawEdge(pts[i], pts[idx(xi+1,yi,zi)],   nds[i], nds[idx(xi+1,yi,zi)]);
              if (yi < b.ny) drawEdge(pts[i], pts[idx(xi,yi+1,zi)],   nds[i], nds[idx(xi,yi+1,zi)]);
              if (zi < b.nz) drawEdge(pts[i], pts[idx(xi,yi,zi+1)],   nds[i], nds[idx(xi,yi,zi+1)]);
            }
          }
        }

        // Draw a node at every grid vertex
        for (int i = 0; i < N; i++) { drawNode(pts[i], nds[i]); }
      }
    }

    // ── Pass 2b: render bilinear patches (with Z-twist) ───────────────────────
    void renderPatches(List<_Patch> patches, double xOff) {
      for (final p in patches) {
        final nu1 = p.nu + 1, nv1 = p.nv + 1, nz1 = p.nz + 1;
        final N   = nu1 * nv1 * nz1;
        final pts = List<Offset>.filled(N, Offset.zero);
        final nds = List<double>.filled(N, 0.0);

        int idx(int ui, int vi, int zi) => ui * nv1 * nz1 + vi * nz1 + zi;

        // Build vertex cache with bilinear XY interpolation + Z-twist
        for (int ui = 0; ui <= p.nu; ui++) {
          for (int vi = 0; vi <= p.nv; vi++) {
            final u = ui / p.nu, v = vi / p.nv;
            // Bilinear interpolation for XY surface position
            final bx = p.x00*(1-u)*(1-v) + p.x10*u*(1-v)
                     + p.x01*(1-u)*v    + p.x11*u*v;
            final by = p.y00*(1-u)*(1-v) + p.y10*u*(1-v)
                     + p.y01*(1-u)*v    + p.y11*u*v;
            for (int zi = 0; zi <= p.nz; zi++) {
              // Z-twist: deflects z by (u-0.5)×v×twist
              // → bottom row (v=0) stays flat; top row (v=1) ribbon-rolls
              final tz = p.twist * (u - 0.5) * v;
              final z  = p.z0 + (p.z1 - p.z0) * zi / p.nz + tz;
              final i  = idx(ui, vi, zi);
              pts[i] = proj(bx, by, z, xOff);
              nds[i] = nd(camZ(bx, by, z, xOff));
            }
          }
        }

        // Draw edges
        for (int ui = 0; ui <= p.nu; ui++) {
          for (int vi = 0; vi <= p.nv; vi++) {
            for (int zi = 0; zi <= p.nz; zi++) {
              final i = idx(ui, vi, zi);
              if (ui < p.nu) drawEdge(pts[i], pts[idx(ui+1,vi,zi)], nds[i], nds[idx(ui+1,vi,zi)]);
              if (vi < p.nv) drawEdge(pts[i], pts[idx(ui,vi+1,zi)], nds[i], nds[idx(ui,vi+1,zi)]);
              if (zi < p.nz) drawEdge(pts[i], pts[idx(ui,vi,zi+1)], nds[i], nds[idx(ui,vi,zi+1)]);
            }
          }
        }

        // Draw a node at every grid vertex
        for (int i = 0; i < N; i++) { drawNode(pts[i], nds[i]); }
      }
    }

    // Render character sequence: I · A ·
    renderBoxes(_kLetterI,  _xI);
    renderBoxes(_kPeriod,   _xDot1);
    renderPatches(_kLetterA, _xA);
    renderBoxes(_kPeriod,   _xDot2);
  }

  @override
  bool shouldRepaint(IALogoPainter old) =>
      rotY != old.rotY || meshColor != old.meshColor;
}

// ════════════════════════════════════════════════════════════════════════════
//  2.  IALogo  —  Responsive Flutter Widget
// ════════════════════════════════════════════════════════════════════════════

/// Responsive I.A. wireframe logo widget.
///
/// Adapts to any available width while maintaining the logo's natural
/// aspect ratio (width : height ≈ 1.82 : 1).
///
/// **Static (brand assets, app bars):**
/// ```dart
/// IALogo(width: 220)
/// ```
///
/// **Animated (splash screens, hero sections):**
/// ```dart
/// IALogo(width: 320, animate: true)
/// ```
///
/// **Custom colour (white-label):**
/// ```dart
/// IALogo(color: Color(0xFFFFFFFF), animate: true)
/// ```
class IALogo extends StatefulWidget {
  /// Explicit pixel width.  When null the widget expands to available width.
  final double? width;

  /// Wire colour.  Defaults to brand turquoise #33C6D8.
  final Color color;

  /// When true the logo slowly rotates around its Y-axis.
  final bool animate;

  /// Fixed Y-rotation angle (radians) used when [animate] is false.
  /// Default 0.30 rad ≈ 17° — shows side faces nicely at rest.
  final double angle;

  /// Full-revolution period for the animated mode.
  final Duration period;

  /// Stroke width of mesh lines (0.55 = hairline premium; 1.0 = bolder).
  final double strokeWidth;

  /// Radius of vertex node circles (1.2 = fine detail; 2.0 = more prominent).
  final double nodeRadius;

  const IALogo({
    super.key,
    this.width,
    this.color       = const Color(0xFF33C6D8),
    this.animate     = false,
    this.angle       = 0.30,
    this.period      = const Duration(seconds: 12),
    this.strokeWidth = 0.55,
    this.nodeRadius  = 1.2,
  });

  @override
  State<IALogo> createState() => _IALogoState();
}

class _IALogoState extends State<IALogo>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  Animation<double>?   _rot;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void didUpdateWidget(IALogo old) {
    super.didUpdateWidget(old);
    if (old.animate != widget.animate || old.period != widget.period) {
      _ctrl?.dispose();
      _ctrl = null;
      _rot  = null;
      _boot();
    }
  }

  void _boot() {
    if (!widget.animate) return;
    _ctrl = AnimationController(vsync: this, duration: widget.period)..repeat();
    // Left-to-right rotation (negative end value)
    _rot = Tween<double>(begin: 0.0, end: -2 * pi).animate(_ctrl!);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = widget.width ?? constraints.maxWidth;
      final h = w * 0.55; // natural aspect ratio ≈ 1.82:1

      final painter = IALogoPainter(
        meshColor:   widget.color,
        strokeWidth: widget.strokeWidth,
        nodeRadius:  widget.nodeRadius,
        rotY: widget.animate ? (_rot?.value ?? widget.angle) : widget.angle,
      );

      if (!widget.animate) {
        return SizedBox(
          width: w, height: h,
          child: CustomPaint(painter: painter),
        );
      }

      return AnimatedBuilder(
        animation: _rot!,
        builder: (_, __) => SizedBox(
          width: w, height: h,
          child: CustomPaint(
            painter: IALogoPainter(
              meshColor:   widget.color,
              strokeWidth: widget.strokeWidth,
              nodeRadius:  widget.nodeRadius,
              rotY: _rot!.value,
            ),
          ),
        ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  3.  generateIaLogoSvg  —  Fully-editable SVG output
// ════════════════════════════════════════════════════════════════════════════

/// Generates a fully-editable, transparent-background SVG of the logo.
///
/// The SVG uses the SAME parametric geometry as [IALogoPainter]:
///   - `<line>` elements for every mesh edge  (opacity-coded by depth)
///   - `<circle>` elements for every vertex node
///   - Named `<g>` groups for Illustrator / Inkscape editing:
///       #ia-lines-I, #ia-lines-A, #ia-nodes-I, #ia-nodes-A, etc.
///
/// **How to generate the SVG file:**
/// ```dart
/// import 'dart:io';
/// // In a Dart script / integration test / build_runner action:
/// final svg = generateIaLogoSvg();
/// File('assets/logos/ia_logo.svg').writeAsStringSync(svg);
/// ```
///
/// **Use in Flutter with flutter_svg:**
/// ```dart
/// SvgPicture.asset('assets/logos/ia_logo.svg', width: 240)
/// ```
String generateIaLogoSvg({
  double svgWidth    = 800,
  double svgHeight   = 440,
  double rotY        = 0.30,
  String color       = '#33C6D8',
  double strokeWidth = 1.0,
  double nodeRadius  = 2.0,
}) {
  final s  = svgWidth * 0.42;
  final cx = svgWidth  / 2;
  final cy = svgHeight / 2;

  final cosX = cos(_kRotX), sinX = sin(_kRotX);
  final cosY = cos(rotY),   sinY = sin(rotY);

  List<double> proj(double x, double y, double z, double xOff) =>
      _proj3d(x, y, z, xOff, cosX, sinX, cosY, sinY, s, cx, cy);

  double camZ(double x, double y, double z, double xOff) =>
      _camZ3d(x, y, z, xOff, sinX, cosX, sinY, cosY);

  // ── Depth range scan ──────────────────────────────────────────────────────
  double minD = double.infinity, maxD = double.negativeInfinity;

  void scanB(List<_Box> bs, double xOff) {
    for (final b in bs) {
      for (int xi = 0; xi <= b.nx; xi++) {
        for (int yi = 0; yi <= b.ny; yi++) {
          for (int zi = 0; zi <= b.nz; zi++) {
            final d = camZ(b.x0+(b.x1-b.x0)*xi/b.nx,
                           b.y0+(b.y1-b.y0)*yi/b.ny,
                           b.z0+(b.z1-b.z0)*zi/b.nz, xOff);
            if (d < minD) minD = d;
            if (d > maxD) maxD = d;
          }
        }
      }
    }
  }

  void scanP(List<_Patch> ps, double xOff) {
    for (final p in ps) {
      for (int ui = 0; ui <= p.nu; ui++) {
        for (int vi = 0; vi <= p.nv; vi++) {
          final u = ui/p.nu, v = vi/p.nv;
          final bx = p.x00*(1-u)*(1-v)+p.x10*u*(1-v)+p.x01*(1-u)*v+p.x11*u*v;
          final by = p.y00*(1-u)*(1-v)+p.y10*u*(1-v)+p.y01*(1-u)*v+p.y11*u*v;
          for (int zi = 0; zi <= p.nz; zi++) {
            final z = p.z0+(p.z1-p.z0)*zi/p.nz + p.twist*(u-0.5)*v;
            final d = camZ(bx, by, z, xOff);
            if (d < minD) minD = d;
            if (d > maxD) maxD = d;
          }
        }
      }
    }
  }

  scanB(_kLetterI, _xI); scanB(_kPeriod, _xDot1);
  scanP(_kLetterA, _xA); scanB(_kPeriod, _xDot2);

  final dRange = (maxD - minD).clamp(1e-6, double.infinity);
  double nd(double d)           => 1.0 - (d - minD) / dRange;
  double la(double da, double db) => ((da+db)*0.5*0.72+0.18).clamp(0.0,1.0);
  double na(double d)           => (d*0.80+0.20).clamp(0.0,1.0);
  String f(double v)            => v.toStringAsFixed(2);

  final lbuf = StringBuffer(); // line elements
  final nbuf = StringBuffer(); // node elements

  // ── Build SVG for an axis-aligned box set ─────────────────────────────────
  void boxSvg(List<_Box> boxes, double xOff, String lid, String nid) {
    lbuf.writeln('  <g id="$lid">');
    nbuf.writeln('  <g id="$nid">');
    for (final b in boxes) {
      final nx1=b.nx+1, ny1=b.ny+1, nz1=b.nz+1, N=nx1*ny1*nz1;
      final px=List<double>.filled(N,0), py=List<double>.filled(N,0);
      final dn=List<double>.filled(N,0);
      int vi(int xi, int yi, int zi) => xi * ny1 * nz1 + yi * nz1 + zi;
      for (int xi = 0; xi < nx1; xi++) {
        for (int yi = 0; yi < ny1; yi++) {
          for (int zi = 0; zi < nz1; zi++) {
            final p = proj(b.x0+(b.x1-b.x0)*xi/b.nx,
                           b.y0+(b.y1-b.y0)*yi/b.ny,
                           b.z0+(b.z1-b.z0)*zi/b.nz, xOff);
            final i = vi(xi, yi, zi); px[i] = p[0]; py[i] = p[1];
            dn[i] = nd(camZ(b.x0+(b.x1-b.x0)*xi/b.nx,
                            b.y0+(b.y1-b.y0)*yi/b.ny,
                            b.z0+(b.z1-b.z0)*zi/b.nz, xOff));
          }
        }
      }
      for (int xi = 0; xi < nx1; xi++) {
        for (int yi = 0; yi < ny1; yi++) {
          for (int zi = 0; zi < nz1; zi++) {
            final i = vi(xi, yi, zi);
            void seg(int j) { lbuf.writeln('    <line x1="${f(px[i])}" y1="${f(py[i])}" x2="${f(px[j])}" y2="${f(py[j])}" stroke-opacity="${f(la(dn[i],dn[j]))}"/>'); }
            if (xi < b.nx) { seg(vi(xi+1, yi, zi)); }
            if (yi < b.ny) { seg(vi(xi, yi+1, zi)); }
            if (zi < b.nz) { seg(vi(xi, yi, zi+1)); }
          }
        }
      }
      for (int i = 0; i < N; i++) { nbuf.writeln('    <circle cx="${f(px[i])}" cy="${f(py[i])}" r="${f(nodeRadius)}" fill-opacity="${f(na(dn[i]))}"/>'); }
    }
    lbuf.writeln('  </g>');
    nbuf.writeln('  </g>');
  }

  // ── Build SVG for a bilinear patch set ───────────────────────────────────
  void patchSvg(List<_Patch> patches, double xOff, String lid, String nid) {
    lbuf.writeln('  <g id="$lid">');
    nbuf.writeln('  <g id="$nid">');
    for (final p in patches) {
      final nu1=p.nu+1, nv1=p.nv+1, nz1=p.nz+1, N=nu1*nv1*nz1;
      final px=List<double>.filled(N,0), py=List<double>.filled(N,0);
      final dn=List<double>.filled(N,0);
      int pi2(int ui, int vi, int zi) => ui * nv1 * nz1 + vi * nz1 + zi;
      for (int ui = 0; ui <= p.nu; ui++) {
        for (int vi2 = 0; vi2 <= p.nv; vi2++) {
          for (int zi = 0; zi <= p.nz; zi++) {
            final u = ui / p.nu, v = vi2 / p.nv;
            final bx = p.x00*(1-u)*(1-v)+p.x10*u*(1-v)+p.x01*(1-u)*v+p.x11*u*v;
            final by = p.y00*(1-u)*(1-v)+p.y10*u*(1-v)+p.y01*(1-u)*v+p.y11*u*v;
            final z  = p.z0 + (p.z1-p.z0)*zi/p.nz + p.twist*(u-0.5)*v;
            final i  = pi2(ui, vi2, zi);
            final pt = proj(bx, by, z, xOff); px[i] = pt[0]; py[i] = pt[1];
            dn[i] = nd(camZ(bx, by, z, xOff));
          }
        }
      }
      for (int ui = 0; ui <= p.nu; ui++) {
        for (int vi2 = 0; vi2 <= p.nv; vi2++) {
          for (int zi = 0; zi <= p.nz; zi++) {
            final i = pi2(ui, vi2, zi);
            void seg(int j) { lbuf.writeln('    <line x1="${f(px[i])}" y1="${f(py[i])}" x2="${f(px[j])}" y2="${f(py[j])}" stroke-opacity="${f(la(dn[i],dn[j]))}"/>'); }
            if (ui  < p.nu)  { seg(pi2(ui+1, vi2, zi)); }
            if (vi2 < p.nv)  { seg(pi2(ui, vi2+1, zi)); }
            if (zi  < p.nz)  { seg(pi2(ui, vi2, zi+1)); }
          }
        }
      }
      for (int i = 0; i < N; i++) { nbuf.writeln('    <circle cx="${f(px[i])}" cy="${f(py[i])}" r="${f(nodeRadius)}" fill-opacity="${f(na(dn[i]))}"/>'); }
    }
    lbuf.writeln('  </g>');
    nbuf.writeln('  </g>');
  }

  boxSvg  (_kLetterI,  _xI,    'ia-lines-I',   'ia-nodes-I');
  boxSvg  (_kPeriod,   _xDot1, 'ia-lines-dot1', 'ia-nodes-dot1');
  patchSvg(_kLetterA,  _xA,    'ia-lines-A',   'ia-nodes-A');
  boxSvg  (_kPeriod,   _xDot2, 'ia-lines-dot2', 'ia-nodes-dot2');

  return '''<?xml version="1.0" encoding="UTF-8"?>
<!--
  I.A. Insurance — Premium Wireframe Logo
  Generated by generateIaLogoSvg() — edit visual constants above, not raw coords.

  Groups
  ──────
  #ia-lines-I / #ia-nodes-I     Letter I edges + vertex nodes
  #ia-lines-A / #ia-nodes-A     Letter A edges + vertex nodes
  #ia-lines-dot1/2               Period dots

  Tip: change stroke-width on <g id="ia-lines"> and r on <g id="ia-nodes">
       for a bolder or finer look without touching individual elements.
-->
<svg
  xmlns="http://www.w3.org/2000/svg"
  viewBox="0 0 ${svgWidth.toInt()} ${svgHeight.toInt()}"
  width="${svgWidth.toInt()}"
  height="${svgHeight.toInt()}"
  fill="none">

  <!-- ── Mesh edges ──────────────────────────────────────────────────── -->
  <g stroke="$color" stroke-width="${f(strokeWidth)}" stroke-linecap="round">
${lbuf.toString()}  </g>

  <!-- ── Vertex nodes ────────────────────────────────────────────────── -->
  <g fill="$color">
${nbuf.toString()}  </g>

</svg>''';
}
