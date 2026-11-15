import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../canvas/dynamic_romantic_canvas.dart';

class MessageComposerScreen extends StatefulWidget {
  final Function({
    required String content,
    required String category,
    required String themeId,
    required String customBgColor,
    required String particleType,
    DateTime? scheduledTime,
  }) onSendMessage;

  const MessageComposerScreen({Key? key, required this.onSendMessage}) : super(key: key);

  @override
  State<MessageComposerScreen> createState() => _MessageComposerScreenState();
}

class _MessageComposerScreenState extends State<MessageComposerScreen> {
  final TextEditingController _textController = TextEditingController();

  String _selectedCategoryKey = '💖 رمانتیک و عاشقانه';
  String _selectedCategoryCode = 'romantic';
  String _selectedBgColor = '#2D0B1E';
  String _selectedParticle = 'heart';
  DateTime? _scheduledDateTime;

  final Map<String, String> _categoryCodeMap = {
    '💖 رمانتیک و عاشقانه': 'romantic',
    '🥺 دلتنگی و دوری': 'missing',
    '🌧️ ناراحتی، دلگیری و بغض': 'sadness',
    '🫂 دلجویی، آرامش و مراقبت': 'comfort',
    '💋 شیطنت، شوخی و شوق': 'playful',
    '🌙 شب‌بخیر و صبح‌بخیر خاص': 'night_morning',
    '🥀 قهر و گلایه نازدار': 'sulking',
    '🆘 بهت نیاز دارم و اضطرار': 'need_you',
  };

  final List<Map<String, dynamic>> _colorPresets = [
    {'name': 'زرشکی سلطنتی', 'color': const Color(0xFF2D0B1E), 'hex': '#2D0B1E'},
    {'name': 'صورتی رمانتیک', 'color': const Color(0xFF3B1425), 'hex': '#3B1425'},
    {'name': 'مشکی مخملی', 'color': const Color(0xFF0F0B18), 'hex': '#0F0B18'},
    {'name': 'بنفش نئونی', 'color': const Color(0xFF1E0B36), 'hex': '#1E0B36'},
    {'name': 'یاقوتی آتشین', 'color': const Color(0xFF5C071D), 'hex': '#5C071D'},
    {'name': 'زمردی تیره', 'color': const Color(0xFF0B241C), 'hex': '#0B241C'},
    {'name': 'طلایی کهربایی', 'color': const Color(0xFF2D1E0B), 'hex': '#2D1E0B'},
  ];

  final List<Map<String, dynamic>> _particlePresets = [
    {'id': 'heart', 'name': 'فوران قلب', 'icon': Icons.favorite, 'color': Color(0xFFF43F5E)},
    {'id': 'candle', 'name': 'اشک و چکه شمع', 'icon': Icons.wb_incandescent_outlined, 'color': Color(0xFFFBBF24)},
    {'id': 'rose', 'name': 'ریزش گلبرگ', 'icon': Icons.local_florist_outlined, 'color': Color(0xFFFB7185)},
    {'id': 'star', 'name': 'بارش ستاره', 'icon': Icons.star_purple500_outlined, 'color': Color(0xFFFDE047)},
    {'id': 'fire', 'name': 'شراره آتش', 'icon': Icons.local_fire_department_outlined, 'color': Color(0xFFF97316)},
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً متنی بنویسید یا یک جمله آماده انتخاب کنید', textDirection: TextDirection.rtl),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    widget.onSendMessage(
      content: text,
      category: _selectedCategoryCode,
      themeId: _selectedParticle,
      customBgColor: _selectedBgColor,
      particleType: _selectedParticle,
      scheduledTime: _scheduledDateTime,
    );

    _textController.clear();
    setState(() {
      _scheduledDateTime = null;
    });
  }

  void _previewCanvas() {
    final text = _textController.text.trim().isNotEmpty
        ? _textController.text.trim()
        : 'پیش‌نمایش بوم پالس: متن شما در این بوم پویا نمایش داده خواهد شد...';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicRomanticCanvas(
          messageText: text,
          customBgColor: _selectedBgColor,
          particleType: _selectedParticle,
          onDismiss: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Scrollable Upper Body (Text, Background/Particle Customizer, 160 Presets)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Text Input Box
                _buildInputBox(),
                const SizedBox(height: 16),

                // Custom Background & Particle Designer
                _buildStyleCustomizer(),
                const SizedBox(height: 16),

                // Category Accordions Header
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFFFB7185), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'جملات آماده (انتخاب سریع از ۱۶۰ پیام احساسی):',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 8 Accordion Sections with 20 sentences each
                ...AppConstants.presetCategories.entries.map((entry) {
                  return _buildCategoryAccordion(entry.key, entry.value);
                }).toList(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        // 2. FIXED STICKY BOTTOM BAR (Always Visible - No Scrolling Required!)
        _buildStickyBottomBar(),
      ],
    );
  }

  Widget _buildInputBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12030A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE11D48).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            maxLines: 4,
            minLines: 2,
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
            decoration: const InputDecoration(
              hintText: 'متن دلخواه یا احساس قلبی خود را اینجا بنویسید...',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
              hintTextDirection: TextDirection.rtl,
              border: InputBorder.none,
            ),
          ),
          if (_scheduledDateTime != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alarm, color: Color(0xFF14B8A6), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'زمان‌بندی: ${_scheduledDateTime!.hour.toString().padLeft(2, '0')}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _scheduledDateTime = null),
                    child: const Icon(Icons.close, color: Colors.white54, size: 14),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStyleCustomizer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0510),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Preview Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'طراحی سفارشی پس‌زمینه و المان متحرک:',
                style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _previewCanvas,
                icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFFFB7185)),
                label: const Text('پیش‌نمایش زنده', style: TextStyle(color: Color(0xFFFB7185), fontSize: 12)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 1. Color Palette Row
          const Text('رنگ تم زمینه:', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colorPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final item = _colorPresets[idx];
                final isSelected = _selectedBgColor == item['hex'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedBgColor = item['hex']),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item['color'],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.2,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: item['color'].withOpacity(0.7), blurRadius: 8, spreadRadius: 1)]
                          : [],
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 2. Particle Type Selector
          const Text('المان پویا (افکت حرکتی):', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _particlePresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final p = _particlePresets[idx];
                final isSelected = _selectedParticle == p['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedParticle = p['id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? p['color'].withOpacity(0.2) : Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? p['color'] : Colors.white12,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(p['icon'], size: 16, color: p['color']),
                        const SizedBox(width: 6),
                        Text(
                          p['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAccordion(String title, List<String> sentences) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF18040E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFFFB7185),
          collapsedIconColor: Colors.white38,
          title: Text(
            '$title (${sentences.length} پیام)',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          children: sentences.map((s) {
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              title: Text(
                s,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
              ),
              trailing: const Icon(Icons.arrow_upward, size: 16, color: Color(0xFFFB7185)),
              onTap: () {
                setState(() {
                  _textController.text = s;
                  _selectedCategoryKey = title;
                  _selectedCategoryCode = _categoryCodeMap[title] ?? 'romantic';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('متن در کادر درج شد؛ دکمه ارسال در پایین صفحه آماده است.', textDirection: TextDirection.rtl),
                    duration: const Duration(milliseconds: 1200),
                    backgroundColor: const Color(0xFF4C1D95),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0612),
        border: Border(top: BorderSide(color: const Color(0xFFE11D48).withOpacity(0.3), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Schedule Button
            IconButton(
              icon: const Icon(Icons.schedule, color: Color(0xFF14B8A6)),
              tooltip: 'زمان‌بندی ارسال (کپسول زمان)',
              onPressed: () async {
                final now = DateTime.now();
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
                );
                if (pickedTime != null) {
                  setState(() {
                    _scheduledDateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  });
                }
              },
            ),

            const SizedBox(width: 8),

            // Main Send Button (Glow gradient, always fixed & accessible)
            Expanded(
              child: GestureDetector(
                onTap: _submitMessage,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE11D48), Color(0xFFBE123C), Color(0xFF881337)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE11D48).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _scheduledDateTime != null ? 'ثبت کپسول زمان‌بندی‌شده' : 'ارسال فوری پالس',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
}
