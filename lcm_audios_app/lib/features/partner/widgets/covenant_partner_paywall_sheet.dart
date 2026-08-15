import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/audio_player_service.dart';
import 'paystack_checkout_sheet.dart';

class CovenantPartnerPaywallSheet extends StatefulWidget {
  final String? sourceFeature;

  const CovenantPartnerPaywallSheet({
    super.key,
    this.sourceFeature,
  });

  static Future<void> show(BuildContext context, {String? sourceFeature}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CovenantPartnerPaywallSheet(sourceFeature: sourceFeature),
    );
  }

  @override
  State<CovenantPartnerPaywallSheet> createState() => _CovenantPartnerPaywallSheetState();
}

class _CovenantPartnerPaywallSheetState extends State<CovenantPartnerPaywallSheet> {
  int _selectedPlanIndex = 1; // 0 = Monthly, 1 = Annual (Best Value)

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final isPartner = playerService.isCovenantPartner;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF140D1E), // Deep royal spiritual obsidian
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35), // Royal Gold border
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Crown & Glow Header
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFD4AF37).withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFDF79), Color(0xFFD4AF37), Color(0xFF996515)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 34,
                          color: Color(0xFF140D1E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'COVENANT PARTNER VAULT',
                    style: TextStyle(
                      color: Color(0xFFFFDF79),
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    isPartner ? 'You are a Covenant Partner' : 'Unlock Full Anointed Catalogs',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    isPartner
                        ? 'Thank you for partnering with the Gospel of Jesus Christ. You have unlocked unlimited access across all devices.'
                        : widget.sourceFeature != null
                            ? 'Exclusive content: ${widget.sourceFeature}. Partner with the ministry to stream full unshortened teachings.'
                            : 'Support global kingdom broadcasting & gain unrestricted access to exclusive sermons, retreats & unlimited downloads.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Benefits List
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildBenefitRow(
                          Icons.lock_open_rounded,
                          'Exclusive Teachings & Retreats',
                          'Access full-length deliverance intensives & secret place messages',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitRow(
                          Icons.cloud_download_rounded,
                          'Unlimited Encrypted DRM Downloads',
                          'No 3-track limit — download entire sermon series for offline travel',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitRow(
                          Icons.high_quality_rounded,
                          'Lossless 320kbps Audio & Spatial Worship',
                          'Studio master quality streams for uninterrupted spiritual soaking',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitRow(
                          Icons.volunteer_activism_rounded,
                          'Gospel Ministry Partnership',
                          'Directly fund media outreach, church planting & global missions',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!isPartner) ...[
                    // Subscription / Seed Plan Selector
                    Row(
                      children: [
                        Expanded(
                          child: _buildPlanCard(
                            index: 0,
                            title: 'Monthly Seed',
                            price: '₦2,500',
                            period: '/ month',
                            badge: null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPlanCard(
                            index: 1,
                            title: 'Annual Covenant',
                            price: '₦24,000',
                            period: '/ year',
                            badge: 'SAVE 20%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Activate CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final planType = _selectedPlanIndex == 1 ? 'annual' : 'monthly';
                          final amount = _selectedPlanIndex == 1 ? 24000 : 2500;
                          final navigator = Navigator.of(context);

                          navigator.pop(); // Close paywall sheet
                          await PaystackCheckoutSheet.show(
                            context,
                            planType: planType,
                            amount: amount,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFDF79), Color(0xFFD4AF37), Color(0xFFB38020)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.lock_open_rounded, color: Color(0xFF140D1E), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'ACTIVATE PARTNER TIER',
                                  style: TextStyle(
                                    color: Color(0xFF140D1E),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Already Partner - Status Info & Toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFFFFDF79), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Covenant Partner Active',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'All locks removed & unlimited downloads active',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await playerService.activatePartnerTier(false);
                        if (mounted) navigator.pop();
                      },
                      child: Text(
                        'Deactivate Partner Tier (Test Free Tier Mode)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFFFFDF79),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String period,
    String? badge,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFD4AF37)
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 1.8 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFFFDF79) : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? const Color(0xFFFFDF79) : Colors.white24,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -8,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE63946), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
