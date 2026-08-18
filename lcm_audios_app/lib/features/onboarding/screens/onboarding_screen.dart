import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
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
  int _currentStep = 0; // 0 = Welcome & Brand Intro, 1 = Theme Selection, 2 = Spiritual Intents
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

  final Set<IntentCategory> _selectedIntents = {
    IntentCategory.morningDevotion,
    IntentCategory.deepWorship,
  };

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
    final isDark = AppColors.isDarkMode(context);

    final bgGradientColor = isDark
        ? AppColors.primaryGlow
        : AppColors.primary.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.2,
            colors: [
              bgGradientColor,
              AppColors.bg(context),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Progress indicator bar (3 Steps)
                Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: _currentStep >= 1
                              ? AppColors.primary
                              : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: _currentStep >= 2
                              ? AppColors.primary
                              : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Step 0: Welcome Intro, Step 1: Theme Selection, Step 2: Spiritual Intents
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _currentStep == 0
                        ? _buildWelcomeIntroStep(context, isDark)
                        : _currentStep == 1
                            ? _buildThemeSelectionStep(context, themeService, isDark)
                            : _buildIntentSelectionStep(context, isDark),
                  ),
                ),

                // Bottom Action Buttons
                Row(
                  children: [
                    if (_currentStep > 0) ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onPressed: () {
                          setState(() {
                            _currentStep--;
                          });
                        },
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
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
                                  fontSize: 15,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
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
  // Step 0: Sacred Sanctuary Editorial (Option A + Brand Colors)
  // ===========================================================================
  Widget _buildWelcomeIntroStep(BuildContext context, bool isDark) {
    final primaryColor = AppColors.primary;
    const goldAccent = Color(0xFFD4AF37);
    const goldGlow = Color(0xFFFFDF79);

    return SingleChildScrollView(
      key: const ValueKey('step_welcome_editorial'),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // Top Mini Brand Crest Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161926) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: goldAccent.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: goldAccent.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    isDark ? 'assets/images/logo2White.png' : 'assets/images/logoIcon.png',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LCM AUDIOS SANCTUARY',
                    style: TextStyle(
                      color: isDark ? goldGlow : const Color(0xFFB45309),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Hero Radiant Visual: Pulsing Dove of Glory with Acoustic Frequencies
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final scale = _pulseAnimation.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Soft Ambient Aura Rings (Crimson & Gold)
                    Container(
                      width: 170 * scale,
                      height: 170 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            goldAccent.withValues(alpha: isDark ? 0.22 : 0.12),
                            primaryColor.withValues(alpha: isDark ? 0.18 : 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Acoustic Waveform Frequency Horizontal Flare
                    Container(
                      width: 260,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            goldAccent.withValues(alpha: isDark ? 0.25 : 0.15),
                            primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
                            goldAccent.withValues(alpha: isDark ? 0.25 : 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(19, (index) {
                          final heights = [6, 12, 18, 28, 14, 36, 44, 26, 48, 38, 48, 26, 44, 36, 14, 28, 18, 12, 6];
                          return Container(
                            width: 2.2,
                            height: heights[index % heights.length] * (scale * 0.9),
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? goldAccent : primaryColor,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: goldAccent.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    // Core Illuminated Sacred Orb with Official LCM Brand Logo
                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF2A1420),
                                  const Color(0xFF160D1A),
                                  const Color(0xFF0F0B14),
                                ]
                              : [
                                  Colors.white,
                                  const Color(0xFFFFF9EE),
                                  const Color(0xFFFDF2F4),
                                ],
                        ),
                        border: Border.all(
                          color: goldAccent.withValues(alpha: 0.7),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: goldAccent.withValues(alpha: isDark ? 0.4 : 0.2),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          isDark ? 'assets/images/logo2White.png' : 'assets/images/logoIcon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Editorial Title & Soul Sanctuary Tagline
          Text(
            'LCM AUDIOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.2,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'A Sacred Sanctuary for the Soul',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? goldGlow : const Color(0xFFB45309),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Immerse in life-transforming sermons, prophetic worship altars, and synchronized scriptures curated for your spiritual ascension.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.subtext(context),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Interactive Horizontal Preview Carousel of Sanctuary Streams
          SizedBox(
            height: 94,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSermonStreamCard(
                  context,
                  title: 'HOPE IN CHAOS',
                  speaker: 'Pastor Martins',
                  category: 'Sunday Services',
                  accentColor: primaryColor,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _buildSermonStreamCard(
                  context,
                  title: 'GUIDING LIGHT',
                  speaker: 'Apostle Joshua',
                  category: 'Deep Worship',
                  accentColor: goldAccent,
                  isDark: isDark,
                  isHighlighted: true,
                ),
                const SizedBox(width: 12),
                _buildSermonStreamCard(
                  context,
                  title: 'DIVINE GLORY',
                  speaker: 'Nathaniel Bassey',
                  category: 'Morning Devotion',
                  accentColor: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSermonStreamCard(
    BuildContext context, {
    required String title,
    required String speaker,
    required String category,
    required Color accentColor,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161926) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted ? accentColor : AppColors.border(context),
          width: isHighlighted ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted ? accentColor.withValues(alpha: 0.22) : AppColors.shadow(context),
            blurRadius: isHighlighted ? 12 : 6,
            offset: const Offset(0, 3),
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
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.graphic_eq_rounded, size: 14, color: accentColor),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                speaker,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.muted(context),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 0: Choose Theme Mode (Light / Dark / System)
  // ===========================================================================
  Widget _buildThemeSelectionStep(BuildContext context, ThemeService themeService, bool isDark) {
    return Column(
      key: const ValueKey('step_theme'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Atmosphere',
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the visual theme that aligns with your sanctuary environment. You can change this anytime.',
          style: TextStyle(
            color: AppColors.subtext(context),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        Expanded(
          child: ListView(
            children: [
              // Dark Mode Card
              _buildThemeCard(
                context: context,
                title: 'Midnight Vigil',
                subtitle: 'Deep obsidian & warm crimson glow for evening prayer, contemplation & deep worship.',
                icon: Icons.nightlight_round,
                accentColor: const Color(0xFF8B5CF6),
                previewColor: const Color(0xFF0D0F17),
                previewTextColor: Colors.white,
                isSelected: themeService.themeMode == ThemeMode.dark,
                onTap: () => themeService.setThemeMode(ThemeMode.dark),
              ),
              const SizedBox(height: 14),

              // Light Mode Card
              _buildThemeCard(
                context: context,
                title: 'Daylight Devotion',
                subtitle: 'Clean alabaster & crisp editorial style for morning devotion, study & bright focus.',
                icon: Icons.wb_sunny_rounded,
                accentColor: const Color(0xFFF59E0B),
                previewColor: const Color(0xFFF6F8FC),
                previewTextColor: const Color(0xFF0F172A),
                isSelected: themeService.themeMode == ThemeMode.light,
                onTap: () => themeService.setThemeMode(ThemeMode.light),
              ),
              const SizedBox(height: 14),

              // System Auto Option
              InkWell(
                onTap: () => themeService.setThemeMode(ThemeMode.system),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeService.themeMode == ThemeMode.system
                          ? AppColors.primary
                          : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
                      width: themeService.themeMode == ThemeMode.system ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.brightness_auto_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Match Device System',
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Automatically transition based on your OS settings',
                              style: TextStyle(
                                color: AppColors.muted(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        themeService.themeMode == ThemeMode.system
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: themeService.themeMode == ThemeMode.system
                            ? AppColors.primary
                            : AppColors.muted(context),
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

  Widget _buildThemeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color previewColor,
    required Color previewTextColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDarkMode(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
            width: isSelected ? 2.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.shadow(context),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini Preview Thumbnail Box
            Container(
              width: 58,
              height: 72,
              decoration: BoxDecoration(
                color: previewColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.6) : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: accentColor, size: 24),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: previewTextColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? AppColors.primary : AppColors.muted(context),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.subtext(context),
                      fontSize: 12.5,
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
  // Step 1: Spiritual Intents
  // ===========================================================================
  Widget _buildIntentSelectionStep(BuildContext context, bool isDark) {
    return Column(
      key: const ValueKey('step_intents'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personalize Your Spiritual Journey',
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the spiritual intents that match your daily devotion routine.',
          style: TextStyle(
            color: AppColors.subtext(context),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight)
                        : AppColors.card(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? intent.accentColor
                          : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: intent.accentColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: AppColors.shadow(context),
                              blurRadius: 8,
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: intent.accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(intent.icon, color: intent.accentColor, size: 24),
                          ),
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? intent.accentColor : AppColors.muted(context),
                            size: 22,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            intent.title,
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            intent.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.muted(context),
                              fontSize: 11,
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
