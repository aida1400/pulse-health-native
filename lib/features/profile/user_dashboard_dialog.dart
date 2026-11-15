import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pairing/pairing_manager.dart';
import 'contact_manager.dart';

class UserDashboardDialog extends StatefulWidget {
  final VoidCallback onDataChanged;

  const UserDashboardDialog({Key? key, required this.onDataChanged}) : super(key: key);

  static void show(BuildContext context, {required VoidCallback onDataChanged}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => UserDashboardDialog(onDataChanged: onDataChanged),
    );
  }

  @override
  State<UserDashboardDialog> createState() => _UserDashboardDialogState();
}

class _UserDashboardDialogState extends State<UserDashboardDialog> {
  String _myCode = '...';
  String _partnerCode = '...';
  String _activeContactName = 'پارتنر';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final myCode = await PairingManager.getOrCreateMyCode();
    final active = ContactManager.getActiveContact();
    setState(() {
      _myCode = myCode;
      _partnerCode = active?.partnerCode ?? 'ثبت نشده';
      _activeContactName = active?.name ?? 'پارتنر';
      _isLoading = false;
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label کپی شد: $text', textDirection: TextDirection.rtl),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editPartnerCode() {
    final controller = TextEditingController(text: _partnerCode == 'ثبت نشده' ? '' : _partnerCode);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E102E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ویرایش کد $_activeContactName',
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4, fontWeight: FontWeight.bold),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: 'کد ۶ رقمی',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 2),
            filled: true,
            fillColor: const Color(0xFF12081C),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB7185),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newCode = controller.text.trim().toUpperCase();
              if (newCode.length == 6) {
                final active = ContactManager.getActiveContact();
                if (active != null) {
                  await ContactManager.updateContact(id: active.id, partnerCode: newCode);
                }
                await PairingManager.pairWithPartner(newCode);
                Navigator.pop(ctx);
                _loadData();
                widget.onDataChanged();
              }
            },
            child: const Text('ذخیره کد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF180A22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFB7185).withOpacity(0.2)),
        ),
        child: _isLoading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFFFB7185))))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.dashboard_customize_outlined, color: Color(0xFFFB7185), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'داشبورد کدهای جفت‌سازی',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 20),

                  // 1. My Pairing Code Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF261036),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFB7185).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'کد اختصاصی من (فرستنده)',
                              style: TextStyle(color: Color(0xFFFB7185), fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                              tooltip: 'کپی کد من',
                              onPressed: () => _copyToClipboard(_myCode, 'کد اختصاصی شما'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: SelectableText(
                            _myCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'این کد را در گوشی مخاطب/پارتنر وارد کنید',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Partner Pairing Code Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14071D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'کد متصل: $_activeContactName',
                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                                  tooltip: 'ویرایش کد مخاطب',
                                  onPressed: _editPartnerCode,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                                  tooltip: 'کپی کد پارتنر',
                                  onPressed: () => _copyToClipboard(_partnerCode, 'کد پارتنر'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: SelectableText(
                            _partnerCode,
                            style: TextStyle(
                              color: _partnerCode == 'ثبت نشده' ? Colors.white38 : Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Indicator Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'کانال رمزنگاری دونفره فعال (AES-256 + HMAC)',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Close button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('بستن داشبورد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
      ),
    );
  }
}
