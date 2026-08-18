import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/theme_service.dart';
import '../../auth/screens/auth_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../partner/widgets/covenant_partner_paywall_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _morningAlarmEnabled = true;
  TimeOfDay _alarmTime = const TimeOfDay(hour: 6, minute: 0);
  bool _wifiOnlyDownload = true;
  String _audioQuality = 'High Fidelity (320 kbps)';

  @override
  void initState() {
    super.initState();
    final notif = NotificationService();
    _morningAlarmEnabled = notif.isDevotionReminderEnabled;
    _alarmTime = notif.devotionTime;
  }

  void _showEditNameDialog(BuildContext context, AudioPlayerService playerService) {
    final controller = TextEditingController(text: playerService.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Profile Name', style: TextStyle(color: AppColors.text(context), fontSize: 16)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppColors.text(context)),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: AppColors.muted(context)),
            filled: true,
            fillColor: AppColors.cardAlt(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.subtext(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                playerService.setUserName(newName);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile name updated!'), backgroundColor: AppColors.primary),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQualityDialog(BuildContext context) {
    final options = ['Auto (Adaptive Bitrate)', 'Standard (160 kbps)', 'High Fidelity (320 kbps)', 'Lossless Spatial Audio'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Streaming Audio Quality', style: TextStyle(color: AppColors.text(context), fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isSelected = _audioQuality == opt;
            return ListTile(
              title: Text(opt, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.text(context), fontSize: 13.5)),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20) : null,
              onTap: () {
                setState(() {
                  _audioQuality = opt;
                });
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _pickAlarmTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
    );
    if (picked != null) {
      setState(() {
        _alarmTime = picked;
        _morningAlarmEnabled = true;
      });
      if (context.mounted) {
        await NotificationService().setDevotionSchedule(
          enabled: true,
          time: picked,
          context: context,
        );
      }
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out of LCM Audios?', style: TextStyle(color: AppColors.text(context), fontSize: 16)),
        content: Text(
          'Your offline encrypted downloads and sermon notes will remain safely stored on this device.',
          style: TextStyle(color: AppColors.subtext(context), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final playerService = Provider.of<AudioPlayerService>(context, listen: false);
              await playerService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final notesCount = playerService.allTracks.fold(0, (sum, t) => sum + t.notes.length);
        final totalHours = ((playerService.listenCount * 45) / 60).toStringAsFixed(1);

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Header ─────────────────────────────────────────────
                  Text(
                    'My Profile & Settings',
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── User Identity & Tier Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: playerService.isCovenantPartner
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.6)
                            : AppColors.border(context),
                      ),
                      gradient: LinearGradient(
                        colors: playerService.isCovenantPartner
                            ? [
                                isDark ? const Color(0xFF231630) : const Color(0xFFFFF9E6),
                                AppColors.card(context),
                              ]
                            : [
                                isDark
                                    ? AppColors.surfaceLight.withValues(alpha: 0.4)
                                    : const Color(0xFFF1F5F9),
                                AppColors.card(context),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: playerService.isCovenantPartner
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                              : AppColors.shadow(context),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: playerService.isCovenantPartner
                                      ? [const Color(0xFFFFDF79), const Color(0xFFD4AF37)]
                                      : [AppColors.primary, const Color(0xFF991B1B)],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.card(context),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 36,
                                  color: AppColors.text(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          playerService.userName,
                                          style: TextStyle(
                                            color: AppColors.text(context),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showEditNameDialog(context, playerService),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: playerService.isCovenantPartner
                                          ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                                          : AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: playerService.isCovenantPartner
                                            ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                                            : AppColors.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          playerService.isCovenantPartner ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
                                          size: 11,
                                          color: playerService.isCovenantPartner ? const Color(0xFFD4AF37) : AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          playerService.isCovenantPartner
                                              ? (playerService.partnerPlanType?.toUpperCase() ?? 'COVENANT PARTNER')
                                              : 'FREE LISTENER',
                                          style: TextStyle(
                                            color: playerService.isCovenantPartner ? const Color(0xFFD4AF37) : AppColors.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: AppColors.border(context), height: 1),
                        const SizedBox(height: 14),

                        // Spiritual Consistency Milestones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem(context, '🔥 7 Days', 'Prayer Streak'),
                            _buildDivider(context),
                            _buildMetricItem(context, '🎧 $totalHours Hrs', 'Immersed'),
                            _buildDivider(context),
                            _buildMetricItem(context, '📝 $notesCount Notes', 'Insights Saved'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Section 1: App Atmosphere & Visual Theme ──────────────
                  _buildSectionHeader(context, '🎨 App Atmosphere & Visual Theme'),
                  Consumer<ThemeService>(
                    builder: (context, themeService, _) {
                      return _buildCardGroup(context, [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                    color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Visual Atmosphere',
                                    style: TextStyle(
                                      color: AppColors.text(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Switch between Daylight Devotion for bright scripture study or Midnight Vigil for night prayer.',
                                style: TextStyle(
                                  color: AppColors.muted(context),
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              // 3-Way Segmented Control Pills
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.cardAlt(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                child: Row(
                                  children: [
                                    _buildThemeOption(
                                      context: context,
                                      title: 'Light',
                                      icon: Icons.wb_sunny_rounded,
                                      isSelected: themeService.themeMode == ThemeMode.light,
                                      onTap: () => themeService.setThemeMode(ThemeMode.light),
                                    ),
                                    _buildThemeOption(
                                      context: context,
                                      title: 'Dark',
                                      icon: Icons.nightlight_round,
                                      isSelected: themeService.themeMode == ThemeMode.dark,
                                      onTap: () => themeService.setThemeMode(ThemeMode.dark),
                                    ),
                                    _buildThemeOption(
                                      context: context,
                                      title: 'System',
                                      icon: Icons.brightness_auto_rounded,
                                      isSelected: themeService.themeMode == ThemeMode.system,
                                      onTap: () => themeService.setThemeMode(ThemeMode.system),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]);
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Section 2: Spiritual Habits & Alarms ───────────────────
                  _buildSectionHeader(context, '🕊️ Spiritual Habits & Discipline'),
                  _buildCardGroup(context, [
                    SwitchListTile(
                      value: _morningAlarmEnabled,
                      onChanged: (val) {
                        setState(() {
                          _morningAlarmEnabled = val;
                        });
                      },
                      activeColor: AppColors.primary,
                      title: Text('Daily Morning Devotion Reminder', style: TextStyle(color: AppColors.text(context), fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Scheduled for ${_alarmTime.format(context)} every morning',
                        style: TextStyle(color: AppColors.muted(context), fontSize: 11.5),
                      ),
                      secondary: const Icon(Icons.alarm_rounded, color: AppColors.primary),
                    ),
                    Divider(color: AppColors.border(context), height: 1),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded, color: AppColors.primary),
                      title: Text('Change Devotion Time', style: TextStyle(color: AppColors.text(context), fontSize: 13.5, fontWeight: FontWeight.w600)),
                      trailing: Text(
                        _alarmTime.format(context),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onTap: () => _pickAlarmTime(context),
                    ),
                    Divider(color: AppColors.border(context), height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_active_rounded, color: Color(0xFFD4AF37)),
                      title: Text('Auto-Test Push Notification', style: TextStyle(color: AppColors.text(context), fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text('Sends an instant status-bar alert with sound & vibration', style: TextStyle(color: AppColors.muted(context), fontSize: 11.5)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                        ),
                        child: const Text('TEST NOW', style: TextStyle(color: Color(0xFFFFDF79), fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ),
                      onTap: () {
                        NotificationService().triggerAutoTestNotification(context);
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Section 3: Audio & Streaming Preferences ───────────────
                  _buildSectionHeader(context, '🎛️ Audio & Streaming Preferences'),
                  _buildCardGroup(context, [
                    ListTile(
                      leading: const Icon(Icons.high_quality_rounded, color: AppColors.primary),
                      title: Text('Streaming Audio Quality', style: TextStyle(color: AppColors.text(context), fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text(_audioQuality, style: TextStyle(color: AppColors.muted(context), fontSize: 11.5)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted(context), size: 13),
                      onTap: () => _showQualityDialog(context),
                    ),
                    Divider(color: AppColors.border(context), height: 1),
                    SwitchListTile(
                      value: _wifiOnlyDownload,
                      onChanged: (val) {
                        setState(() {
                          _wifiOnlyDownload = val;
                        });
                      },
                      activeColor: AppColors.primary,
                      title: Text('Download on Wi-Fi Only', style: TextStyle(color: AppColors.text(context), fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text('Prevent cellular data consumption when saving offline audio', style: TextStyle(color: AppColors.muted(context), fontSize: 11.5)),
                      secondary: const Icon(Icons.wifi_rounded, color: AppColors.primary),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Section 4: Covenant Partner & Kingdom Giving ───────────
                  _buildSectionHeader(context, '👑 Kingdom Partnership'),
                  _buildCardGroup(context, [
                    ListTile(
                      leading: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFDF79)),
                      title: Text('Covenant Partner Vault', style: TextStyle(color: AppColors.text(context), fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        playerService.isCovenantPartner
                            ? 'Plan: Active (${playerService.partnerPlanType ?? 'Partner'})'
                            : 'Upgrade to unlock full audio vault & support missions',
                        style: TextStyle(color: AppColors.muted(context), fontSize: 11.5),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted(context), size: 13),
                      onTap: () => CovenantPartnerPaywallSheet.show(context),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Section 5: Community & Account ─────────────────────────
                  _buildSectionHeader(context, '🤝 Community & Account'),
                  _buildCardGroup(context, [
                    ListTile(
                      leading: const Icon(Icons.share_rounded, color: AppColors.primary),
                      title: Text('Share LCM Audios with Friends', style: TextStyle(color: AppColors.text(context), fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text('Spread the gospel of grace with prayer partners', style: TextStyle(color: AppColors.muted(context), fontSize: 11.5)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted(context), size: 13),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('LCM Audios share link copied to clipboard! ✨'),
                            backgroundColor: AppColors.card(context),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                    Divider(color: AppColors.border(context), height: 1),
                    ListTile(
                      leading: const Icon(Icons.explore_rounded, color: AppColors.primary),
                      title: Text('Spiritual Onboarding & Atmosphere Setup', style: TextStyle(color: AppColors.text(context), fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text('Revisit theme atmosphere & spiritual intent selection', style: TextStyle(color: AppColors.muted(context), fontSize: 11.5)),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.muted(context), size: 13),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                        );
                      },
                    ),
                    Divider(color: AppColors.border(context), height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 13.5, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent, size: 13),
                      onTap: () => _showSignOutDialog(context),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // ── Brand Footer ───────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          isDark ? 'assets/images/logo2White.png' : 'assets/images/logoIcon.png',
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'LCM Audios • Version 1.0.0 (Faith in Motion)',
                          style: TextStyle(color: AppColors.muted(context), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDarkMode(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary.withValues(alpha: 0.25) : AppColors.primary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: isDark ? AppColors.primary : Colors.transparent,
                    width: 1.2,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isDark ? AppColors.primary : Colors.white)
                    : AppColors.subtext(context),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? AppColors.textPrimary : Colors.white)
                      : AppColors.subtext(context),
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.subtext(context),
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCardGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.muted(context),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.border(context),
    );
  }
}
