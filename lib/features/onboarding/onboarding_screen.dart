import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_constants.dart';
import '../biometrics/biometric_auth_service.dart';
import '../notifications/unkillable_notification_service.dart';
import '../pairing/pairing_manager.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const OnboardingScreen({Key? key, required this.onCompleted}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _permissionNotificationGranted = false;
  bool _biometricConfigured = false;
  String _myCode = '';

  @override
  void initState() {
    super.initState();
    _loadMyCode();
  }

  Future<void> _loadMyCode() async {
    final code = await PairingManager.getOrCreateMyCode();
    setState(() {
      _myCode = code;
    });
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0206),
        body: SafeArea(
          child: Column(
            children: [
              // Top Stepper Indicator (4 steps)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) => _buildIndicator(index == _currentPage)),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildStep1Intro(),
                    _buildStep2VisualGuide(),
                    _buildStep3Permissions(),
                    _buildStep4Ready(),
                  ],
                ),
              ),
              // Bottom Action Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == 3 ? 'ورود به مانیتور ضربان سلامت' : 'مرحله بعد',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 28 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE11D48) : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildStep1Intro() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.monitor_heart_rounded, size: 80, color: Color(0xFFE11D48)),
          SizedBox(height: 24),
          Text(
            'به سامانه پالس خوش آمدید',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 14),
          Text(
            'این اپلیکیشن در ظاهر یک مانیتور پزشکی ضربان قلب (ECG) است، اما با ژست مخفی به فضای گفتگوی فوق‌محرمانه تبدیل می‌شود.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFFFDA4AF), height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2VisualGuide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'راهنمای ورود مخفی و خروج اضطراری',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          _buildGuideCard(
            icon: Icons.touch_app_rounded,
            title: 'ورود مخفی با اثر انگشت',
            desc: 'در صفحه ضربان قلب، نمودار نوار قلب را ۳ ثانیه لمس کرده و نگه دارید تا سنسور اثر انگشت فعال شود.',
          ),
          const SizedBox(height: 12),
          _buildGuideCard(
            icon: Icons.screen_rotation_rounded,
            title: 'قفل اضطراری با برگرداندن گوشی',
            desc: 'هر زمان گوشی را روی میز رو به پایین برگردانید، بلافاصله برنامه قفل شده و به مانیتور ضربان تبدیل می‌شود.',
          ),
          const SizedBox(height: 12),
          _buildGuideCard(
            icon: Icons.exit_to_app_rounded,
            title: 'استتار خودکار در لحظه خروج',
            desc: 'با هر بار خروج یا رفتن به برنامه‌ای دیگر، جلسه محرمانه فوراً بسته و قفل می‌گردد.',
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Permissions() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.notifications_active_rounded, size: 68, color: Color(0xFFE11D48)),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'فعال‌سازی اعلان‌های تضمینی و بیومتریک',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'جهت دریافت بدون وقفه اعلان‌های استتار پزشکی و بازگشایی امن با اثر انگشت، مجوزهای زیر را لمس فرمایید:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildPermissionTile(
            title: '۱. فعال‌سازی نوتیفیکیشن اندروید',
            subtitle: 'اجازه صدور اعلان‌های پزشکی بر روی صفحه',
            isGranted: _permissionNotificationGranted,
            onTap: () async {
              await UnkillableNotificationService.requestNotificationPermission();
              await UnkillableNotificationService.testNotification();
              setState(() => _permissionNotificationGranted = true);
            },
          ),
          const SizedBox(height: 12),
          _buildPermissionTile(
            title: '۲. بررسی حسگر اثر انگشت',
            subtitle: 'تست بازگشایی بیومتریک گوشی',
            isGranted: _biometricConfigured,
            onTap: () async {
              final ok = await BiometricAuthService.authenticate(reason: 'تست احراز هویت بیومتریک پالس');
              if (ok) {
                setState(() => _biometricConfigured = true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Ready() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 74, color: Color(0xFF10B981)),
          const SizedBox(height: 18),
          const Text(
            'آماده بهره‌برداری',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'نیازی به وارد کردن شناسه پارتنر در این مرحله نیست.',
            style: TextStyle(fontSize: 14, color: Color(0xFFFDA4AF), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'پس از ورود، هر زمان مایل بودید می‌توانید از منوی بالای برنامه (☰) مخاطبان و کدهای اختصاصی آن‌ها را ثبت نمایید.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F0510),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE11D48)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('کد اختصاصی شما: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _myCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Color(0xFFFB7185), size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _myCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('کد شما کپی شد'), backgroundColor: Color(0xFFE11D48)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C040E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE11D48).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE11D48), size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C040E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isGranted ? const Color(0xFF10B981) : const Color(0xFFE11D48).withOpacity(0.5)),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
            : const Icon(Icons.touch_app_rounded, color: Color(0xFFFB7185)),
        onTap: onTap,
      ),
    );
  }
}
