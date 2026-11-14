import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/decoy/heart_rate_decoy_screen.dart';
import 'features/sensors/panic_sensor_service.dart';
import 'features/composer/message_composer_screen.dart';
import 'features/canvas/dynamic_romantic_canvas.dart';
import 'features/canvas/blossom_and_reactions.dart';
import 'features/time_capsule/time_capsule_service.dart';
import 'features/notifications/unkillable_notification_service.dart';
import 'features/pairing/pairing_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UnkillableNotificationService.initialize();
  await TimeCapsuleService.loadVault();
  runApp(const PulseApp());
}

class PulseApp extends StatefulWidget {
  const PulseApp({Key? key}) : super(key: key);

  @override
  State<PulseApp> createState() => _PulseAppState();
}

class _PulseAppState extends State<PulseApp> {
  bool _isLoading = true;
  bool _isFirstRun = true;
  bool _isSecretUnlocked = false;
  String? _activeViewingMessage;
  String _activeViewingTheme = 'hearts';

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
    _initSensors();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final firstRun = prefs.getBool(AppConstants.keyIsFirstRun) ?? true;
    setState(() {
      _isFirstRun = firstRun;
      _isLoading = false;
    });
  }

  void _initSensors() {
    PanicSensorService.startListening(
      onPanicTriggered: () {
        // Immediate flip-down or shake detected! Force instant panic lockdown.
        if (_isSecretUnlocked || _activeViewingMessage != null) {
          setState(() {
            _isSecretUnlocked = false;
            _activeViewingMessage = null;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    PanicSensorService.stopListening();
    super.dispose();
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstRun, false);
    setState(() {
      _isFirstRun = false;
      _isSecretUnlocked = false; // Always go to decoy screen
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.decoyTheme,
        home: const Scaffold(
          backgroundColor: Color(0xFF0A0F1D),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
        ),
      );
    }

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _isSecretUnlocked ? AppTheme.secretTheme : AppTheme.decoyTheme,
      home: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    // 1. If first run: Display 4-step interactive permission & pairing wizard
    if (_isFirstRun) {
      return OnboardingScreen(onCompleted: _completeOnboarding);
    }

    // 2. If viewing a romantic message with dynamic canvas
    if (_activeViewingMessage != null) {
      return Scaffold(
        body: Stack(
          children: [
            DynamicRomanticCanvas(
              themeId: _activeViewingTheme,
              messageText: _activeViewingMessage!,
              onDismiss: () => setState(() => _activeViewingMessage = null),
            ),
            // Floating 4-action reaction palette
            BlossomAndReactionsBar(
              onReactionSent: (type, text) {
                // Send reaction signal back to partner
                setState(() => _activeViewingMessage = null);
              },
            ),
            // Top Emergency Disguise Button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white60),
                onPressed: () {
                  setState(() {
                    _isSecretUnlocked = false;
                    _activeViewingMessage = null;
                  });
                },
              ),
            ),
          ],
        ),
      );
    }

    // 3. If secret space is unlocked: Show Message Composer
    if (_isSecretUnlocked) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF200F29),
          title: const Text('پالس اختصاصی', style: TextStyle(fontSize: 16)),
          actions: [
            // Instant camouflage switch button
            IconButton(
              icon: const Icon(Icons.shield_outlined, color: Color(0xFF10B981)),
              tooltip: 'تغییر قیافه فوری به مانیتور ضربان',
              onPressed: () {
                setState(() => _isSecretUnlocked = false);
              },
            ),
          ],
        ),
        body: MessageComposerScreen(
          onSendMessage: (content, themeId, scheduledTime) async {
            final myCode = await PairingManager.getOrCreateMyCode();
            final capsule = TimeCapsuleModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: content,
              themeId: themeId,
              scheduledUnlockTime: scheduledTime ?? DateTime.now(),
              status: CapsuleStatus.pendingLocked,
              senderCode: myCode,
              createdAt: DateTime.now(),
            );
            await TimeCapsuleService.saveToVault(capsule);

            // Preview message
            setState(() {
              _activeViewingMessage = content;
              _activeViewingTheme = themeId;
            });
          },
        ),
      );
    }

    // 4. Default Safe State: Medical Fake Heart-Rate Monitor
    return HeartRateDecoyScreen(
      onSecretUnlocked: () {
        setState(() {
          _isSecretUnlocked = true;
        });
      },
    );
  }
}
