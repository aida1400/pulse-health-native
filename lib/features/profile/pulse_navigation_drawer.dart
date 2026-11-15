import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'contact_model.dart';
import 'contact_manager.dart';
import 'user_dashboard_dialog.dart';
import '../time_capsule/time_capsule_service.dart';

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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E102E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'ویرایش مشخصات کاربری',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'نام و نام خانوادگی',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF12081C),
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
                fillColor: const Color(0xFF12081C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
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
              await ContactManager.updateUserProfile(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              _loadDrawerData();
            },
            child: const Text('ذخیره', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditContactModal({ContactModel? contactToEdit}) {
    final isEditing = contactToEdit != null;
    final nameCtrl = TextEditingController(text: contactToEdit?.name ?? '');
    final codeCtrl = TextEditingController(text: contactToEdit?.partnerCode ?? '');
    String selectedRelation = contactToEdit?.relation ?? 'همسر';
    String selectedColor = contactToEdit?.colorHex ?? '#FB7185';

    final relations = ['همسر', 'مادر', 'خواهر', 'پارتنر', 'دوست', 'سایر'];
    final colors = ['#FB7185', '#38BDF8', '#A855F7', '#34D399', '#FBBF24', '#F43F5E'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF190C25),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                    isEditing ? 'ویرایش مخاطب' : 'افزودن مخاطب جدید (مانند اسنپ)',
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

              // Name input
              TextField(
                controller: nameCtrl,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'نام یا برچسب (مثلاً: همسر، مامان، خواهر)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF12081C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Partner Code input
              TextField(
                controller: codeCtrl,
                textAlign: TextAlign.center,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 3, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'کد ۶ رقمی پارتنر/مخاطب',
                  hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 1),
                  filled: true,
                  fillColor: const Color(0xFF12081C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),

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
                    backgroundColor: const Color(0xFF261036),
                    onSelected: (val) {
                      setModalState(() => selectedRelation = rel);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Color Selection
              const Text('رنگ تم فضا:', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: colors.map((col) {
                  final colorObj = Color(int.parse(col.replaceFirst('#', '0xFF')));
                  final isSel = selectedColor == col;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedColor = col),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorObj,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2.5),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Save button
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
                        content: Text('لطفاً نام و کد ۶ رقمی را وارد نمایید', textDirection: TextDirection.rtl),
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
                    );
                  } else {
                    await ContactManager.addContact(
                      name: name,
                      relation: selectedRelation,
                      partnerCode: code,
                      colorHex: selectedColor,
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
    Navigator.pop(context); // close drawer
    widget.onContactSwitched();
  }

  IconData _getRelationIcon(String relation) {
    switch (relation) {
      case 'همسر':
        return Icons.favorite_rounded;
      case 'مادر':
        return Icons.volunteer_activism_rounded;
      case 'خواهر':
        return Icons.face_3_rounded;
      case 'پارتنر':
        return Icons.favorite_border_rounded;
      case 'دوست':
        return Icons.emoji_emotions_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF14081E),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFB7185)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. User Profile Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    decoration: const BoxDecoration(
                      color: Color(0xFF220C32),
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE11D48), Color(0xFF831843)],
                                ),
                                border: Border.all(color: Colors.white24, width: 2),
                              ),
                              child: const Center(
                                child: Icon(Icons.favorite, color: Colors.white, size: 26),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: _editUserProfile,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _profile?.phone ?? '۰۹۱۲۳۴۵۶۷۸۹',
                                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // User's own pulse code banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF13061C),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFB7185).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.qr_code_2_rounded, color: Color(0xFFFB7185), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'کد من: ${_profile?.myCode ?? ""}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: _profile?.myCode ?? ""));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('کد شما کپی شد', textDirection: TextDirection.rtl),
                                      backgroundColor: Color(0xFF10B981),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.copy_rounded, color: Colors.white60, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Saved Contacts Section (Snapp-style address cards)
                  Padding(
                    padding: const EdgeInsets.only(right: 18, left: 18, top: 16, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'مخاطبان و فضاها (مانند اسنپ):',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () => _showAddOrEditContactModal(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE11D48).withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add, color: Color(0xFFFB7185), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'افزودن فرد',
                                  style: TextStyle(color: Color(0xFFFB7185), fontSize: 11, fontWeight: FontWeight.bold),
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
                        final colorObj = Color(int.parse(contact.colorHex.replaceFirst('#', '0xFF')));

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF2B103E) : const Color(0xFF1B0927),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive ? colorObj : Colors.white12,
                              width: isActive ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: colorObj.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: colorObj),
                              ),
                              child: Icon(_getRelationIcon(contact.relation), color: colorObj, size: 20),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  contact.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF10B981)),
                                    ),
                                    child: const Text(
                                      'فعال',
                                      style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              'کد پارتنر: ${contact.partnerCode.isEmpty ? "تنظیم نشده" : contact.partnerCode}',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isActive)
                                  IconButton(
                                    icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF38BDF8), size: 20),
                                    tooltip: 'سوئیچ به این فضا',
                                    onPressed: () => _switchContact(contact),
                                  ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                                  color: const Color(0xFF1F0D30),
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
                                            content: Text('حداقل یک مخاطب باید در سیستم باقی بماند', textDirection: TextDirection.rtl),
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

                  // 3. Bottom Settings & Dashboard Actions
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1C0A28),
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: Column(
                      children: [
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
                          title: const Text('تغییر قیافه فوری (مانیتور ضربان)', style: TextStyle(color: Color(0xFF10B981), fontSize: 13)),
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
