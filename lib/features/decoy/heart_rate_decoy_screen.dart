import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../biometrics/biometric_auth_service.dart';

class HeartRateDecoyScreen extends StatefulWidget {
  final VoidCallback onSecretUnlocked;
  const HeartRateDecoyScreen({Key? key, required this.onSecretUnlocked}) : super(key: key);

  @override
  State<HeartRateDecoyScreen> createState() => _HeartRateDecoyScreenState();
}

class _HeartRateDecoyScreenState extends State<HeartRateDecoyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ecgController;
  int _currentBpm = 74;
  Timer? _bpmTimer;
  bool _isMeasuring = false;
  double _measuringProgress = 0.0;
  Timer? _measuringTimer;

  @override
  void initState() {
    super.initState();
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Minor natural fluctuations in BPM to make it 100% realistic
    _bpmTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !_isMeasuring) {
        setState(() {
          _currentBpm = 72 + Random().nextInt(5);
        });
      }
    });
  }

  @override
  void dispose() {
    _ecgController.dispose();
    _bpmTimer?.cancel();
    _measuringTimer?.cancel();
    super.dispose();
  }

  void _startFakeMeasurement() {
    setState(() {
      _isMeasuring = true;
      _measuringProgress = 0.0;
    });

    _measuringTimer?.cancel();
    _measuringTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() {
        _measuringProgress += 0.025;
        if (_measuringProgress >= 1.0) {
          _measuringProgress = 1.0;
          _isMeasuring = false;
          _currentBpm = 70 + Random().nextInt(7);
          t.cancel();
        }
      });
    });
  }

  Future<void> _attemptSecretUnlock() async {
    final authenticated = await BiometricAuthService.authenticate(
      reason: 'احراز هویت بیومتریک پالس',
    );
    if (authenticated) {
      widget.onSecretUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.monitor_heart_rounded, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 8),
            Text('Pulse Health Tracker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          // Secret tap area disguised as info icon
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white24, size: 20),
            onPressed: _attemptSecretUnlock,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Status Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('حالت پایش: مداوم و بلادرنگ', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  Text('سیستم فعال', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Real-time animated ECG Canvas (Hold 2s for secret entry)
            GestureDetector(
              onLongPress: _attemptSecretUnlock,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF060B14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedBuilder(
                    animation: _ecgController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: EcgPainter(progress: _ecgController.value),
                        size: const Size(double.infinity, 160),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // BPM Metric
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_currentBpm',
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text('BPM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ],
            ),
            const Text(
              'ضربان نرمال / ریتم سینوسی منظم',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const Spacer(),
            // Measurement action or progress
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (_isMeasuring) ...[
                    LinearProgressIndicator(
                      value: _measuringProgress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'در حال سنجش از طریق سنسور... ${(_measuringProgress * 100).toInt()}%',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.favorite_border_rounded),
                        label: const Text('کالیبراسیون و پایش مجدد سنسور', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _startFakeMeasurement,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EcgPainter extends CustomPainter {
  final double progress;
  EcgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Grid lines for medical screen look
    final gridPaint = Paint()
      ..color = const Color(0xFF102820)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ECG Signal line
    final linePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midY = size.height / 2;

    path.moveTo(0, midY);

    for (double x = 0; x < size.width; x += 2) {
      final shiftedX = (x + progress * size.width) % size.width;
      double y = midY;

      // Realistic QRS complex wave calculation
      final rel = shiftedX / size.width;
      if (rel > 0.45 && rel < 0.48) {
        y = midY + 12; // P wave dip
      } else if (rel >= 0.48 && rel < 0.52) {
        y = midY - 55; // R peak (sharp spike)
      } else if (rel >= 0.52 && rel < 0.55) {
        y = midY + 22; // S dip
      } else if (rel >= 0.60 && rel < 0.68) {
        y = midY - 14; // T wave bump
      }

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant EcgPainter oldDelegate) => true;
}
