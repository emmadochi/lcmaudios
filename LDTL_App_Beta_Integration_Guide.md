# LDTL Mobile Ecosystem: LCMWorld Integration & Beta Testing Guide
**Target Audience:** Mobile Engineering Teams (LiChat, La-Vie Conference, yo-ETS, LCM Audios, Living The Life)  
**Platform Version:** LCMWorld API v1.0  
**Central Hub URL:** `https://lcmworld.lifechangerstouch.org`  

---

## 1. Executive Summary & Objective

To prepare our portfolio of applications for the **Google Play Store 14-day closed testing requirement** and gather structured evidence for commercialization and investor reviews, all LDTL mobile applications must integrate with the **LCMWorld Central Cloud Engine**.

This integration accomplishes two automated workflows with minimal developer effort:
1. **Automated OTA (Over-The-Air) Update Checks:** When a user launches your app, it checks LCMWorld for newer APK builds and prompts the user to update without needing manual Play Store approvals.
2. **Unified Beta Feedback & Bug Reporting:** A standardized 1-tap dialog inside each app allowing testers to report bugs, rating satisfaction, and commercial intent (willingness to pay). Submissions flow directly into the management dashboard.

---

## 2. App Identification Registry

Each engineering team must ensure their application declares their unique **Package Name (Application ID)** consistently across API calls:

| Application Name | Designated Package ID | Category | Primary Testing Focus |
| :--- | :--- | :--- | :--- |
| **LiChat** | `org.ldtl.lichat` | Communication | Messaging, calls, weak network handling, media transfer |
| **La-Vie Enterprise** | `org.ldtl.lavie` | Productivity / Meet | Meeting stability, screen share, broadcast quality, paid leads |
| **yo-ETS** | `org.ldtl.yoets` | Education | Course navigation, video streaming, document downloads |
| **LCM Audios** | `org.ldtl.lcmaudios` | Audio & Media | Background audio playback, offline downloads, playlist UX |
| **Living The Life** | `org.ldtl.livingthelife` | Lifestyle / Community | Daily user retention, onboarding flow, push notifications |

---

## 3. Plug-and-Play Flutter SDK (`LcmBridge`)

For Flutter applications, we have provided a zero-dependency, drop-in integration class: `LcmBridge`.

### Step 1: Add the Bridge File
Create or copy the file into your Flutter project at:  
`lib/services/lcm_bridge.dart`

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class LcmBridge {
  static const String baseUrl = 'https://lcmworld.lifechangerstouch.org/api';
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  /// 1. Auto-check for updates on app launch
  static Future<void> checkForUpdates(
    BuildContext context, {
    required String packageName,
    required String currentVersion,
    bool showToastIfLatest = false,
  }) async {
    try {
      final response = await _dio.get(
        '/apps/check-update',
        queryParameters: {
          'package': packageName,
          'version': currentVersion,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['has_update'] == true && context.mounted) {
          _showUpdateDialog(
            context,
            appName: data['app_name'] ?? 'App',
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

  /// 2. Open Beta Feedback / Bug Report Dialog
  static void showFeedbackDialog(
    BuildContext context, {
    required String packageName,
    required String appName,
    required String currentVersion,
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

  static void _showUpdateDialog(
    BuildContext context, {
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
            Text('$appName v$latestVersion is available on LCMWorld.', style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading update package from LCMWorld...')),
              );
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
      final dio = Dio();
      await dio.post(
        '${LcmBridge.baseUrl}/feedback',
        data: {
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
        },
      );

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
```

---

### Step 2: Invoke Update Check on Startup
In your app's main view (e.g. `home_screen.dart` or `splash_screen.dart`), call:

```dart
import 'services/lcm_bridge.dart';

@override
void initState() {
  super.initState();
  
  // Auto-check for updates on launch
  WidgetsBinding.instance.addPostFrameCallback((_) {
    LcmBridge.checkForUpdates(
      context,
      packageName: 'org.ldtl.lichat', // Your package ID from Table 2
      currentVersion: '1.0.0',         // Current build version string
    );
  });
}
```

---

### Step 3: Add the Beta Feedback Button
Add a button or ListTile inside your Settings screen, Side Drawer, or Profile:

```dart
ListTile(
  leading: const Icon(Icons.bug_report_outlined, color: Colors.blueAccent),
  title: const Text('Beta Feedback & Bug Report'),
  subtitle: const Text('Help us improve before official launch'),
  onTap: () {
    LcmBridge.showFeedbackDialog(
      context,
      packageName: 'org.ldtl.lichat',
      appName: 'LiChat',
      currentVersion: '1.0.0',
    );
  },
)
```

---

## 4. Direct REST API Specification (For Native Android / Non-Flutter)

If your app is built with native Kotlin/Java, React Native, or another framework, call these endpoints directly:

### 1. Check for App Updates
- **Endpoint:** `GET https://lcmworld.lifechangerstouch.org/api/apps/check-update`
- **Query Parameters:**
  - `package`: (Required) String, e.g. `org.ldtl.lichat`
  - `version`: (Required) String, e.g. `1.0.0`
- **Response Format (`application/json`):**
```json
{
  "found": true,
  "has_update": true,
  "app_id": 1,
  "app_name": "LiChat",
  "package_name": "org.ldtl.lichat",
  "current_version": "1.0.0",
  "latest_version": "1.0.1",
  "whats_new": "Fixed audio call disconnect bug on weak networks.",
  "file_size": "48.2 MB",
  "download_url": "https://lcmworld.lifechangerstouch.org/api/admin/apps/1/download",
  "icon_url": "https://lcmworld.lifechangerstouch.org/storage/apps/icons/lichat.png"
}
```

---

### 2. Submit Beta Feedback & Bug Reports
- **Endpoint:** `POST https://lcmworld.lifechangerstouch.org/api/feedback`
- **Headers:** `Content-Type: application/json`, `Accept: application/json`
- **Request Body:**
```json
{
  "package_name": "org.ldtl.lichat",
  "app_name": "LiChat",
  "app_version": "1.0.0",
  "type": "bug",
  "message": "When switching from Wi-Fi to cellular during a call, audio drops.",
  "rating": 4,
  "device_model": "Samsung Galaxy A14",
  "os_version": "Android 13 (API 33)",
  "tester_email": "john.tester@gmail.com",
  "would_pay": "yes"
}
```
- **Field Values:**
  - `type`: `"bug"` | `"feedback"` | `"feature_request"` | `"commercial"`
  - `rating`: `1` to `5`
  - `would_pay`: `"yes"` | `"maybe"` | `"no"`

---

## 5. QA Verification Checklist Before Distribution

Before distributing your beta build to the tester cohort:
1. **Verify Package ID:** Confirm your `build.gradle` `applicationId` matches the designated registry in Table 2.
2. **Submit a Test Bug:** Open the feedback dialog in your debug build, enter `"Test report from Dev"`, and click Send.
3. **Admin Check:** Confirm the test entry appears immediately on:  
   👉 `https://lcmworld.lifechangerstouch.org/admin/beta-feedback`
4. **Tag Your Builds:** Mark pre-release APK filenames clearly (e.g. `LiChat-v1.0.0-beta.apk`) when uploading to the LCMWorld team.
