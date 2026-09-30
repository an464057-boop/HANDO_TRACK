import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/translations.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _deptController;
  late TextEditingController _roleController;
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _deptController = TextEditingController(text: user?.department ?? '');
    // Extracts Job role excluding department suffix
    final fullRole = user?.role ?? '';
    final roleText = fullRole.contains(' - ') ? fullRole.split(' - ')[0] : fullRole;
    _roleController = TextEditingController(text: roleText);
    _avatarBase64 = user?.avatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _deptController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  // Edit Avatar Picker
  Future<void> _pickAvatar(String lang) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/png;base64,${base64Encode(bytes)}';

        setState(() {
          _avatarBase64 = base64String;
        });

        // Auto save to AppState
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.updateUserProfile(
          name: _nameController.text.trim(),
          department: _deptController.text.trim(),
          role: _roleController.text.trim(),
          avatarDataUrl: base64String,
        );

        _showToast(Translations.get('avatar_success', lang), isSuccess: true, lang: lang);
      }
    } catch (e) {
      _showToast(Translations.get('avatar_error', lang), isSuccess: false, lang: lang);
    }
  }

  void _showToast(String message, {required bool isSuccess, required String lang}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: lang == 'ar' ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: lang == 'ar'
              ? [
                  Text(
                    message,
                    style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSuccess ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circleXmark,
                    color: Colors.white,
                    size: 16,
                  ),
                ]
              : [
                  Icon(
                    isSuccess ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circleXmark,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
                  ),
                ],
        ),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.danger,
      ),
    );
  }

  void _saveProfile(String lang) async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final dept = _deptController.text.trim();
      final role = _roleController.text.trim();

      if (name.isEmpty || dept.isEmpty || role.isEmpty) {
        return;
      }

      final appState = Provider.of<AppState>(context, listen: false);
      await appState.updateUserProfile(
        name: name,
        department: dept,
        role: role,
        avatarDataUrl: _avatarBase64,
      );

      _showToast(Translations.get('profile_success', lang), isSuccess: true, lang: lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Dynamic role translation replacement
    String displayRole = user.role;
    if (lang == 'en') {
      displayRole = displayRole.replaceAll('مشرف', 'Supervisor');
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    final avatarCard = Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.shadow,
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _pickAvatar(lang),
            borderRadius: BorderRadius.circular(100),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildLargeAvatar(_avatarBase64),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(FontAwesomeIcons.camera, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user.name,
            style: const TextStyle(color: AppTheme.darkNeutral, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            displayRole,
            style: const TextStyle(color: AppTheme.lightNeutral, fontSize: 14, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              user.id,
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );

    final formCard = Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.shadow,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Translations.get('profile_title', lang),
              style: const TextStyle(color: AppTheme.darkNeutral, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 20),
            _buildReadOnlyInput(label: Translations.get('profile_emp_id', lang), value: user.id, isRTL: isRTL),
            const SizedBox(height: 16),
            _buildTextInput(label: Translations.get('profile_name', lang), controller: _nameController, lang: lang, isRTL: isRTL),
            const SizedBox(height: 16),
            _buildTextInput(label: Translations.get('profile_role', lang), controller: _roleController, lang: lang, isRTL: isRTL),
            const SizedBox(height: 16),
            _buildTextInput(label: Translations.get('profile_dept', lang), controller: _deptController, lang: lang, isRTL: isRTL),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: isRTL ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _saveProfile(lang),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                  ),
                  child: Text(
                    Translations.get('btn_save', lang),
                    style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [avatarCard, const SizedBox(height: 16), formCard],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isRTL
            ? [Expanded(flex: 1, child: avatarCard), const SizedBox(width: 24), Expanded(flex: 2, child: formCard)]
            : [Expanded(flex: 2, child: formCard), const SizedBox(width: 24), Expanded(flex: 1, child: avatarCard)],
      ),
    );
  }


  Widget _buildLargeAvatar(String? avatar) {
    if (avatar == null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primaryLight, width: 4),
        ),
        child: const Center(
          child: Icon(FontAwesomeIcons.user, color: AppTheme.primary, size: 48),
        ),
      );
    }

    ImageProvider imageProvider;
    if (avatar.startsWith('data:image') || avatar.startsWith('base64,')) {
      final base64String = avatar.substring(avatar.indexOf(',') + 1);
      imageProvider = MemoryImage(base64Decode(base64String));
    } else {
      imageProvider = AssetImage(avatar);
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryLight, width: 4),
        boxShadow: AppTheme.shadow,
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildFormRow({required bool isWide, required Widget child1, required Widget child2, required bool isRTL}) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isRTL
            ? [
                Expanded(child: child1),
                const SizedBox(width: 24),
                Expanded(child: child2),
              ]
            : [
                Expanded(child: child2),
                const SizedBox(width: 24),
                Expanded(child: child1),
              ],
      );
    } else {
      return Column(
        children: [
          child2,
          const SizedBox(height: 20),
          child1,
        ],
      );
    }
  }

  Widget _buildTextInput({required String label, required TextEditingController controller, required String lang, required bool isRTL}) {
    return Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.darkNeutral,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              borderSide: const BorderSide(color: AppTheme.borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return Translations.get('field_required', lang);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReadOnlyInput({required String label, required String value, required bool isRTL}) {
    return Column(
      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.darkNeutral,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.borderColor, width: 1.5),
          ),
          alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.lightNeutral,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
