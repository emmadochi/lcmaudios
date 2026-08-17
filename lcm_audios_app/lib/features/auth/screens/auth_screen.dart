import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/api_service.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleAuthSubmit() async {
    final isSignIn = _tabController.index == 0;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    // Validation
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    if (!isSignIn && name.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final playerService = Provider.of<AudioPlayerService>(context, listen: false);

    try {
      if (isSignIn) {
        // Sign In Request
        final result = await ApiService.login(email: email, password: password);

        if (result['success'] == true) {
          final user = result['user'] as Map<String, dynamic>;
          final token = result['token'] as String;

          await playerService.saveAuthSession(
            token: token,
            userId: user['id']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
            email: user['email'] ?? email,
            fullName: user['fullName'] ?? 'Grace Worshipper',
          );

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigationShell()),
            );
          }
        } else {
          _showError(result['error'] ?? 'Sign in failed. Please check your credentials.');
        }
      } else {
        // Sign Up Request
        final result = await ApiService.register(
          email: email,
          password: password,
          fullName: name,
        );

        if (result['success'] == true) {
          final user = result['user'] as Map<String, dynamic>;
          final token = result['token'] as String;

          await playerService.saveAuthSession(
            token: token,
            userId: user['id']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
            email: user['email'] ?? email,
            fullName: user['fullName'] ?? name,
          );

          if (mounted) {
            // New accounts proceed to onboarding intent selection
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          }
        } else {
          _showError(result['error'] ?? 'Account creation failed. Please try again.');
        }
      }
    } catch (e) {
      _showError('Authentication error. Please check your connection.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '39253804126-f61fdfn5hqdecn98bmbq0vbak9kadefd.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();

      if (account == null) {
        // User cancelled Google account picker
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final result = await ApiService.loginWithGoogle(
        email: account.email,
        fullName: account.displayName ?? account.email.split('@')[0],
        photoUrl: account.photoUrl,
        googleId: account.id,
      );

      if (result['success'] == true) {
        if (!mounted) return;
        final user = result['user'] as Map<String, dynamic>;
        final token = result['token'] as String;
        final playerService = Provider.of<AudioPlayerService>(context, listen: false);

        await playerService.saveAuthSession(
          token: token,
          userId: user['id']?.toString() ?? account.id,
          email: user['email'] ?? account.email,
          fullName: user['fullName'] ?? account.displayName ?? 'Grace Worshipper',
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationShell()),
          );
        }
      } else {
        _showError(result['error'] ?? 'Google sign-in failed on server.');
      }
    } catch (e) {
      debugPrint('[Google Auth Error] $e');
      final errorStr = e.toString();
      if (errorStr.contains('network_error') || errorStr.contains('7')) {
        _showError('Network error connecting to Google Play Services.');
      } else {
        _showError('Google Sign-In: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordModal(BuildContext context) {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final otpCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    int currentStep = 1; // 1 = Request OTP, 2 = Enter OTP & New Password
    bool isModalLoading = false;
    String? modalError;
    String? generatedOtpHint;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: AppColors.glassBorder)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentStep == 1 ? 'Reset Password' : 'Enter 6-Digit Code',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentStep == 1
                                  ? 'Enter your email to receive a reset code'
                                  : 'Enter the code and set your new password',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (modalError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalError!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (generatedOtpHint != null && currentStep == 2) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Verification Code: $generatedOtpHint',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (currentStep == 1) ...[
                      _buildTextField(
                        controller: emailCtrl,
                        hint: 'Your registered email',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isModalLoading
                              ? null
                              : () async {
                                  final email = emailCtrl.text.trim();
                                  if (email.isEmpty || !email.contains('@')) {
                                    setModalState(() => modalError = 'Please enter a valid email address.');
                                    return;
                                  }
                                  setModalState(() {
                                    isModalLoading = true;
                                    modalError = null;
                                  });

                                  final res = await ApiService.forgotPassword(email);
                                  setModalState(() => isModalLoading = false);

                                  if (res['success'] == true) {
                                    setModalState(() {
                                      currentStep = 2;
                                      generatedOtpHint = res['otp']?.toString();
                                    });
                                  } else {
                                    setModalState(() => modalError = res['error'] ?? 'Failed to send code.');
                                  }
                                },
                          child: isModalLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('SEND 6-DIGIT CODE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      _buildTextField(
                        controller: otpCtrl,
                        hint: '6-Digit Verification Code',
                        icon: Icons.pin_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: newPasswordCtrl,
                        hint: 'New Password (min. 6 chars)',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isModalLoading
                              ? null
                              : () async {
                                  final otp = otpCtrl.text.trim();
                                  final newPass = newPasswordCtrl.text.trim();
                                  if (otp.length != 6) {
                                    setModalState(() => modalError = 'Please enter the 6-digit code.');
                                    return;
                                  }
                                  if (newPass.length < 6) {
                                    setModalState(() => modalError = 'Password must be at least 6 characters.');
                                    return;
                                  }

                                  setModalState(() {
                                    isModalLoading = true;
                                    modalError = null;
                                  });

                                  final res = await ApiService.resetPassword(
                                    email: emailCtrl.text.trim(),
                                    otp: otp,
                                    newPassword: newPass,
                                  );

                                  setModalState(() => isModalLoading = false);

                                  if (res['success'] == true) {
                                    if (!context.mounted) return;
                                    final token = res['token'] as String;
                                    final user = res['user'] as Map<String, dynamic>;
                                    final playerService = Provider.of<AudioPlayerService>(context, listen: false);

                                    await playerService.saveAuthSession(
                                      token: token,
                                      userId: user['id']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
                                      email: user['email'] ?? emailCtrl.text.trim(),
                                      fullName: user['fullName'] ?? 'Faith Worshipper',
                                    );

                                    if (context.mounted) {
                                      Navigator.of(modalCtx).pop();
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                                      );
                                    }
                                  } else {
                                    setModalState(() => modalError = res['error'] ?? 'Reset failed.');
                                  }
                                },
                          child: isModalLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('RESET PASSWORD & SIGN IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleGuestEntry() {
    final playerService = Provider.of<AudioPlayerService>(context, listen: false);
    playerService.setUserName('Grace Worshipper');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              AppColors.primaryGlow,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Brand Logo
                  Image.asset(
                    'assets/images/logo2White.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Faith in Motion • Audio Ecosystem',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Auth Glassmorphism Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.glassBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab Selector (Sign In vs Sign Up)
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: AppColors.primary,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.textMuted,
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Sign In'),
                              Tab(text: 'Create Account'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form Inputs
                        SizedBox(
                          height: 235,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Sign In Form
                              Column(
                                children: [
                                  _buildTextField(
                                    controller: _emailController,
                                    hint: 'Email Address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hint: 'Password (min. 6 characters)',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _showForgotPasswordModal(context),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Sign Up Form
                              Column(
                                children: [
                                  _buildTextField(
                                    controller: _nameController,
                                    hint: 'Full Name',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _emailController,
                                    hint: 'Email Address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hint: 'Password (min. 6 characters)',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action Button with Loading Indicator
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _isLoading ? null : _handleAuthSubmit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'CONTINUE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Divider
                        const Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.glassBorder)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('OR', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ),
                            Expanded(child: Divider(color: AppColors.glassBorder)),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Social Fast Access Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                label: 'Google',
                                icon: Icons.g_mobiledata_rounded,
                                onPressed: _handleGoogleSignIn,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSocialButton(
                                label: 'Apple',
                                icon: Icons.apple_rounded,
                                onPressed: _handleGuestEntry,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Guest Entry Link
                  TextButton(
                    onPressed: _handleGuestEntry,
                    child: const Text(
                      'Explore as Guest →',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 11),
      ),
      icon: Icon(icon, size: 22, color: AppColors.textPrimary),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      onPressed: onPressed,
    );
  }
}
