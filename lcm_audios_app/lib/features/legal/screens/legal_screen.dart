import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

enum LegalDocumentType { privacyPolicy, termsOfService }

class LegalScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalScreen({super.key, required this.type});

  static const String privacyUrl = 'https://lifechangerstouch.org/privacy-policy';
  static const String termsUrl = 'https://lifechangerstouch.org/terms';

  Future<void> _openOnline(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == LegalDocumentType.privacyPolicy;
    final title = isPrivacy ? 'Privacy Policy' : 'Terms of Service';
    final url = isPrivacy ? privacyUrl : termsUrl;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(color: AppColors.text(context), fontSize: 17, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: AppColors.text(context)),
        actions: [
          IconButton(
            tooltip: 'Open on lifechangerstouch.org',
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            onPressed: () => _openOnline(context, url),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Life Changers Ministry (LCM Audios)',
                          style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _openOnline(context, url),
                          child: Text(
                            url,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isPrivacy) ..._buildPrivacySections(context) else ..._buildTermsSections(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPrivacySections(BuildContext context) {
    return [
      _section(
        context,
        '1. Information We Collect',
        'When you create an account or sign in with Google or Apple, we collect your name, email address, and a unique account identifier. We also store your spiritual intent preferences, sermon notes, listening statistics, and subscription status.',
      ),
      _section(
        context,
        '2. How We Use Your Information',
        'Your information is used strictly to authenticate your account, sync your sermon notes and listening progress across sessions, deliver optional devotion reminders or broadcast notifications you enable, and verify Covenant Partner in-app purchases.',
      ),
      _section(
        context,
        '3. Offline Audio & Local Storage',
        'Downloaded sermons are encrypted and stored locally on your device for offline playback. We do not sell, rent, or trade your personal data with third parties or use it for third-party advertising.',
      ),
      _section(
        context,
        '4. Account & Data Deletion',
        'You may permanently delete your account and associated personal data at any time inside the app under Profile → Delete Account, or by contacting support via lifechangerstouch.org.',
      ),
      _section(
        context,
        '5. Contact',
        'For privacy inquiries, please visit https://lifechangerstouch.org or reach out through the feedback link in Profile.',
      ),
    ];
  }

  List<Widget> _buildTermsSections(BuildContext context) {
    return [
      _section(
        context,
        '1. Acceptance of Terms',
        'By accessing or using LCM Audios, you agree to be bound by these Terms of Service and our Privacy Policy.',
      ),
      _section(
        context,
        '2. Audio Content & Licensing',
        'All sermons, teachings, worship tracks, and written notes provided in LCM Audios are the intellectual property of Life Changers Ministry and respective ministers. Offline downloads are licensed for personal, non-commercial spiritual listening only.',
      ),
      _section(
        context,
        '3. Covenant Partner Subscriptions',
        'Covenant Partner subscriptions are processed securely through the Apple App Store or Google Play Store. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current billing period in your App Store or Google Play account settings.',
      ),
      _section(
        context,
        '4. Account Termination',
        'You may delete your account at any time from the Profile screen. We reserve the right to suspend accounts that attempt to redistribute DRM-protected audio or abuse platform services.',
      ),
    ];
  }

  Widget _section(BuildContext context, String heading, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(color: AppColors.text(context), fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: AppColors.subtext(context), fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}
