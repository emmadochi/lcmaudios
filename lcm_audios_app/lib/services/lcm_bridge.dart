import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// LCMBridge
/// Plug-and-play module for any LDTL app (LiChat, La-Vie, yo-ETS, LCM Audios, Living The Life)
/// to communicate with the central LCMWorld App Store backend.
class LcmBridge {
  static const String baseUrl = 'https://lcmworld.lifechangerstouch.org/api';
  static const String designatedPackageName = 'com.lcmaudios.lcm_audios_app';
  static const String fallbackPackageName = 'org.ldtl.lcmaudios';
  static const String appName = 'LCM Audios';
  static const String currentAppVersion = '1.0.1';

  /// 1. Auto-check for updates on app startup
  static Future<void> checkForUpdates(
    BuildContext context, {
    String packageName = designatedPackageName,
    String currentVersion = currentAppVersion,
    bool showToastIfLatest = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/apps/check-update').replace(
        queryParameters: {
          'package': packageName,
          'version': currentVersion,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['has_update'] == true && context.mounted) {
          _showUpdateDialog(
            context,
            packageName: packageName,
            appName: data['app_name'] ?? appName,
            latestVersion: data['latest_version'] ?? '',
            whatsNew: data['whats_new'] ?? 'General improvements and bug fixes.',
            downloadUrl: data['download_url'] ?? '',
          );
        } else if (showToastIfLatest && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are on the latest version!')),
          );
        }
      }
    } catch (e) {
      debugPrint('[LCMBridge] Update check error: $e');
    }
  }

  /// Launch Lifechangers Apps (LCMWorld) in its own separate task/window
  /// directly to the specific app details screen.
  static Future<void> openAppInStore(String packageName) async {
    final Uri customUri = Uri.parse('lcmworld://app?package=$packageName');
    final Uri marketUri = Uri.parse('market://details?id=$packageName');
    final Uri webUri = Uri.parse('https://lcmworld.lifechangerstouch.org/apps/details?package=$packageName');

    try {
      if (await canLaunchUrl(customUri)) {
        await launchUrl(customUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[LCMBridge] openAppInStore error: $e');
    }
  }

  /// 2. Open Beta Feedback / Bug Report Dialog
  static void showFeedbackDialog(
    BuildContext context, {
    String packageName = designatedPackageName,
    String appName = appName,
    String currentVersion = currentAppVersion,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2230),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FeedbackSheet(
        packageName: packageName,
        appName: appName,
        currentVersion: currentVersion,
      ),
    );
  }

  /// Submit feedback programmatically without opening the modal
  static Future<bool> submitFeedback({
    required String message,
    String type = 'general',
    int? rating,
    String wouldPay = 'maybe',
    String packageName = designatedPackageName,
    String? name,
    String? email,
    String currentVersion = currentAppVersion,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/feedback');
      final payload = {
        'package_name': packageName,
        'app_name': appName,
        'app_version': currentVersion,
        'type': type,
        'message': message,
        if (rating != null) 'rating': rating,
        'device_model': deviceInfo?['os_version'] ?? Platform.operatingSystemVersion,
        'os_version': deviceInfo?['platform'] ?? Platform.operatingSystem,
        if (email != null && email.isNotEmpty) 'tester_email': email,
        if (name != null && name.isNotEmpty) 'tester_name': name,
        'would_pay': wouldPay,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[LCMBridge] Feedback submit error: $e');
      return false;
    }
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String packageName,
    required String appName,
    required String latestVersion,
    required String whatsNew,
    required String downloadUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Update Available', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$appName v$latestVersion is available on Lifechangers Apps.', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            const Text("What's New:", style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
              child: Text(whatsNew, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              Navigator.pop(ctx);
              openAppInStore(packageName);
            },
            child: const Text('Update Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  final String packageName;
  final String appName;
  final String currentVersion;

  const _FeedbackSheet({
    required this.packageName,
    required this.appName,
    required this.currentVersion,
  });

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  String _type = 'bug';
  int _rating = 5;
  String _wouldPay = 'yes';
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback or bug description.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('${LcmBridge.baseUrl}/feedback');
      final payload = {
        'package_name': widget.packageName,
        'app_name': widget.appName,
        'app_version': widget.currentVersion,
        'type': _type,
        'message': msg,
        'rating': _rating,
        'device_model': Platform.operatingSystemVersion,
        'os_version': Platform.operatingSystem,
        'tester_email': _emailController.text.trim(),
        'would_pay': _wouldPay,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Thank you! Your feedback has been sent to the LDTL engineering team.'),
            ),
          );
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Submission error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Beta Feedback: ${widget.appName}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Feedback Category', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                _chip('bug', 'Bug Report', Icons.bug_report_outlined),
                _chip('feedback', 'UX / Usability', Icons.thumb_up_alt_outlined),
                _chip('feature_request', 'Feature Request', Icons.lightbulb_outline),
                _chip('commercial', 'Pricing / Plans', Icons.monetization_on_outlined),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Your Rating', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 30,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What happened? Or what can we improve?',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Would you or your team pay for premium features?', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                _radio('yes', 'Yes'),
                const SizedBox(width: 12),
                _radio('maybe', 'Maybe'),
                const SizedBox(width: 12),
                _radio('no', 'No'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tester Email (Optional, for follow-up)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send to Engineering Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String value, String label, IconData icon) {
    final isSelected = _type == value;
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white60),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 11)),
        ],
      ),
      selectedColor: Colors.blueAccent,
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      onSelected: (_) => setState(() => _type = value),
    );
  }

  Widget _radio(String value, String label) {
    final isSelected = _wouldPay == value;
    return InkWell(
      onTap: () => setState(() => _wouldPay = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: isSelected ? Colors.blueAccent : Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
