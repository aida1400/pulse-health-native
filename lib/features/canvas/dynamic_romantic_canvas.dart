import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DynamicRomanticCanvas extends StatefulWidget {
  final String themeId;
  final String customBgColor;
  final String particleType; // 'heart', 'candle', 'rose', 'star', 'fire'
  final String messageText;
  final VoidCallback onDismiss;

  const DynamicRomanticCanvas({
    Key? key,
    this.themeId = 'hearts',
    this.customBgColor = '#2D0B1E',
    this.particleType = 'heart',
    required this.messageText,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<DynamicRomanticCanvas> createState() => _DynamicRomanticCanvasState();
}

class _DynamicRomanticCanvasState extends State<DynamicRomanticCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<CanvasParticle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Spawn 45 initial particles
    for (int i = 0; i < 45; i++) {
      _particles.add(CanvasParticle.random(_rand, widget.particleType));
    }

    _triggerHaptic();
  }

  Future<void> _triggerHaptic() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex, {Color fallback = const Color(0xFF2D0B1E)}) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseHex(widget.customBgColor);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: widget.onDismiss,
        child: Stack(
          children: [
            // 1. Dynamic Radial Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    bgColor.withOpacity(0.95),
                    bgColor.withOpacity(0.6),
                    const Color(0xFF07050A),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            // 2. Animated Custom Particle Canvas
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                for (var p in _particles) {
                  p.update();
                }
                return CustomPaint(
                  painter: ParticleCanvasPainter(
                    particles: _particles,
                    particleType: widget.particleType,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // 3. Central Romantic Glass Message Card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 34.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.48),
                    borderRadius: BorderRadius.circular(28.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: bgColor.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Icon based on particle type
                      _buildHeaderIcon(widget.particleType),
                      const SizedBox(height: 18),
                      // Romantic Message Body
                      Text(
                        widget.messageText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.75,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Subtle Hint to dismiss
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'برای بستن، هر جای صفحه را لمس کنید',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(String type) {
    switch (type) {
      case 'candle':
        return const Icon(Icons.wb_incandescent_outlined, color: Color(0xFFFBBF24), size: 36);
      case 'rose':
        return const Icon(Icons.local_florist_outlined, color: Color(0xFFFB7185), size: 36);
      case 'star':
        return const Icon(Icons.star_purple500_outlined, color: Color(0xFFFDE047), size: 36);
      case 'fire':
        return const Icon(Icons.local_fire_department_outlined, color: Color(0xFFF97316), size: 36);
      case 'heart':
      default:
        return const Icon(Icons.favorite, color: Color(0xFFF43F5E), size: 38);
    }
  }
}

class CanvasParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  double rotation;
  double vRotation;
  final String type;
  final Random rand;

  CanvasParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.vRotation,
    required this.type,
    required this.rand,
  });

  factory CanvasParticle.random(Random rand, String type) {
    final x = rand.nextDouble();
    double y;
    double vy;

    if (type == 'candle' || type == 'rose') {
      // Drips downwards (candle wax or falling rose petals)
      y = rand.nextDouble();
      vy = 0.0015 + rand.nextDouble() * 0.0035;
    } else if (type == 'star') {
      // Gentle twinkle
      y = rand.nextDouble();
      vy = (rand.nextDouble() - 0.5) * 0.0005;
    } else {
      // Erupts upwards (hearts, fire embers)
      y = rand.nextDouble();
      vy = -(0.002 + rand.nextDouble() * 0.0045);
    }

    return CanvasParticle(
      x: x,
      y: y,
      vx: (rand.nextDouble() - 0.5) * 0.0012,
      vy: vy,
      size: 10 + rand.nextDouble() * 18,
      opacity: 0.3 + rand.nextDouble() * 0.7,
      rotation: rand.nextDouble() * pi * 2,
      vRotation: (rand.nextDouble() - 0.5) * 0.04,
      type: type,
      rand: rand,
    );
  }

  void update() {
    x += vx;
    y += vy;
    rotation += vRotation;

    if (type == 'candle' || type == 'rose') {
      // Dripping downwards: reset when falling off bottom
      if (y > 1.05) {
        y = -0.05;
        x = rand.nextDouble();
      }
    } else if (type == 'star') {
      opacity = 0.3 + 0.6 * sin(rotation);
      if (opacity < 0.1) opacity = 0.1;
    } else {
      // Erupting upwards: reset when floating above top
      if (y < -0.05) {
        y = 1.05;
        x = rand.nextDouble();
      }
    }

    if (x < 0) x = 1.0;
    if (x > 1) x = 0.0;
  }
}

class ParticleCanvasPainter extends CustomPainter {
  final List<CanvasParticle> particles;
  final String particleType;

  ParticleCanvasPainter({
    required this.particles,
    required this.particleType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final dx = p.x * size.width;
      final dy = p.y * size.height;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation);

      if (particleType == 'candle') {
        _drawCandleDrop(canvas, p.size, p.opacity);
      } else if (particleType == 'rose') {
        _drawRosePetal(canvas, p.size, p.opacity);
      } else if (particleType == 'star') {
        _drawSparkleStar(canvas, p.size, p.opacity);
      } else if (particleType == 'fire') {
        _drawFireEmber(canvas, p.size, p.opacity);
      } else {
        _drawHeart(canvas, p.size, p.opacity);
      }

      canvas.restore();
    }
  }

  void _drawHeart(Canvas canvas, double s, double opacity) {
    final paint = Paint()
      ..color = const Color(0xFFF43F5E).withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final path = Path();
    final half = s / 2;
    path.moveTo(0, half * 0.35);
    path.cubicTo(-half, -half * 0.5, -half * 1.1, half * 0.6, 0, half * 1.3);
    path.cubicTo(half * 1.1, half * 0.6, half, -half * 0.5, 0, half * 0.35);
    canvas.drawPath(path, paint);
  }

  void _drawCandleDrop(Canvas canvas, double s, double opacity) {
    // Teardrop / wax drip shape
    final paint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final path = Path();
    final r = s * 0.4;
    path.moveTo(0, -s * 0.8);
    path.quadraticBezierTo(-r, 0, -r, r);
    path.arcToPoint(Offset(r, r), radius: Radius.circular(r), clockwise: false);
    path.quadraticBezierTo(r, 0, 0, -s * 0.8);
    canvas.drawPath(path, paint);
  }

  void _drawRosePetal(Canvas canvas, double s, double opacity) {
    final paint = Paint()
      ..color = const Color(0xFFE11D48).withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, -s * 0.6);
    path.quadraticBezierTo(-s * 0.5, 0, 0, s * 0.6);
    path.quadraticBezierTo(s * 0.5, 0, 0, -s * 0.6);
    canvas.drawPath(path, paint);
  }

  void _drawSparkleStar(Canvas canvas, double s, double opacity) {
    final paint = Paint()
      ..color = const Color(0xFFFDE047).withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, -s * 0.8);
    path.quadraticBezierTo(0, 0, s * 0.8, 0);
    path.quadraticBezierTo(0, 0, 0, s * 0.8);
    path.quadraticBezierTo(0, 0, -s * 0.8, 0);
    path.quadraticBezierTo(0, 0, 0, -s * 0.8);
    canvas.drawPath(path, paint);
  }

  void _drawFireEmber(Canvas canvas, double s, double opacity) {
    final paint = Paint()
      ..color = const Color(0xFFF97316).withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, s * 0.35, paint);
  }

  @override
  bool shouldRepaint(covariant ParticleCanvasPainter oldDelegate) => true;
}
