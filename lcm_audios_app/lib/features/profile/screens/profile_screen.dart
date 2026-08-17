import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/notification_service.dart';
import '../../auth/screens/auth_screen.dart';
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Profile Name', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Streaming Audio Quality', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isSelected = _audioQuality == opt;
            return ListTile(
              title: Text(opt, style: TextStyle(color: isSelected ? AppColors.primary : Colors.white, fontSize: 13.5)),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out of LCM Audios?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'Your offline encrypted downloads and sermon notes will remain safely stored on this device.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
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
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final notesCount = playerService.allTracks.fold(0, (sum, t) => sum + t.notes.length);
        final totalHours = ((playerService.listenCount * 45) / 60).toStringAsFixed(1);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Header ─────────────────────────────────────────────
                  const Text(
                    'My Profile & Settings',
                    style: TextStyle(
                      color: AppColors.textPrimary,
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: playerService.isCovenantPartner
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.6)
                            : AppColors.glassBorder,
                      ),
                      gradient: LinearGradient(
                        colors: playerService.isCovenantPartner
                            ? [const Color(0xFF231630), AppColors.surface]
                            : [AppColors.surfaceLight.withValues(alpha: 0.4), AppColors.surface],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: playerService.isCovenantPartner
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                              : Colors.black26,
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
                              child: const CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.surface,
                                child: Icon(Icons.person_rounded, size: 36, color: Colors.white),
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
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
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
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: playerService.isCovenantPartner
                                          ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                                          : AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: playerService.isCovenantPartner
                                            ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
                                            : AppColors.glassBorder,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          playerService.isCovenantPartner
                                              ? Icons.workspace_premium_rounded
                                              : Icons.volunteer_activism_rounded,
                                          color: playerService.isCovenantPartner
                                              ? const Color(0xFFFFDF79)
                                              : AppColors.primary,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          playerService.isCovenantPartner
                                              ? 'Covenant Partner (Gold)'
                                              : 'Grace Worshipper',
                                          style: TextStyle(
                                            color: playerService.isCovenantPartner
                                                ? const Color(0xFFFFDF79)
                                                : AppColors.textSecondary,
                                            fontSize: 11,
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
                        const Divider(color: AppColors.glassBorder, height: 1),
                        const SizedBox(height: 14),

                        // Spiritual Consistency Milestones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem('🔥 7 Days', 'Prayer Streak'),
                            _buildDivider(),
                            _buildMetricItem('🎧 $totalHours Hrs', 'Immersed'),
                            _buildDivider(),
                            _buildMetricItem('📝 $notesCount Notes', 'Insights Saved'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Section 1: Spiritual Habits & Alarms ───────────────────
                  _buildSectionHeader('🕊️ Spiritual Habits & Discipline'),
                  _buildCardGroup([
                    SwitchListTile(
                      value: _morningAlarmEnabled,
                      onChanged: (val) {
                        setState(() {
                          _morningAlarmEnabled = val;
                        });
                      },
                      activeColor: AppColors.primary,
                      title: const Text('Daily Morning Devotion Reminder', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Scheduled for ${_alarmTime.format(context)} every morning',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                      ),
                      secondary: const Icon(Icons.alarm_rounded, color: AppColors.primary),
                    ),
                    const Divider(color: AppColors.glassBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded, color: AppColors.primary),
                      title: const Text('Change Devotion Time', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      trailing: Text(
                        _alarmTime.format(context),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onTap: () => _pickAlarmTime(context),
                    ),
                    const Divider(color: AppColors.glassBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_active_rounded, color: Color(0xFFD4AF37)),
                      title: const Text('Auto-Test Push Notification', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Sends an instant status-bar alert with sound & vibration', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
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

                  // ── Section 2: Audio & Streaming Preferences ───────────────
                  _buildSectionHeader('🎛️ Audio & Streaming Preferences'),
                  _buildCardGroup([
                    ListTile(
                      leading: const Icon(Icons.high_quality_rounded, color: AppColors.primary),
                      title: const Text('Streaming Audio Quality', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text(_audioQuality, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
                      onTap: () => _showQualityDialog(context),
                    ),
                    const Divider(color: AppColors.glassBorder, height: 1),
                    SwitchListTile(
                      value: _wifiOnlyDownload,
                      onChanged: (val) {
                        setState(() {
                          _wifiOnlyDownload = val;
                        });
                      },
                      activeColor: AppColors.primary,
                      title: const Text('Download on Wi-Fi Only', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Prevent cellular data consumption when saving offline audio', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      secondary: const Icon(Icons.wifi_rounded, color: AppColors.primary),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Section 3: Covenant Partner & Kingdom Giving ───────────
                  _buildSectionHeader('👑 Kingdom Partnership'),
                  _buildCardGroup([
                    ListTile(
                      leading: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFDF79)),
                      title: const Text('Covenant Partner Vault', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        playerService.isCovenantPartner
                            ? 'Plan: Active (${playerService.partnerPlanType ?? 'Partner'})'
                            : 'Upgrade to unlock full audio vault & support missions',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
                      onTap: () => CovenantPartnerPaywallSheet.show(context),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Section 4: Community & Account ─────────────────────────
                  _buildSectionHeader('🤝 Community & Account'),
                  _buildCardGroup([
                    ListTile(
                      leading: const Icon(Icons.share_rounded, color: AppColors.primary),
                      title: const Text('Share LCM Audios with Friends', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Spread the gospel of grace with prayer partners', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('LCM Audios share link copied to clipboard! ✨'),
                            backgroundColor: AppColors.surfaceLight,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                    const Divider(color: AppColors.glassBorder, height: 1),
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
                          'assets/images/logo2White.png',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'LCM Audios • Version 1.0.0 (Faith in Motion)',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMetricItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.glassBorder,
    );
  }
}
