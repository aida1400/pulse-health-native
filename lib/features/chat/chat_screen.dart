import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/persian_date_helper.dart';
import '../time_capsule/time_capsule_service.dart';
import '../serverless/serverless_relay_adapter.dart';
import '../canvas/dynamic_romantic_canvas.dart';
import '../pairing/pairing_manager.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback onEmergencyPanic;

  const ChatScreen({Key? key, required this.onEmergencyPanic}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _msgInputController = TextEditingController();
  final Map<String, GlobalKey> _dateHeaderKeys = {};

  List<PulseMessageModel> _messages = [];
  Map<String, List<PulseMessageModel>> _groupedMessages = {};
  Timer? _liveRefreshTimer;

  final List<String> _reactionEmojis = ['❤️', '🥺', '💋', '🫂', '😭', '✨'];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markIncomingMessagesAsSeen();
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (mounted) {
        _loadMessages();
        _markIncomingMessagesAsSeen();
      }
    });
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    _scrollController.dispose();
    _msgInputController.dispose();
    super.dispose();
  }

  int _lastMsgCount = 0;

  void _loadMessages({bool forceScroll = false}) {
    final all = TimeCapsuleService.getAllMessages();
    final bool hasNew = all.length > _lastMsgCount;
    _lastMsgCount = all.length;

    setState(() {
      _messages = all;
      _groupedMessages = TimeCapsuleService.getMessagesGroupedByDate();
      for (var key in _groupedMessages.keys) {
        _dateHeaderKeys.putIfAbsent(key, () => GlobalKey());
      }
    });

    if (forceScroll || hasNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// Automatically marks all received partner messages as 'seen' and dispatches seen receipt
  Future<void> _markIncomingMessagesAsSeen() async {
    for (var msg in _messages) {
      if (!msg.isSender && msg.status != 'seen') {
        msg.status = 'seen';
        msg.seenAt = DateTime.now();
        await TimeCapsuleService.updateMessageStatus(msg.id, 'seen', seenAt: msg.seenAt);
        await ServerlessRelayAdapter.sendReceipt(messageId: msg.id, receiptStatus: 'seen');
      }
    }
  }

  Future<void> _sendQuickChatMessage() async {
    final text = _msgInputController.text.trim();
    if (text.isEmpty) return;

    final myCode = await PairingManager.getOrCreateMyCode();
    final newMsg = PulseMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      category: 'romantic',
      themeId: 'heart',
      customBgColor: '#2D0B1E',
      particleType: 'heart',
      scheduledUnlockTime: DateTime.now(),
      status: 'sent',
      senderCode: myCode,
      isSender: true,
      createdAt: DateTime.now(),
    );

    await TimeCapsuleService.saveToVault(newMsg);
    await ServerlessRelayAdapter.sendMessage(message: newMsg);

    _msgInputController.clear();
    _loadMessages();
  }

  void _openCalendarPicker() {
    final distinctDates = _groupedMessages.keys.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF190C25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'انتخاب و پرش به تاریخ شمسی:',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (distinctDates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'هنوز پیامی در تاریخچه ثبت نشده است.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: distinctDates.map((dateLabel) {
                    final count = _groupedMessages[dateLabel]?.length ?? 0;
                    return ActionChip(
                      backgroundColor: const Color(0xFF2E103E),
                      side: BorderSide(color: const Color(0xFFFB7185).withOpacity(0.3)),
                      avatar: const Icon(Icons.calendar_today, size: 14, color: Color(0xFFFB7185)),
                      label: Text(
                        '$dateLabel ($count پیام)',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _jumpToDate(dateLabel);
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _jumpToDate(String dateLabel) {
    final key = _dateHeaderKeys[dateLabel];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openMessageCanvas(PulseMessageModel msg) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicRomanticCanvas(
          messageText: msg.content,
          customBgColor: msg.customBgColor,
          particleType: msg.particleType,
          onDismiss: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0715),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B0B27),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'چت محرمانه پالس',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Calendar Jump Button
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFFFB7185)),
            tooltip: 'تقویم شمسی و پرش به روز خاص',
            onPressed: _openCalendarPicker,
          ),
          // Panic Disguise Button
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Color(0xFF10B981)),
            tooltip: 'قفل فوری و استتار به مانیتور ضربان',
            onPressed: widget.onEmergencyPanic,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Messages Timeline grouped by Jalali Solar Date
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      children: _groupedMessages.entries.map((entry) {
                        final dateHeader = entry.key;
                        final dayMessages = entry.value;

                        return Column(
                          key: _dateHeaderKeys[dateHeader],
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Jalali Date Header Pill
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 14),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF261234),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: Text(
                                  dateHeader,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            // Messages of this day
                            ...dayMessages.map((msg) => _buildMessageBubble(msg)).toList(),
                          ],
                        );
                      }).toList(),
                    ),
            ),

            // Pinned Bottom Chat Input Bar
            _buildBottomInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 54, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text(
              'هنوز پیامی رد و بدل نشده است',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              'اولین پالس عاشقانه را برای پارتنر خود ارسال کنید ❤️',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(PulseMessageModel msg) {
    final isMe = msg.isSender;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _openMessageCanvas(msg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(colors: [Color(0xFF831843), Color(0xFF9D174D)])
                      : const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
                  borderRadius: BorderRadius.only(
                    topRight: const Radius.circular(18),
                    topLeft: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMe ? const Color(0xFF831843).withOpacity(0.3) : Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message Text
                    Text(
                      msg.content,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Meta: Time, Seen Status & Canvas Hint
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          PersianDateHelper.formatTime(msg.createdAt),
                          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(msg),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Reactions Display & Picker
            _buildReactionsSection(msg),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(PulseMessageModel msg) {
    if (msg.status == 'seen') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.done_all, size: 14, color: Color(0xFFF43F5E)),
          SizedBox(width: 2),
          Text('دیده شد', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      );
    } else if (msg.status == 'delivered') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.done_all, size: 14, color: Colors.white70),
          SizedBox(width: 2),
          Text('تحویل شد', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
        ],
      );
    } else {
      return const Icon(Icons.check, size: 14, color: Colors.white38);
    }
  }

  Widget _buildReactionsSection(PulseMessageModel msg) {
    final isMe = msg.isSender;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Display existing reactions
          if (msg.reactions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF261234),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                msg.reactions.join(' '),
                style: const TextStyle(fontSize: 13),
              ),
            ),

          // 2. Reaction Picker: STRICTLY ONLY RECIPIENT CAN REACT!
          // Sender CANNOT react to own message as requested by user.
          if (!isMe) ...[
            const SizedBox(width: 6),
            ..._reactionEmojis.map((emoji) {
              return GestureDetector(
                onTap: () async {
                  await TimeCapsuleService.addReaction(msg.id, emoji);
                  await ServerlessRelayAdapter.sendReaction(messageId: msg.id, reactionEmoji: emoji);
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(emoji, style: const TextStyle(fontSize: 15)),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF190B25),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF100717),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _msgInputController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'ارسال پیام کوتاه...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    hintTextDirection: TextDirection.rtl,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendQuickChatMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendQuickChatMessage,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFBE123C)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
