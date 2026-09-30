import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_theme.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

class ProfileSetupView extends StatefulWidget {
  const ProfileSetupView({super.key});

  @override
  State<ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<ProfileSetupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  
  String? _selectedRole;
  String? _selectedDept;
  bool _isSaving = false;

  final List<String> _roles = ['فني', 'مشرف', 'مهندس', 'مدير'];
  final List<String> _departments = ['تشكيل', 'دهان', 'تجميع', 'قصدرة', 'جودة', 'لحام'];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleSaveProfile(BuildContext context, AppState appState, String lang, bool isRTL) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final name = _nameController.text.trim();
      final code = _codeController.text.trim();
      final role = _selectedRole!;
      
      // Managers do not belong to a production line department
      final department = role == 'مدير' ? (lang == 'ar' ? 'الإدارة' : 'Management') : _selectedDept!;

      final newUser = UserModel(
        id: code,
        name: name,
        role: role,
        department: department,
        avatar: 'assets/avatar.png',
      );

      // Save user details
      await FirebaseService.saveUser(newUser);
      
      // Update memory state
      appState.updateCurrentUser(newUser);
      
      // Set profile registration as completed
      await appState.completeProfile();

      setState(() {
        _isSaving = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'ar' ? 'تم حفظ الملف الشخصي بنجاح!' : 'Profile saved successfully!',
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';

    final showDepartment = _selectedRole != null && _selectedRole != 'مدير';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Floating Language Toggle
            Positioned(
              top: 24,
              right: isRTL ? null : 24,
              left: isRTL ? 24 : null,
              child: SafeArea(
                child: TextButton.icon(
                  onPressed: () => appState.toggleLanguage(),
                  icon: const Icon(FontAwesomeIcons.language, size: 16, color: Colors.white),
                  label: Text(
                    isRTL ? 'English' : 'العربية',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                  ),
                ),
              ),
            ),

            // Main Registration Card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // User Profile Setup Icon
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                FontAwesomeIcons.userPen,
                                size: 28,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            isRTL ? 'إكمال بيانات الملف الشخصي' : 'Complete User Profile',
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.darkNeutral,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            isRTL
                                ? 'يرجى كتابة الاسم وتحديد المسمى الوظيفي والقسم لبدء استخدام التطبيق'
                                : 'Please fill in your name, employee details, and job role to begin',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.lightNeutral,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Name Field
                        Text(
                          isRTL ? 'الاسم بالكامل *' : 'Full Name *',
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            color: AppTheme.darkNeutral,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isRTL ? 'يرجى كتابة الاسم' : 'Please enter your name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(FontAwesomeIcons.userTag, size: 14, color: AppTheme.lightNeutral),
                            hintText: isRTL ? 'اكتب اسمك الثلاثي...' : 'Type your full name...',
                            hintStyle: const TextStyle(color: AppTheme.lightNeutral, fontSize: 13),
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
                        ),
                        const SizedBox(height: 18),

                        // Employee Code Field
                        Text(
                          isRTL ? 'كود الموظف (ID) *' : 'Employee Code (ID) *',
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            color: AppTheme.darkNeutral,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _codeController,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          textDirection: isRTL ? TextDirection.ltr : TextDirection.ltr,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isRTL ? 'يرجى كتابة كود الموظف' : 'Please enter employee ID';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(FontAwesomeIcons.idCard, size: 14, color: AppTheme.lightNeutral),
                            hintText: isRTL ? 'مثال: EMP-001...' : 'Example: EMP-001...',
                            hintStyle: const TextStyle(color: AppTheme.lightNeutral, fontSize: 13),
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
                        ),
                        const SizedBox(height: 18),

                        // Job Role Dropdown Field
                        Text(
                          isRTL ? 'الوظيفة / المسمى الوظيفي *' : 'Job Role *',
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            color: AppTheme.darkNeutral,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                          icon: const Icon(FontAwesomeIcons.chevronDown, size: 14, color: AppTheme.lightNeutral),
                          validator: (val) => val == null ? (isRTL ? 'يرجى اختيار الوظيفة' : 'Please select job role') : null,
                          onChanged: (val) {
                            setState(() {
                              _selectedRole = val;
                              // If Manager, clear department selection
                              if (val == 'مدير') {
                                _selectedDept = null;
                              }
                            });
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(FontAwesomeIcons.briefcase, size: 14, color: AppTheme.lightNeutral),
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
                          items: _roles.map((role) {
                            // Translate display options
                            String displayText = role;
                            if (!isRTL) {
                              if (role == 'فني') displayText = 'Technician';
                              if (role == 'مشرف') displayText = 'Supervisor';
                              if (role == 'مهندس') displayText = 'Engineer';
                              if (role == 'مدير') displayText = 'Manager';
                            }
                            return DropdownMenuItem(
                              value: role,
                              child: Align(
                                alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                                child: Text(
                                  displayText,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        // Conditional Department Dropdown Field
                        if (showDepartment) ...[
                          const SizedBox(height: 18),
                          Text(
                            isRTL ? 'القسم *' : 'Department *',
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            style: const TextStyle(
                              color: AppTheme.darkNeutral,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedDept,
                            isExpanded: true,
                            alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                            icon: const Icon(FontAwesomeIcons.chevronDown, size: 14, color: AppTheme.lightNeutral),
                            validator: (val) => val == null ? (isRTL ? 'يرجى اختيار القسم' : 'Please select department') : null,
                            onChanged: (val) {
                              setState(() {
                                _selectedDept = val;
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(FontAwesomeIcons.networkWired, size: 14, color: AppTheme.lightNeutral),
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
                            items: _departments.map((dept) {
                              // Translate display options
                              String displayText = dept;
                              if (!isRTL) {
                                if (dept == 'تشكيل') displayText = 'Forming / Sheet Metal';
                                if (dept == 'دهان') displayText = 'Painting';
                                if (dept == 'تجميع') displayText = 'Assembly';
                                if (dept == 'قصدرة') displayText = 'Tinning';
                                if (dept == 'جودة') displayText = 'Quality Control';
                                if (dept == 'لحام') displayText = 'Welding';
                              }
                              return DropdownMenuItem(
                                value: dept,
                                child: Align(
                                  alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Text(
                                    displayText,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Save Button
                        ElevatedButton(
                          onPressed: _isSaving ? null : () => _handleSaveProfile(context, appState, lang, isRTL),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius),
                            ),
                            elevation: 2,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isRTL ? 'حفظ ودخول' : 'Save and Continue',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ],
                    ),
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
