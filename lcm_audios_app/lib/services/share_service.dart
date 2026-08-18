import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// LCM Audios Deep Link Share Service
///
/// Generates and shares deep links in the format:
///   https://lcmaudios.app/track/{trackId}
///
/// Non-app users receive a fallback web preview link.
/// Premium tracks include a paywall note — no audio is ever shared raw.
class ShareService {
  const ShareService._();
  static const ShareService instance = ShareService._();

  static const String _appBaseUrl = 'https://lcmaudios.app';
  static const String _webFallbackUrl = 'https://lcmaudios.app/listen';

  /// Generates the deep link URL for a given track ID.
  static String buildTrackDeepLink(String trackId) {
    return '$_appBaseUrl/track/$trackId';
  }

  /// Shares the currently playing track via the native OS share sheet.
  ///
  /// - For FREE tracks: shares the direct deep link + title + artist.
  /// - For PREMIUM tracks: shares the link with a "partner to unlock full" note.
  Future<void> shareTrack({
    required BuildContext context,
    required String trackId,
    required String title,
    required String artist,
    required String subgenre,
    required bool isPremium,
  }) async {
    final deepLink = buildTrackDeepLink(trackId);

    final String shareText;
    if (isPremium) {
      shareText = '''🎙️ *$title* — $artist

🔒 This is a Covenant Partner exclusive sermon on LCM Audios.
Partner with Life Care Ministry to unlock the full anointed message.

👇 Open in LCM Audios App:
$deepLink

📱 Download LCM Audios: $_webFallbackUrl''';
    } else {
      shareText = '''🎵 *$title* — $artist

"${_getSubgenreEmoji(subgenre)} $subgenre" — Now streaming on LCM Audios 🙌

👇 Listen now:
$deepLink

📱 Download LCM Audios App: $_webFallbackUrl''';
    }

    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        shareText,
        subject: 'Listen to "$title" on LCM Audios',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      debugPrint('[ShareService] Share failed: $e');
    }
  }

  /// Copies the deep link to the clipboard with a snackbar confirmation.
  Future<void> copyLinkToClipboard({
    required BuildContext context,
    required String trackId,
    required String title,
  }) async {
    final deepLink = buildTrackDeepLink(trackId);
    await Clipboard.setData(ClipboardData(text: deepLink));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: const Color(0xFF1E2338),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.link_rounded, color: Color(0xFFE63946), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Link for "$title" copied!',
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static String _getSubgenreEmoji(String subgenre) {
    final s = subgenre.toLowerCase();
    if (s.contains('worship') || s.contains('praise')) return '🙌';
    if (s.contains('prayer') || s.contains('warfare')) return '🔥';
    if (s.contains('prophet')) return '✨';
    if (s.contains('healing') || s.contains('deliver')) return '💊';
    if (s.contains('sermon') || s.contains('apostol')) return '📖';
    if (s.contains('devotion')) return '🌅';
    return '🎶';
  }
}
