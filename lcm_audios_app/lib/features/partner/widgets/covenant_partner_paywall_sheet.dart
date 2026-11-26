import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/audio_player_service.dart';
import '../../../services/iap_service.dart';
import '../../legal/screens/legal_screen.dart';

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
  final IapService _iapService = IapService();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playerService = Provider.of<AudioPlayerService>(context, listen: false);
      _iapService.onPurchaseResult = (success, message) {
        if (!mounted) return;
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        if (success) {
          Navigator.of(context).pop();
        }
      };
      await _iapService.init(playerService);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }

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
                    // Subscription Plan Selector (Apple StoreKit / Google Play Billing)
                    Row(
                      children: [
                        Expanded(
                          child: _buildPlanCard(
                            index: 0,
                            title: 'Monthly Seed',
                            price: _iapService.getProduct(IapService.monthlyProductId)?.price ?? '\$2.99',
                            period: '/ month',
                            badge: null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPlanCard(
                            index: 1,
                            title: 'Annual Covenant',
                            price: _iapService.getProduct(IapService.annualProductId)?.price ?? '\$24.99',
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
                        onPressed: _isBusy
                            ? null
                            : () async {
                                final productId = _selectedPlanIndex == 1
                                    ? IapService.annualProductId
                                    : IapService.monthlyProductId;
                                setState(() => _isBusy = true);
                                final started = await _iapService.buyPlan(productId);
                                if (!started && mounted) {
                                  setState(() => _isBusy = false);
                                }
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
                            child: _isBusy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF140D1E),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock_open_rounded, color: Color(0xFF140D1E), size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'SUBSCRIBE & UNLOCK',
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
                    const SizedBox(height: 12),

                    // Restore Purchases (Required by Apple Guideline 3.1.1)
                    TextButton(
                      onPressed: _isBusy
                          ? null
                          : () async {
                              setState(() => _isBusy = true);
                              await _iapService.restorePurchases();
                              if (mounted) setState(() => _isBusy = false);
                            },
                      child: const Text(
                        'Restore Purchases',
                        style: TextStyle(
                          color: Color(0xFFFFDF79),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Auto-renewal disclosure & Legal Links (Required by Apple)
                    Text(
                      'Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period in your App Store or Google Play account settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LegalScreen(type: LegalDocumentType.privacyPolicy),
                            ),
                          ),
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5),
                          ),
                        ),
                        Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LegalScreen(type: LegalDocumentType.termsOfService),
                            ),
                          ),
                          child: Text(
                            'Terms of Use',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Already Partner - Status Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFFFFDF79), size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
