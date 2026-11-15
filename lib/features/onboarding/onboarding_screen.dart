import 'package:flutter/material.dart';
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
  bool _permissionBatteryGranted = false;
  bool _biometricConfigured = false;
  bool _pairingDone = false;

  final TextEditingController _partnerCodeController = TextEditingController();
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
    if (_currentPage < 4) {
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
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Column(
          children: [
            // Top Stepper Indicator (5 steps now)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => _buildIndicator(index == _currentPage)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildStep1Intro(),
                  _buildStep2VisualGuide(), // NEW: Full visual tutorial of keys and gestures!
                  _buildStep3Permissions(),
                  _buildStep4SensorsAndBiometric(),
                  _buildStep5Pairing(),
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
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _canProceed() ? _nextPage : null,
                  child: Text(
                    _currentPage == 4 ? 'پایان و ورود به پالس' : 'مرحله بعد',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 26 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF10B981) : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  bool _canProceed() {
    if (_currentPage == 0) return true;
    if (_currentPage == 1) return true; // Visual guide can be read and continued
    if (_currentPage == 2) return _permissionNotificationGranted && _permissionBatteryGranted;
    if (_currentPage == 3) return _biometricConfigured;
    if (_currentPage == 4) return _pairingDone;
    return true;
  }

  // Step 1: Welcome & Stealth Concept
  Widget _buildStep1Intro() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.monitor_heart_rounded, size: 76, color: Color(0xFF10B981)),
          SizedBox(height: 24),
          Text(
            'به سامانه نیتیو پالس سلامت خوش آمدید',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'پالس یک پایشگر پزشکی ضربان قلب واقعی است، اما برای شما دو نفر یک صندوق ارتباطی فوق‌محرمانه است.\n\nتمامی اعلان‌ها با نام و ظاهر گزارش سلامت ظاهر می‌شوند و متن‌های اصلی فقط با اثر انگشت فیزیکی گوشی شما بازگشایی می‌شوند.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.8),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Step 2: Visual Guide of Buttons and Gestures
  Widget _buildStep2VisualGuide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'راهنمای تصویری کلیدها و ژست‌های حرکتی',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'پیش از شروع، نحوه کارکرد علائم و سنسورها را مرور کنید:',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 20),
          _buildGuideCard(
            icon: Icons.fingerprint,
            iconColor: const Color(0xFF10B981),
            title: 'ورود به محیط محرمانه (راز دو نفره)',
            desc: 'نگه داشتن انگشت به مدت ۲ ثانیه روی خط نوار قلب (ECG) یا لمس آیکون مخفی در بالای صفحه.',
          ),
          _buildGuideCard(
            icon: Icons.screen_rotation,
            iconColor: const Color(0xFF38BDF8),
            title: 'سنسور برگرداندن روی میز (استتار فوری)',
            desc: 'در هر کجای برنامه باشید، با قرار دادن گوشی رو به میز یا تکان دادن شدید آن، صفحه فوراً به نوار قلب تبدیل می‌شود.',
          ),
          _buildGuideCard(
            icon: Icons.schedule_send_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'کپسول زمان و دکمه ابطال (Undo)',
            desc: 'پیام‌ها را برای ساعت مشخص قفل کنید. تا قبل از باز شدن توسط پارتنر، می‌توانید آن را ادیت کنید یا کلاً پس بگیرید.',
          ),
          _buildGuideCard(
            icon: Icons.favorite,
            iconColor: const Color(0xFFF43F5E),
            title: 'پالت ری‌اکت سریع و تاریخچه پیام‌ها',
            desc: 'با یک لمس زیر پیام، تپش پالس (ویبره قلب)، آغوش یا بوسه بفرستید و در بخش تاریخچه، آرشیو تمام پیام‌ها را مرور کنید.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Critical Permissions
  Widget _buildStep3Permissions() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active_rounded, size: 64, color: Color(0xFF38BDF8)),
          const SizedBox(height: 20),
          const Text(
            'پیکربندی اعلان‌های بومی و ضدتوقف',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'برای تضمین اینکه پیام‌ها حتی با بسته بودن برنامه و بدون فیلترشکن به دست شما برسند، دسترسی‌های زیر الزامی است:',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildPermissionTile(
            title: 'مجوز اعلان با اولویت بحرانی',
            subtitle: 'نمایش بی‌درنگ با صدای ملایم پیش‌فرض',
            isGranted: _permissionNotificationGranted,
            onTap: () async {
              await UnkillableNotificationService.requestNotificationPermission();
              setState(() => _permissionNotificationGranted = true);
            },
          ),
          const SizedBox(height: 12),
          _buildPermissionTile(
            title: 'معافیت از مدیریت باتری (Doze Mode)',
            subtitle: 'جلوگیری از فریز شدن پالس توسط اندروید',
            isGranted: _permissionBatteryGranted,
            onTap: () async {
              await UnkillableNotificationService.requestIgnoreBatteryOptimization();
              setState(() => _permissionBatteryGranted = true);
            },
          ),
        ],
      ),
    );
  }

  // Step 4: Biometrics & Flip Face-Down Sensors
  Widget _buildStep4SensorsAndBiometric() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fingerprint_rounded, size: 64, color: Color(0xFFF43F5E)),
          const SizedBox(height: 20),
          const Text(
            'گیت امنیتی اثر انگشت سخت‌افزاری',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'سیستم به طور مستقیم با سنسور اثر انگشت فیزیکی گوشی شما متصل می‌شود.\nهیچ‌کس بدون اثر انگشت شما قادر به ورود نخواهد بود.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildPermissionTile(
            title: 'تست سنسور اثر انگشت فیزیکی',
            subtitle: _biometricConfigured ? 'اثر انگشت با موفقیت تایید شد' : 'جهت اسکن اثر انگشت لمس کنید',
            isGranted: _biometricConfigured,
            onTap: () async {
              final ok = await BiometricAuthService.authenticate(reason: 'احراز هویت سنسور اثر انگشت پالس');
              if (ok) {
                setState(() => _biometricConfigured = true);
              }
            },
          ),
        ],
      ),
    );
  }

  // Step 5: 1-to-1 Pairing
  Widget _buildStep5Pairing() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.favorite, size: 64, color: Color(0xFFF43F5E)),
          const SizedBox(height: 16),
          const Text(
            'اتصال اختصاصی یک‌به‌یک (Pairing)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'هر نسخه پالس فقط و فقط به یک پارتنر متصل می‌شود.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                const Text('کد اختصاصی شما جهت ارائه به پارتنر:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 8),
                SelectableText(
                  _myCode.isEmpty ? 'در حال تولید...' : _myCode,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 6, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _partnerCodeController,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: 'کد ۶ رقمی پارتنر را وارد کنید',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13, letterSpacing: 0),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF38BDF8),
              side: const BorderSide(color: Color(0xFF38BDF8)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(_pairingDone ? Icons.check_circle : Icons.link),
            label: Text(_pairingDone ? 'اتصال برقرار شد' : 'ثبت و قفل جفت'),
            onPressed: () async {
              if (_partnerCodeController.text.trim().isNotEmpty) {
                final success = await PairingManager.pairWithPartner(_partnerCodeController.text.trim());
                if (success) {
                  setState(() => _pairingDone = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اتصال اختصاصی با موفقیت برقرار و قفل شد.')),
                  );
                }
              }
            },
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isGranted ? const Color(0xFF10B981) : const Color(0xFF334155)),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
            : const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
        onTap: onTap,
      ),
    );
  }
}
