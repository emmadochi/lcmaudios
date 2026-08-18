import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_player_service.dart';
import '../../partner/widgets/covenant_partner_paywall_sheet.dart';
import '../../partner/widgets/paystack_checkout_sheet.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlanIndex = 1; // 0 = Monthly, 1 = Annual

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, playerService, child) {
        final isPartner = playerService.isCovenantPartner;

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFDF79), size: 20),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Covenant Partner',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: isPartner
                          ? [const Color(0xFF2A1C3D), const Color(0xFF191024)]
                          : [const Color(0xFFE63946), const Color(0xFF6B0F1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: isPartner ? 0.6 : 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isPartner
                            ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                            : AppColors.primaryGlow.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFDF79), Color(0xFFD4AF37)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Icon(
                          isPartner ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                          size: 44,
                          color: const Color(0xFF140D1E),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPartner ? 'Covenant Partner Active' : 'Unlock Faith Unlimited',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPartner
                            ? 'Thank you for your kingdom partnership! You have full unrestricted access to all deliverance teachings, master quality audio & unlimited downloads.'
                            : 'Offline DRM Downloads • Lossless 320kbps Audio • Exclusive Deliverance & Retreat Teachings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPartner ? Colors.white12 : Colors.white,
                            foregroundColor: isPartner ? Colors.white : AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: isPartner ? 0 : 4,
                          ),
                          onPressed: () {
                            if (isPartner) {
                              CovenantPartnerPaywallSheet.show(context);
                            } else {
                              final planType = _selectedPlanIndex == 1 ? 'annual' : 'monthly';
                              final amount = _selectedPlanIndex == 1 ? 24000 : 2500;
                              PaystackCheckoutSheet.show(
                                context,
                                planType: planType,
                                amount: amount,
                              );
                            }
                          },
                          child: Text(
                            isPartner ? 'View Partnership Status' : 'Upgrade Now via Paystack',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!isPartner) ...[
                  // Offering Plan Selector
                  Text(
                    'SELECT KINGDOM SEED PLAN',
                    style: TextStyle(
                      color: AppColors.muted(context),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlanSelectorCard(
                          context: context,
                          index: 0,
                          title: 'Monthly Seed',
                          price: '₦2,500',
                          period: '/ month',
                          badge: null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPlanSelectorCard(
                          context: context,
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
                ] else ...[
                  // Active Subscription Info Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow(context),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, color: Color(0xFFFFDF79), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Subscription Details',
                              style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _infoRow(context, 'Plan Tier', playerService.partnerPlanType == 'annual' ? 'Annual Covenant (₦24,000/yr)' : 'Monthly Seed (₦2,500/mo)'),
                        const SizedBox(height: 8),
                        _infoRow(context, 'Payment Reference', playerService.partnerPaymentRef ?? 'LCM-PARTNER-ACTIVE'),
                        if (playerService.partnerReceiptNo != null) ...[
                          const SizedBox(height: 8),
                          _infoRow(context, 'Receipt Number', playerService.partnerReceiptNo!),
                        ],
                        const SizedBox(height: 8),
                        _infoRow(context, 'Gateway', 'Paystack Verified (Active)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Partnership Privileges Breakdown
                Text(
                  'PARTNERSHIP PRIVILEGES',
                  style: TextStyle(
                    color: AppColors.muted(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),

                _buildPrivilegeCard(
                  context: context,
                  icon: Icons.lock_open_rounded,
                  title: 'Unrestricted Exclusive Catalog',
                  subtitle: 'Stream full unshortened deliverance teachings & secret place messages.',
                  badge: 'EXCLUSIVE',
                ),
                const SizedBox(height: 10),
                _buildPrivilegeCard(
                  context: context,
                  icon: Icons.cloud_download_rounded,
                  title: 'Unlimited AES-256 DRM Downloads',
                  subtitle: 'Store whole sermon albums on your device for offline flights and journeys.',
                  badge: 'UNLIMITED',
                ),
                const SizedBox(height: 10),
                _buildPrivilegeCard(
                  context: context,
                  icon: Icons.graphic_eq_rounded,
                  title: '320kbps Lossless Spatial Worship',
                  subtitle: 'Hear every frequency of soaking worship in crystal-clear master quality.',
                  badge: 'LOSSLESS',
                ),
                const SizedBox(height: 10),
                _buildPrivilegeCard(
                  context: context,
                  icon: Icons.volunteer_activism_rounded,
                  title: 'Global Gospel Media Sponsorship',
                  subtitle: 'Directly fund world evangelism, missions, and spiritual broadcasting.',
                  badge: 'KINGDOM',
                ),

                const SizedBox(height: 120), // Mini player clearance
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.muted(context), fontSize: 12)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanSelectorCard({
    required BuildContext context,
    required int index,
    required String title,
    required String price,
    required String period,
    String? badge,
  }) {
    final isSelected = _selectedPlanIndex == index;
    final isDark = AppColors.isDarkMode(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.14 : 0.08)
                  : AppColors.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFD4AF37)
                    : AppColors.border(context),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow(context),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? const Color(0xFFFFDF79) : const Color(0xFFB38020))
                              : AppColors.subtext(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? const Color(0xFFD4AF37) : AppColors.muted(context),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    color: AppColors.muted(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE63946), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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

  Widget _buildPrivilegeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
  }) {
    final isDark = AppColors.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.12 : 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.15 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFFDF79) : const Color(0xFFB38020),
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.subtext(context), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
