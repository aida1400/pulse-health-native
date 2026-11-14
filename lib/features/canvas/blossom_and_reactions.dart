import 'package:flutter/material.dart';

enum ReactionType { echoHeart, warmHug, kiss, quickText }

class BlossomAndReactionsBar extends StatefulWidget {
  final Function(ReactionType type, String? text) onReactionSent;
  const BlossomAndReactionsBar({Key? key, required this.onReactionSent}) : super(key: key);

  @override
  State<BlossomAndReactionsBar> createState() => _BlossomAndReactionsBarState();
}

class _BlossomAndReactionsBarState extends State<BlossomAndReactionsBar> {
  bool _isReplying = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E0A24).withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _isReplying ? _buildQuickReplyInput() : _buildActionButtons(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: '❤️',
          label: 'تپش پالس',
          onTap: () => widget.onReactionSent(ReactionType.echoHeart, null),
        ),
        _buildActionButton(
          icon: '🫂',
          label: 'آغوش گرم',
          onTap: () => widget.onReactionSent(ReactionType.warmHug, null),
        ),
        _buildActionButton(
          icon: '💋',
          label: 'بوسه',
          onTap: () => widget.onReactionSent(ReactionType.kiss, null),
        ),
        _buildActionButton(
          icon: '💬',
          label: 'پاسخ سریع',
          onTap: () => setState(() => _isReplying = true),
        ),
      ],
    );
  }

  Widget _buildActionButton({required String icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _replyController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'پاسخ عاشقانه تک‌خطی...',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send_rounded, color: Color(0xFFF43F5E), size: 20),
          onPressed: () {
            if (_replyController.text.trim().isNotEmpty) {
              widget.onReactionSent(ReactionType.quickText, _replyController.text.trim());
              _replyController.clear();
              setState(() => _isReplying = false);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white38, size: 18),
          onPressed: () => setState(() => _isReplying = false),
        ),
      ],
    );
  }
}
