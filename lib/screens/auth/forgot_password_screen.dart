import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1; // 1 = Request Code, 2 = Verify Code & Set New Password
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Step 1: Request Reset Code
  Future<void> _requestCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final result = await ApiService.forgotPassword(email: email);

      if (result['message'] != null && result['error'] == null) {
        setState(() {
          _step = 2;
          _successMessage = 'Reset code aapke email pe bhej diya gaya hai.';
        });
      } else {
        setState(() {
          _errorMessage = result['detail'] ?? result['error'] ?? 'Request failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Is backend running?';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Step 2: Verify Code and Reset Password
  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords match nahi kar rahe';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await ApiService.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (result['message'] != null && result['error'] == null) {
        setState(() {
          _successMessage = '✅ Password kamyabi se update ho gaya hai!';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
        }
      } else {
        setState(() {
          _errorMessage = result['detail'] ?? result['error'] ?? 'Reset failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Is backend running?';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (_step == 2) {
              setState(() {
                _step = 1;
                _errorMessage = null;
                _successMessage = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _step == 1 ? 'Forgot Password' : 'Reset Password',
          style: AppTextStyles.heading3,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.red.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Icon(
                      _step == 1 ? Icons.lock_reset_rounded : Icons.mark_email_read_rounded,
                      color: AppColors.red,
                      size: 38,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  _step == 1
                      ? 'Apna email address enter karein taake reset code bheja ja sake.'
                      : 'Email par bheja gaya 6-digit code aur naya password enter karein.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ),
              const SizedBox(height: 32),

              // Feedback Messages
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // STEP 1 FORM
              if (_step == 1)
                Form(
                  key: _emailFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email Address', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'name@example.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.red, size: 20),
                        ),
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Send Reset Code',
                        isLoading: _isLoading,
                        onPressed: _requestCode,
                      ),
                    ],
                  ),
                ),

              // STEP 2 FORM
              if (_step == 2)
                Form(
                  key: _resetFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('6-Digit Verification Code', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.required(v, fieldName: 'Reset Code'),
                        style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 18),
                        maxLength: 6,
                        decoration: const InputDecoration(
                          hintText: '123456',
                          counterText: '',
                          prefixIcon: Icon(Icons.pin_rounded, color: AppColors.red, size: 20),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text('New Password', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscurePassword,
                        validator: (v) => Validators.minLength(v, 6, fieldName: 'Password'),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'At least 6 characters',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.red, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text('Confirm New Password', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        validator: (v) => Validators.required(v, fieldName: 'Confirm Password'),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Repeat new password',
                          prefixIcon: Icon(Icons.lock_reset_rounded, color: AppColors.red, size: 20),
                        ),
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Reset Password',
                        isLoading: _isLoading,
                        onPressed: _resetPassword,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
