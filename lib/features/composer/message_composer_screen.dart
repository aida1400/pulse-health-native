import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../time_capsule/time_capsule_service.dart';

class MessageComposerScreen extends StatefulWidget {
  final Function(String content, String themeId, DateTime? scheduledTime) onSendMessage;
  const MessageComposerScreen({Key? key, required this.onSendMessage}) : super(key: key);

  @override
  State<MessageComposerScreen> createState() => _MessageComposerScreenState();
}

class _MessageComposerScreenState extends State<MessageComposerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  String _selectedTheme = 'hearts';
  DateTime? _scheduledDateTime;

  final Map<String, List<String>> _presets = {
    '💖 عاشقانه و پرشور': [
      'فقط خواستم بگم چقدر تموم دنیای منی...',
      'وسط شلوغی‌های روز، یه دفعه دلم برات پر کشید ❤️',
      'یاد چشمات افتادم و خستگی از تنم رفت.',
      'وجودت تنها چیزیه که حال دلم رو خوب می‌کنه.',
    ],
    '🫂 دلجویی و مراقبت': [
      'خستگی‌هات مال من، تو فقط لبخند بزن...',
      'مراقب خودت باش تموم وجودم، هیچ چیز ارزش استرست رو نداره.',
      'همیشه کنارتم، حتی وقتی فرسنگ‌ها از هم دوریم.',
      'یک چای گرم برای خودت بریز و بدون یکی این سر دنیا مدام به یادته.',
    ],
    '💋 شیطنت، رازها و شوق': [
      'یه راز خیلی مهم دارم که باید بدونی... بیش از حد عاشقتم!',
      'همین الان یه بوسه برات پست کردم، به دستت رسید؟ 💋',
      'امروز قشنگ‌تر از هر روز دیگه‌ای شدی، حواست هست؟',
    ],
    '🌙 شب‌بخیر و صبح‌بخیر خاص': [
      'شبت پر از آرامش دلیلِ دلخوشی‌های من... خوابای قشنگ ببینی ✨',
      'صبح قشنگت بخیر زیباترین آغاز روزم ☀️',
      'ستاره‌ها امشب دارن به قشنگی لبخندت حسودی می‌کنن.',
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (time == null) return;

    setState(() {
      _scheduledDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submitMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً متنی برای ارسال بنویسید یا یک پیام آماده انتخاب کنید.')),
      );
      return;
    }

    widget.onSendMessage(text, _selectedTheme, _scheduledDateTime);
    _textController.clear();
    setState(() {
      _scheduledDateTime = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('پیام با موفقیت رمزنگاری و ثبت شد.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0715),
      appBar: AppBar(
        backgroundColor: const Color(0xFF200F29),
        title: const Text('پالس اختصاصی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF43F5E),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'میز نگارش پیام'),
            Tab(text: 'صندوق تاریخچه پیام‌ها'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComposerTab(),
          _buildHistoryVaultTab(),
        ],
      ),
    );
  }

  Widget _buildComposerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Input Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E0E26),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4C1D54)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                  decoration: const InputDecoration(
                    hintText: 'دلت می‌خواد الان چی به پارتنرت بگی؟...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
                const Divider(color: Colors.white12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        Icons.schedule_rounded,
                        color: _scheduledDateTime != null ? const Color(0xFF10B981) : Colors.white60,
                        size: 18,
                      ),
                      label: Text(
                        _scheduledDateTime != null
                            ? 'موعد بازگشایی: ${_scheduledDateTime!.hour}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}'
                            : 'زمان‌بندی (کپسول زمان)',
                        style: TextStyle(
                          fontSize: 12,
                          color: _scheduledDateTime != null ? const Color(0xFF10B981) : Colors.white60,
                        ),
                      ),
                      onPressed: _pickDateTime,
                    ),
                    if (_scheduledDateTime != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                        onPressed: () => setState(() => _scheduledDateTime = null),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Theme selector
          const Text('انتخاب جلوه بصری پویا:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildThemeChip(id: 'hearts', label: '💖 فوران قلب‌ها'),
              const SizedBox(width: 8),
              _buildThemeChip(id: 'rain', label: '🌧️ باران پشت شیشه'),
              const SizedBox(width: 8),
              _buildThemeChip(id: 'candle', label: '🕯️ شمع رمانتیک'),
            ],
          ),
          const SizedBox(height: 24),

          // Categorized Presets Accordion
          const Text('دسته‌بندی پیام‌های آماده دلنشین:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._presets.entries.map((category) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0B22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF331640)),
              ),
              child: ExpansionTile(
                iconColor: const Color(0xFFF43F5E),
                collapsedIconColor: Colors.white38,
                title: Text(category.key, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                children: category.value.map((msg) {
                  return ListTile(
                    dense: true,
                    title: Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
                    trailing: const Icon(Icons.add_circle_outline, color: Color(0xFFF43F5E), size: 18),
                    onTap: () {
                      _textController.text = msg;
                    },
                  );
                }).toList(),
              ),
            );
          }).toList(),

          const SizedBox(height: 28),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              label: Text(
                _scheduledDateTime != null ? 'قفل در کپسول زمان و ارسال' : 'ارسال محرمانه به پارتنر',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              onPressed: _submitMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryVaultTab() {
    final messages = TimeCapsuleService.getAllMessages();

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 54),
            SizedBox(height: 16),
            Text('صندوق پیام‌های شما خالی است', style: TextStyle(color: Colors.white60, fontSize: 14)),
            SizedBox(height: 8),
            Text('هر پیامی که ارسال یا دریافت شود، در این صندوق نگهداری می‌شود.', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final item = messages[index];
        final isLocked = item.isLocked;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E0E26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isLocked ? const Color(0xFFF59E0B) : const Color(0xFF4C1D54)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isLocked ? Icons.lock_clock_rounded : Icons.check_circle_rounded,
                        color: isLocked ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLocked ? 'کپسول قفل‌دار (موعد بازگشایی در آینده)' : 'تحویل داده شده',
                        style: TextStyle(
                          color: isLocked ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (item.canBeEditedOrRecalled)
                    TextButton(
                      child: const Text('ابطال و پس گرفتن (Undo)', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 11)),
                      onPressed: () async {
                        await TimeCapsuleService.recallCapsule(id: item.id);
                        setState(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.content,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 8),
              Text(
                'ثبت: ${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeChip({required String id, required String label}) {
    final isSelected = _selectedTheme == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFE11D48),
      backgroundColor: const Color(0xFF1E0E26),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white60,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedTheme = id);
      },
    );
  }
}
