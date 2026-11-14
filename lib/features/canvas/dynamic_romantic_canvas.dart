import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DynamicRomanticCanvas extends StatefulWidget {
  final String themeId;
  final String messageText;
  final VoidCallback onDismiss;

  const DynamicRomanticCanvas({
    Key? key,
    required this.themeId,
    required this.messageText,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<DynamicRomanticCanvas> createState() => _DynamicRomanticCanvasState();
}

class _DynamicRomanticCanvasState extends State<DynamicRomanticCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<HeartParticle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate initial particles
    for (int i = 0; i < 40; i++) {
      _particles.add(HeartParticle.random(_rand));
    }

    // Trigger subtle heartbeat haptic feedback
    _triggerHeartbeatHaptic();
  }

  Future<void> _triggerHeartbeatHaptic() async {
    try {
      // Lub-Dub heart rhythm vibration (heavy impact, pause, medium impact)
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

  void _onPanUpdate(DragUpdateDetails details) {
    // Add burst of particles at user's touch location
    setState(() {
      for (int i = 0; i < 3; i++) {
        _particles.add(HeartParticle(
          x: details.localPosition.dx + (_rand.nextDouble() * 20 - 10),
          y: details.localPosition.dy + (_rand.nextDouble() * 20 - 10),
          size: 14 + _rand.nextDouble() * 18,
          speedY: 2 + _rand.nextDouble() * 4,
          speedX: (_rand.nextDouble() - 0.5) * 3,
          opacity: 0.9,
          color: Colors.pinkAccent.shade100,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: Stack(
        children: [
          // Background Gradient based on theme
          _buildBackground(),

          // Particle Physics Layer
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              _updateParticles(MediaQuery.of(context).size);
              return CustomPaint(
                painter: ParticlePainter(particles: _particles),
                size: Size.infinite,
              );
            },
          ),

          // Message Card Content (Centered, beautifully frosted)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.18),
                      blurRadius: 32,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Color(0xFFF43F5E), size: 40),
                    const SizedBox(height: 20),
                    Text(
                      widget.messageText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.8,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    switch (widget.themeId) {
      case 'rain':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF020617)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        );
      case 'candle':
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF451A03), Color(0xFF1C1917), Color(0xFF0C0A09)],
              center: Alignment.center,
              radius: 0.9,
            ),
          ),
        );
      case 'hearts':
      default:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF881337), Color(0xFF4C0519), Color(0xFF1F030B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
    }
  }

  void _updateParticles(Size size) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.y -= p.speedY; // Float upwards like eruption
      p.x += p.speedX;
      p.opacity -= 0.003;

      if (p.y < -20 || p.opacity <= 0) {
        _particles.removeAt(i);
        // Recycle with new particle at bottom
        _particles.add(HeartParticle.bottom(_rand, size));
      }
    }
  }
}

class HeartParticle {
  double x;
  double y;
  double size;
  double speedY;
  double speedX;
  double opacity;
  Color color;

  HeartParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.opacity,
    required this.color,
  });

  factory HeartParticle.random(Random rand) {
    return HeartParticle(
      x: rand.nextDouble() * 400,
      y: rand.nextDouble() * 800,
      size: 10 + rand.nextDouble() * 20,
      speedY: 1.5 + rand.nextDouble() * 3.5,
      speedX: (rand.nextDouble() - 0.5) * 1.5,
      opacity: 0.3 + rand.nextDouble() * 0.7,
      color: Colors.pinkAccent.withOpacity(0.8),
    );
  }

  factory HeartParticle.bottom(Random rand, Size size) {
    return HeartParticle(
      x: rand.nextDouble() * size.width,
      y: size.height + 20,
      size: 12 + rand.nextDouble() * 18,
      speedY: 2.0 + rand.nextDouble() * 3.5,
      speedX: (rand.nextDouble() - 0.5) * 1.8,
      opacity: 0.6 + rand.nextDouble() * 0.4,
      color: Colors.pinkAccent.shade100,
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<HeartParticle> particles;
  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      // Draw heart path
      final heartPath = _getHeartPath(p.x, p.y, p.size);
      canvas.drawPath(heartPath, paint);
    }
  }

  Path _getHeartPath(double x, double y, double size) {
    final path = Path();
    path.moveTo(x, y + size / 4);
    path.cubicTo(x, y, x - size / 2, y, x - size / 2, y + size / 4);
    path.cubicTo(x - size / 2, y + size / 2, x, y + size * 0.75, x, y + size);
    path.cubicTo(x, y + size * 0.75, x + size / 2, y + size / 2, x + size / 2, y + size / 4);
    path.cubicTo(x + size / 2, y, x, y, x, y + size / 4);
    return path;
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
