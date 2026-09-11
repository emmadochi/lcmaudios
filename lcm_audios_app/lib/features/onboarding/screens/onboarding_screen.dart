import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/spiritual_intent.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/theme_service.dart';
import '../../auth/screens/auth_screen.dart';
import '../../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0 = Welcome, 1 = Atmosphere/Theme, 2 = Spiritual Intents
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Set<IntentCategory> _selectedIntents = {
    IntentCategory.morningDevotion,
    IntentCategory.deepWorship,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    final playerService = Provider.of<AudioPlayerService>(context, listen: false);
    playerService.setCategoryFilter('all');
    playerService.setIntentFilter(IntentCategory.all);
    await playerService.completeOnboarding();
    if (!mounted) return;

    if (playerService.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    // Brand Crimson Colors
    const crimsonColor = Color(0xFFE63946);
    const crimsonDark = Color(0xFFD90429);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.2,
            colors: [
              Color(0xFFFFF5F5), // ultra-soft crimson warmth at the top center
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Progress Bar & Skip Button
                Row(
                  children: [
                    // 3-Segment Capsule Progress Indicator
                    Expanded(
                      child: Row(
                        children: List.generate(3, (index) {
                          final isActive = index <= _currentStep;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 4,
                              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? const LinearGradient(
                                        colors: [crimsonColor, crimsonDark],
                                      )
                                    : null,
                                color: isActive ? null : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Skip action (Steps 0 & 1)
                    if (_currentStep < 2)
                      TextButton(
                        onPressed: _finishOnboarding,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Step Content with Smooth Fade Transitions
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _currentStep == 0
                        ? _buildWelcomeStep(context)
                        : _currentStep == 1
                            ? _buildAtmosphereStep(context, themeService)
                            : _buildIntentsStep(context),
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Action Buttons (Back + Crimson Continue CTA)
                Row(
                  children: [
                    if (_currentStep > 0) ...[
                      InkWell(
                        onTap: () {
                          setState(() {
                            _currentStep--;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF0F172A),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: crimsonColor.withValues(alpha: 0.35),
                            elevation: 5,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            if (_currentStep < 2) {
                              setState(() {
                                _currentStep++;
                              });
                            } else {
                              _finishOnboarding();
                            }
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE63946),
                                  Color(0xFFD90429),
                                  Color(0xFFBE123C),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentStep == 0
                                        ? 'GET STARTED'
                                        : _currentStep == 1
                                            ? 'CONTINUE'
                                            : 'ENTER SANCTUARY',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Step 0: Welcome Step (Pristine White, Crimson Brand Focus, High-End Editorial)
  // ===========================================================================
  Widget _buildWelcomeStep(BuildContext context) {
    const crimsonColor = Color(0xFFE63946);

    return SingleChildScrollView(
      key: const ValueKey('step_welcome_white_red'),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Top Mini Crimson Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: crimsonColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: crimsonColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome_rounded, size: 13, color: crimsonColor),
                SizedBox(width: 6),
                Text(
                  'SACRED AUDIO SANCTUARY',
                  style: TextStyle(
                    color: crimsonColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Central Illuminated Orb with Crimson Waveform
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = _pulseAnimation.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Soft Ambient Aura Ring
                  Container(
                    width: 170 * scale,
                    height: 170 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          crimsonColor.withValues(alpha: 0.14),
                          const Color(0xFFFB7185).withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Crimson Audio Soundwave Flare
                  Container(
                    width: 250,
                    height: 44,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(15, (index) {
                        final heights = [8, 16, 26, 38, 20, 42, 30, 44, 30, 42, 20, 38, 26, 16, 8];
                        return Container(
                          width: 2.5,
                          height: heights[index % heights.length] * scale,
                          decoration: BoxDecoration(
                            color: crimsonColor.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Core Emblem Disc
                  Container(
                    width: 108,
                    height: 108,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: crimsonColor.withValues(alpha: 0.7),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: crimsonColor.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logoIcon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.headphones_rounded,
                          color: crimsonColor,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Editorial Title & Headline
          const Text(
            'LCM AUDIOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.8,
            ),
          ),
          const SizedBox(height: 6),

          const Text(
            'Faith in Motion • Sacred Sound for the Soul',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: crimsonColor,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 14),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Immerse in life-transforming sermons, prophetic worship, and midnight prayer altars curated for your spiritual elevation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // 3 Minimalist Luxury Feature Chips on Clean White
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureHighlightPill(
                icon: Icons.offline_bolt_rounded,
                label: 'Encrypted Offline Vault',
              ),
              _buildFeatureHighlightPill(
                icon: Icons.high_quality_rounded,
                label: 'Studio Master Audio',
              ),
              _buildFeatureHighlightPill(
                icon: Icons.menu_book_rounded,
                label: 'Sermon Timestamp Notes',
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlightPill({
    required IconData icon,
    required String label,
  }) {
    const crimsonColor = Color(0xFFE63946);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: crimsonColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 1: Choose Your Atmosphere (Balanced Visual Theme Cards on White)
  // ===========================================================================
  Widget _buildAtmosphereStep(BuildContext context, ThemeService themeService) {
    const crimsonColor = Color(0xFFE63946);

    return Column(
      key: const ValueKey('step_theme_white'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Atmosphere',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Personalize the lighting environment for your sanctuary experience.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 20),

        // Visual Side-By-Side / Stacked Atmosphere Cards
        Expanded(
          child: Column(
            children: [
              // Midnight Vigil Theme Card (Dark Mode Preview)
              Expanded(
                child: _buildVisualThemeCard(
                  context: context,
                  title: 'Midnight Vigil',
                  subtitle: 'Deep obsidian & warm crimson glow for evening prayer, contemplation & worship.',
                  icon: Icons.nightlight_round,
                  accentColor: const Color(0xFFFFDF79),
                  bgColors: const [Color(0xFF0F172A), Color(0xFF1E293B)],
                  textColor: Colors.white,
                  isSelected: themeService.themeMode == ThemeMode.dark,
                  onTap: () => themeService.setThemeMode(ThemeMode.dark),
                ),
              ),
              const SizedBox(height: 14),

              // Daylight Devotion Theme Card (Light Mode Preview)
              Expanded(
                child: _buildVisualThemeCard(
                  context: context,
                  title: 'Daylight Devotion',
                  subtitle: 'Crisp alabaster & bright radiant tones for morning study & devotional focus.',
                  icon: Icons.wb_sunny_rounded,
                  accentColor: crimsonColor,
                  bgColors: const [Color(0xFFFFF5F5), Colors.white],
                  textColor: const Color(0xFF0F172A),
                  isSelected: themeService.themeMode == ThemeMode.light,
                  onTap: () => themeService.setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(height: 14),

              // Match Device Auto-Toggle
              InkWell(
                onTap: () => themeService.setThemeMode(ThemeMode.system),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeService.themeMode == ThemeMode.system
                          ? crimsonColor
                          : const Color(0xFFE2E8F0),
                      width: themeService.themeMode == ThemeMode.system ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: crimsonColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.brightness_auto_rounded, color: crimsonColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Match Device System',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Automatically follow your device system settings',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        themeService.themeMode == ThemeMode.system
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: themeService.themeMode == ThemeMode.system
                            ? crimsonColor
                            : const Color(0xFFCBD5E1),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualThemeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Color> bgColors,
    required Color textColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const crimsonColor = Color(0xFFE63946);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? crimsonColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: crimsonColor.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? crimsonColor : const Color(0xFFCBD5E1),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Step 2: Personalize Spiritual Intents (Clean White Cards, Crimson Active State)
  // ===========================================================================
  Widget _buildIntentsStep(BuildContext context) {
    const crimsonColor = Color(0xFFE63946);

    return Column(
      key: const ValueKey('step_intents_white'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personalize Your Spiritual Journey',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select your daily prayer & worship streams for a customized home altar.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 18),

        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.18,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: SpiritualIntent.categories.length - 1, // Exclude 'All'
            itemBuilder: (ctx, i) {
              final intent = SpiritualIntent.categories[i + 1];
              final isSelected = _selectedIntents.contains(intent.category);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIntents.remove(intent.category);
                    } else {
                      _selectedIntents.add(intent.category);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? crimsonColor : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: crimsonColor.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? crimsonColor.withValues(alpha: 0.15)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              intent.icon,
                              color: isSelected ? crimsonColor : const Color(0xFF475569),
                              size: 18,
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? crimsonColor : const Color(0xFFCBD5E1),
                            size: 18,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            intent.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? crimsonColor : const Color(0xFF0F172A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            intent.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

