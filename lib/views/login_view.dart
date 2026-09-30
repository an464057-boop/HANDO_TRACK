import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/translations.dart';
import 'change_password_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context, AppState appState, String lang, bool isRTL) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoggingIn = true;
      });

      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      // First-time password reset check
      if (password == '0000') {
        setState(() {
          _isLoggingIn = false;
        });
        
        // Route to Change Password View
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordView(username: username),
            ),
          );
        }
        return;
      }

      final success = await appState.login(username, password);

      setState(() {
        _isLoggingIn = false;
      });

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang == 'ar' ? 'تم تسجيل الدخول بنجاح!' : 'Logged in successfully!',
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
                style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang == 'ar' ? 'اسم المستخدم أو كلمة المرور غير صحيحة!' : 'Incorrect username or password!',
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
                style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
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
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E293B), // Slate 800
              Color(0xFF0F172A), // Slate 900
            ],
          ),
        ),
        child: Stack(
          children: [
            // Floating Lang Switch Button
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
                        // App Logo & Header
                        Center(
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            Translations.get('app_title', lang),
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.darkNeutral,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            isRTL ? 'سجل دخول للبدء في إدارة تسليمات الشغل' : 'Log in to start managing job order handovers',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.lightNeutral,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Username Field (Employee Code)
                        Text(
                          isRTL ? 'كود العامل *' : 'Employee Code *',
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            color: AppTheme.darkNeutral,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isRTL ? 'يرجى إدخال كود العامل' : 'Please enter your employee code';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(FontAwesomeIcons.user, size: 14, color: AppTheme.lightNeutral),
                            hintText: isRTL ? 'اكتب كود العامل هنا...' : 'Type your employee code...',
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

                        // Password Field
                        Text(
                          isRTL ? 'كلمة المرور *' : 'Password *',
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            color: AppTheme.darkNeutral,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          textDirection: isRTL ? TextDirection.ltr : TextDirection.ltr,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return isRTL ? 'يرجى إدخال كلمة المرور' : 'Please enter your password';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(FontAwesomeIcons.lock, size: 14, color: AppTheme.lightNeutral),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                                size: 14,
                                color: AppTheme.lightNeutral,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            hintText: isRTL ? 'اكتب كلمة المرور...' : 'Type your password...',
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
                          onPressed: _isLoggingIn ? null : () => _handleLogin(context, appState, lang, isRTL),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoggingIn
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isRTL ? 'تسجيل الدخول' : 'Log In',
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
