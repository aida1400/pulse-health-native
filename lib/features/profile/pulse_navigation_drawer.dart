import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'contact_model.dart';
import 'contact_manager.dart';
import 'user_dashboard_dialog.dart';
import '../time_capsule/time_capsule_service.dart';
import '../notifications/unkillable_notification_service.dart';

class PulseNavigationDrawer extends StatefulWidget {
  final VoidCallback onEmergencyPanic;
  final VoidCallback onContactSwitched;

  const PulseNavigationDrawer({
    Key? key,
    required this.onEmergencyPanic,
    required this.onContactSwitched,
  }) : super(key: key);

  @override
  State<PulseNavigationDrawer> createState() => _PulseNavigationDrawerState();
}

class _PulseNavigationDrawerState extends State<PulseNavigationDrawer> {
  UserProfileModel? _profile;
  List<ContactModel> _contacts = [];
  bool _isLoading = true;

  final List<String> _avatarChoices = ['👑', '🌹', '💖', '🧕', '💍', '🦋', '🌸', '💎', '🕊️', '🍒'];

  @override
  void initState() {
    super.initState();
    _loadDrawerData();
  }

  Future<void> _loadDrawerData() async {
    final profile = await ContactManager.getUserProfile();
    final contacts = ContactManager.getAllContacts();
    setState(() {
      _profile = profile;
      _contacts = contacts;
      _isLoading = false;
    });
  }

  void _editUserProfile() {
    final nameCtrl = TextEditingController(text: _profile?.name ?? 'آیدا شفیع‌خانی');
    final phoneCtrl = TextEditingController(text: _profile?.phone ?? '۰۹۱۲۳۴۵۶۷۸۹');
    String selectedAvatar = _profile?.avatarEmoji ?? '👑';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF220512),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE11D48), width: 1.5),
          ),
          title: const Text(
            'ویرایش پروفایل کاربری',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Avatar Chooser
                const Text('انتخاب آیکون/تصویر پروفایل:', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _avatarChoices.map((av) {
                    final isSel = selectedAvatar == av;
                    return GestureDetector(
                      onTap: () => setDlgState(() => selectedAvatar = av),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFE11D48) : const Color(0xFF32071B),
                          shape: BoxShape.circle,
                          border: Border.all(color: isSel ? Colors.white : Colors.white24, width: 2),
                        ),
                        child: Center(child: Text(av, style: const TextStyle(fontSize: 22))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameCtrl,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'نام و نام خانوادگی',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF14030B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'شماره تماس',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF14030B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await ContactManager.updateUserProfile(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  avatarEmoji: selectedAvatar,
                );
                Navigator.pop(ctx);
                _loadDrawerData();
              },
              child: const Text('ذخیره', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditContactModal({ContactModel? contactToEdit}) {
    final isEditing = contactToEdit != null;
    final nameCtrl = TextEditingController(text: contactToEdit?.name ?? '');
    final codeCtrl = TextEditingController(text: contactToEdit?.partnerCode ?? '');
    String selectedRelation = contactToEdit?.relation ?? 'همسر';
    String selectedColor = contactToEdit?.colorHex ?? '#E11D48';
    String selectedAvatar = contactToEdit?.avatarEmoji ?? '❤️';

    final relations = ['همسر', 'مادر', 'خواهر', 'پارتنر', 'دوست', 'سایر'];
    final colors = ['#E11D48', '#BE123C', '#9F1239', '#F43F5E', '#FB7185', '#F59E0B'];
    final contactAvatars = ['❤️', '💍', '🧕', '👭', '🌸', '🌹', '👑', '🕊️'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E0510),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFFE11D48), width: 1.5),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'ویرایش اطلاعات مخاطب' : 'افزودن مخاطب و فضای جدید',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),

              // Avatar selection for contact
              const Text('آیکون مخاطب:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: contactAvatars.map((em) {
                  final isSel = selectedAvatar == em;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedAvatar = em),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFE11D48) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSel ? Colors.white : Colors.white24),
                      ),
                      child: Text(em, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: nameCtrl,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'نام یا عنوان (مثلاً: همسر، مامان، خواهر)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF12030A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Code Input with explicit LTR to prevent bi-directional reversal!
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: codeCtrl,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 4,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'کد ۶ رقمی پارتنر (مثال: A7X9K2)',
                    hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 1),
                    filled: true,
                    fillColor: const Color(0xFF12030A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Relation selection
              const Text('نسبت / عنوان:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: relations.map((rel) {
                  final isSelected = selectedRelation == rel;
                  return ChoiceChip(
                    label: Text(rel, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE11D48),
                    backgroundColor: const Color(0xFF2C0616),
                    onSelected: (val) {
                      setModalState(() => selectedRelation = rel);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim().toUpperCase();
                  if (name.isEmpty || code.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً نام و کد ۶ رقمی پارتنر را به درستی وارد نمایید', textDirection: TextDirection.rtl),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (isEditing) {
                    await ContactManager.updateContact(
                      id: contactToEdit.id,
                      name: name,
                      relation: selectedRelation,
                      partnerCode: code,
                      colorHex: selectedColor,
                      avatarEmoji: selectedAvatar,
                    );
                  } else {
                    await ContactManager.addContact(
                      name: name,
                      relation: selectedRelation,
                      partnerCode: code,
                      colorHex: selectedColor,
                      avatarEmoji: selectedAvatar,
                    );
                  }

                  Navigator.pop(ctx);
                  _loadDrawerData();
                  widget.onContactSwitched();
                },
                child: Text(
                  isEditing ? 'ذخیره تغییرات' : 'افزودن به لیست مخاطبان',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _switchContact(ContactModel contact) async {
    await ContactManager.switchActiveContact(contact.id);
    await TimeCapsuleService.switchContact(contact.id);
    Navigator.pop(context);
    widget.onContactSwitched();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF14030B),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. User Profile Header with Avatar & Red Theme
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: const BoxDecoration(
                      color: Color(0xFF220512),
                      border: Border(bottom: BorderSide(color: Color(0xFFE11D48), width: 1.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _editUserProfile,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFE11D48), Color(0xFF881337)],
                                      ),
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _profile?.avatarEmoji ?? '👑',
                                        style: const TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE11D48),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _profile?.name ?? 'آیدا شفیع‌خانی',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.white60, size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: _editUserProfile,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _profile?.phone ?? '۰۹۱۲۳۴۵۶۷۸۹',
                                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // User's own pulse code banner (Wrapped in Directionality LTR to prevent flipped characters!)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF100207),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE11D48).withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.qr_code_2_rounded, color: Color(0xFFFB7185), size: 18),
                                  const SizedBox(width: 8),
                                  const Text('کد من: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      _profile?.myCode ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: _profile?.myCode ?? ""));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('کد شما با موفقیت کپی شد', textDirection: TextDirection.rtl),
                                      backgroundColor: Color(0xFFE11D48),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Saved Contacts Section (Clean wording - no "manande snapp"!)
                  Padding(
                    padding: const EdgeInsets.only(right: 18, left: 18, top: 16, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'فضاهای خصوصی (مخاطبان):',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () => _showAddOrEditContactModal(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48).withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE11D48)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add, color: Color(0xFFFB7185), size: 15),
                                SizedBox(width: 4),
                                Text(
                                  'افزودن مخاطب',
                                  style: TextStyle(color: Color(0xFFFB7185), fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contacts List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        final isActive = contact.isActive;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF2C0717) : const Color(0xFF1E040E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive ? const Color(0xFFE11D48) : Colors.white12,
                              width: isActive ? 1.6 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B0A1E),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE11D48)),
                              ),
                              child: Center(
                                child: Text(contact.avatarEmoji, style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  contact.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE11D48).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE11D48)),
                                    ),
                                    child: const Text(
                                      'فضای فعال',
                                      style: TextStyle(color: Color(0xFFFB7185), fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  'کد: ',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                                ),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    contact.partnerCode.isEmpty ? "تنظیم نشده" : contact.partnerCode,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11.5,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isActive)
                                  IconButton(
                                    icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFFB7185), size: 22),
                                    tooltip: 'ورود به این فضا',
                                    onPressed: () => _switchContact(contact),
                                  ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                                  color: const Color(0xFF220512),
                                  onSelected: (val) async {
                                    if (val == 'edit') {
                                      _showAddOrEditContactModal(contactToEdit: contact);
                                    } else if (val == 'delete') {
                                      final success = await ContactManager.deleteContact(contact.id);
                                      if (success) {
                                        _loadDrawerData();
                                        widget.onContactSwitched();
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('حداقل یک مخاطب باید در سیستم فعال باشد', textDirection: TextDirection.rtl),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('ویرایش مخاطب', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white)),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('حذف فضا', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!isActive) {
                                _switchContact(contact);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // 3. Guaranteed Notification Self-Test Button & Dashboard Actions
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF220512),
                      border: Border(top: BorderSide(color: Color(0xFFE11D48), width: 1.5)),
                    ),
                    child: Column(
                      children: [
                        // Test Notification Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            await UnkillableNotificationService.testNotification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('نوتیفیکیشن با صدا و ویبره شبیه‌سازی شد! لطفاً بالای صفحه گوشی را بررسی فرمایید.', textDirection: TextDirection.rtl),
                                  backgroundColor: Color(0xFF10B981),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            'تست و فعال‌سازی فوری نوتیفیکیشن',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Dashboard Button
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.dashboard_outlined, color: Color(0xFFFB7185), size: 20),
                          title: const Text('داشبورد کدهای جفت‌سازی', style: TextStyle(color: Colors.white, fontSize: 13)),
                          onTap: () {
                            Navigator.pop(context);
                            UserDashboardDialog.show(context, onDataChanged: () {
                              _loadDrawerData();
                              widget.onContactSwitched();
                            });
                          },
                        ),

                        // Emergency Camouflage Button
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
                          title: const Text('تغییر قیافه فوری به مانیتور ضربان', style: TextStyle(color: Color(0xFF10B981), fontSize: 13)),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onEmergencyPanic();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
