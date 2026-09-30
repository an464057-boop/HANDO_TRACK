import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_theme.dart';

class ChangePasswordView extends StatefulWidget {
  final String username;
  const ChangePasswordView({super.key, required this.username});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSavePassword(BuildContext context, AppState appState, String lang, bool isRTL) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final newPassword = _newPasswordController.text;

      // Update password and automatically complete login
      await appState.updatePassword(widget.username, newPassword);

      // Username sync is handled during login session creation or profile management.

      setState(() {
        _isSaving = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'ar' ? 'تم تعيين كلمة المرور الجديدة وتأكيد الدخول!' : 'New password saved! Logged in successfully.',
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.success,
          ),
        );

        // Pop back to the LoginView (which will immediately transition to Dashboard because isLoggedIn is now true)
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.currentLanguage;
    final isRTL = lang == 'ar';

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
            // Floating Back Button
            Positioned(
              top: 24,
              right: isRTL ? 24 : null,
              left: isRTL ? null : 24,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(
                    isRTL ? FontAwesomeIcons.arrowRight : FontAwesomeIcons.arrowLeft,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Card centered layout
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
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
                        // Security Key Icon
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7), // Amber 100
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                FontAwesomeIcons.key,
                                size: 30,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            isRTL ? 'إعداد كلمة مرور جديدة' : 'Reset Default Password',
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
                                ? 'لأسباب أمنية، يرجى تغيير كلمة المرور الافتراضية (0000) للبدء في استخدام التطبيق'
                                : 'For security, please replace the default password (0000) to start using the application',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.lightNeutral,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // New Password Field
                        Text(
                          isRTL ? 'كلمة المرور الجديدة *' : 'New Password *',
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            color: AppTheme.darkNeutral,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          textDirection: isRTL ? TextDirection.ltr : TextDirection.ltr,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return isRTL ? 'يرجى إدخال كلمة المرور الجديدة' : 'Please enter new password';
                            }
                            if (val.length < 4) {
                              return isRTL ? 'يجب أن لا تقل كلمة المرور عن 4 رموز' : 'Password must be at least 4 characters';
                            }
                            if (val == '0000') {
                              return isRTL ? 'لا يمكنك استخدام كلمة المرور الافتراضية' : 'You cannot use the default password';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(FontAwesomeIcons.lock, size: 14, color: AppTheme.lightNeutral),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                                size: 14,
                                color: AppTheme.lightNeutral,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNew = !_obscureNew;
                                });
                              },
                            ),
                            hintText: isRTL ? 'أدخل كلمة مرور قوية...' : 'Type a strong password...',
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
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        Text(
                          isRTL ? 'تأكيد كلمة المرور *' : 'Confirm Password *',
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            color: AppTheme.darkNeutral,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          textDirection: isRTL ? TextDirection.ltr : TextDirection.ltr,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return isRTL ? 'يرجى تأكيد كلمة المرور' : 'Please confirm your password';
                            }
                            if (val != _newPasswordController.text) {
                              return isRTL ? 'كلمتا المرور غير متطابقتين!' : 'Passwords do not match!';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(FontAwesomeIcons.checkDouble, size: 14, color: AppTheme.lightNeutral),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                                size: 14,
                                color: AppTheme.lightNeutral,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                            hintText: isRTL ? 'أعد كتابة كلمة المرور...' : 'Retype password...',
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
                        const SizedBox(height: 32),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isSaving ? null : () => _handleSavePassword(context, appState, lang, isRTL),
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
                                  isRTL ? 'حفظ ودخول' : 'Save and Log In',
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
