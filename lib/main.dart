import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/decoy/heart_rate_decoy_screen.dart';
import 'features/sensors/panic_sensor_service.dart';
import 'features/composer/message_composer_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/canvas/dynamic_romantic_canvas.dart';
import 'features/time_capsule/time_capsule_service.dart';
import 'features/notifications/unkillable_notification_service.dart';
import 'features/pairing/pairing_manager.dart';
import 'features/serverless/serverless_relay_adapter.dart';
import 'features/profile/contact_manager.dart';
import 'features/profile/pulse_navigation_drawer.dart';
import 'features/profile/user_dashboard_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UnkillableNotificationService.initialize();
  await ContactManager.initialize();
  final activeContact = ContactManager.getActiveContact();
  if (activeContact != null) {
    await TimeCapsuleService.switchContact(activeContact.id);
  } else {
    await TimeCapsuleService.loadVault();
  }
  runApp(const PulseApp());
}

class PulseApp extends StatefulWidget {
  const PulseApp({Key? key}) : super(key: key);

  @override
  State<PulseApp> createState() => _PulseAppState();
}

class _PulseAppState extends State<PulseApp> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isFirstRun = true;
  bool _isSecretUnlocked = false;

  int _selectedVaultTab = 0; // 0: چت و تاریخچه, 1: ارسال پیام جدید
  String? _activeViewingMessage;
  String _activeViewingCustomBg = '#2D0B1E';
  String _activeViewingParticle = 'heart';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstRun();
    _initSensors();
    _initRelayListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PanicSensorService.stopListening();
    ServerlessRelayAdapter.stopRelayListener();
    super.dispose();
  }

  /// Instant Camouflage on Pause / Inactive / Background
  /// "وقتی از برنامه لحظه ای خارج شد باز بره رو اضطرار"
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_isSecretUnlocked || _activeViewingMessage != null) {
        setState(() {
          _isSecretUnlocked = false;
          _activeViewingMessage = null;
        });
      }
    }
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
        // Immediate flip-down on desk or double-shake detected!
        if (_isSecretUnlocked || _activeViewingMessage != null) {
          setState(() {
            _isSecretUnlocked = false;
            _activeViewingMessage = null;
          });
        }
      },
    );
  }

  void _initRelayListener() {
    ServerlessRelayAdapter.startRelayListener(
      onNewMessage: () {
        if (mounted) setState(() {});
      },
      onReceipt: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstRun, false);
    setState(() {
      _isFirstRun = false;
      _isSecretUnlocked = false; // Always enter medical decoy
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: _isSecretUnlocked ? AppTheme.secretTheme : AppTheme.decoyTheme,
        home: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    // 1. First run wizard
    if (_isFirstRun) {
      return OnboardingScreen(onCompleted: _completeOnboarding);
    }

    // 2. Full-screen active romantic canvas preview
    if (_activeViewingMessage != null) {
      return Scaffold(
        body: Stack(
          children: [
            DynamicRomanticCanvas(
              messageText: _activeViewingMessage!,
              customBgColor: _activeViewingCustomBg,
              particleType: _activeViewingParticle,
              onDismiss: () => setState(() => _activeViewingMessage = null),
            ),
            // Top Emergency Disguise Button
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 28),
                tooltip: 'قفل فوری اضطراری',
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

    // 3. Unlocked Secret Space
    if (_isSecretUnlocked) {
      final activeContact = ContactManager.getActiveContact();

      return Scaffold(
        backgroundColor: const Color(0xFF0E0715),
        body: _selectedVaultTab == 0
            ? ChatScreen(
                onEmergencyPanic: () => setState(() => _isSecretUnlocked = false),
                onContactSwitched: () => setState(() {}),
              )
            : Scaffold(
                backgroundColor: const Color(0xFF0E0715),
                drawer: PulseNavigationDrawer(
                  onEmergencyPanic: () => setState(() => _isSecretUnlocked = false),
                  onContactSwitched: () => setState(() {}),
                ),
                appBar: AppBar(
                  backgroundColor: const Color(0xFF1B0B27),
                  elevation: 0,
                  leading: Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                      tooltip: 'منوی کاربری و مخاطبان (مانند اسنپ)',
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ارسال بوم: ${activeContact?.name ?? "پارتنر"}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'کد متصل: ${activeContact?.partnerCode.isEmpty ?? true ? "تنظیم نشده" : activeContact!.partnerCode}',
                        style: TextStyle(fontSize: 10, color: const Color(0xFFFB7185).withOpacity(0.9)),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.dashboard_outlined, color: Color(0xFFFB7185)),
                      tooltip: 'داشبورد کدهای جفت‌سازی',
                      onPressed: () => UserDashboardDialog.show(context, onDataChanged: () => setState(() {})),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shield_outlined, color: Color(0xFF10B981)),
                      tooltip: 'تغییر قیافه فوری به مانیتور ضربان',
                      onPressed: () => setState(() => _isSecretUnlocked = false),
                    ),
                  ],
                ),
                body: MessageComposerScreen(
                  onSendMessage: ({
                    required String content,
                    required String category,
                    required String themeId,
                    required String customBgColor,
                    required String particleType,
                    DateTime? scheduledTime,
                  }) async {
                    final myCode = await PairingManager.getOrCreateMyCode();
                    final currentPartner = ContactManager.getActiveContact();

                    final capsule = PulseMessageModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      content: content,
                      category: category,
                      themeId: themeId,
                      customBgColor: customBgColor,
                      particleType: particleType,
                      scheduledUnlockTime: scheduledTime ?? DateTime.now(),
                      status: 'sent',
                      senderCode: myCode,
                      isSender: true,
                      createdAt: DateTime.now(),
                      isCanvas: true, // Marked as Romantic Canvas Card
                    );

                    // 1. Save to local vault
                    await TimeCapsuleService.saveToVault(capsule);

                    // 2. Real cloud dispatch to partner via ntfy relay!
                    await ServerlessRelayAdapter.sendMessage(
                      message: capsule,
                      targetPartnerCode: currentPartner?.partnerCode,
                    );

                    // 3. Open dynamic canvas preview
                    setState(() {
                      _activeViewingMessage = content;
                      _activeViewingCustomBg = customBgColor;
                      _activeViewingParticle = particleType;
                    });
                  },
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF180A22),
          selectedItemColor: const Color(0xFFFB7185),
          unselectedItemColor: Colors.white38,
          currentIndex: _selectedVaultTab,
          onTap: (idx) => setState(() => _selectedVaultTab = idx),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'چت و تاریخچه',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_outlined),
              activeIcon: Icon(Icons.edit_note),
              label: 'ارسال بوم عاشقانه',
            ),
          ],
        ),
      );
    }

    // 4. Default Safe Medical Decoy
    return HeartRateDecoyScreen(
      onSecretUnlocked: () {
        setState(() {
          _isSecretUnlocked = true;
        });
      },
    );
  }
}
