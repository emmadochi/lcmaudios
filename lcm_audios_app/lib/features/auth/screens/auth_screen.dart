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
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
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
      if (errorStr.contains('10') || errorStr.contains('DEVELOPER_ERROR')) {
        _showError('Google OAuth requires SHA-1 registration. Please sign in with Email or continue as Guest.');
      } else if (errorStr.contains('network_error') || errorStr.contains('7')) {
        _showError('Network error connecting to Google Play Services.');
      } else {
        _showError('Google Sign-In was not completed. Please try Email or Guest.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Password reset instructions will be sent to your email.'),
                                            backgroundColor: AppColors.surfaceLight,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(color: AppColors.primary, fontSize: 12),
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
