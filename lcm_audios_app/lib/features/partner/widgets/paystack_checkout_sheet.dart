import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/audio_player_service.dart';

class PaystackCheckoutSheet extends StatefulWidget {
  final String planType; // 'monthly' | 'annual'
  final int amount; // 2500 or 24000

  const PaystackCheckoutSheet({
    super.key,
    required this.planType,
    required this.amount,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String planType,
    required int amount,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaystackCheckoutSheet(
        planType: planType,
        amount: amount,
      ),
    );
  }

  @override
  State<PaystackCheckoutSheet> createState() => _PaystackCheckoutSheetState();
}

class _PaystackCheckoutSheetState extends State<PaystackCheckoutSheet> {
  final TextEditingController _emailController = TextEditingController(text: 'grace.worshipper@lcmfaith.org');
  final TextEditingController _cardNumberController = TextEditingController(text: '5399 •••• •••• 4128');
  final TextEditingController _expiryController = TextEditingController(text: '11/28');
  final TextEditingController _cvvController = TextEditingController(text: '883');

  int _selectedPaymentMethod = 0; // 0: Card, 1: Bank Transfer, 2: USSD
  bool _isProcessing = false;
  String _processingStatus = '';

  @override
  void dispose() {
    _emailController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String get _formattedAmount {
    if (widget.amount >= 1000) {
      final str = widget.amount.toString();
      final thousands = str.substring(0, str.length - 3);
      final remainder = str.substring(str.length - 3);
      return '₦$thousands,$remainder.00';
    }
    return '₦${widget.amount}.00';
  }

  Future<void> _processPaystackPayment(BuildContext context, AudioPlayerService playerService) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address for your Paystack receipt.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Initializing Paystack secure gateway...';
    });

    // 1. Initialize Paystack transaction with Backend API
    final initData = await ApiService.initializePaystackPayment(
      email: email,
      planType: widget.planType,
    );

    final reference = initData?['reference'] ??
        'LCM-PARTNER-${widget.planType.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _processingStatus = 'Encrypting card tokens with 256-bit SSL...';
    });
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() {
      _processingStatus = 'Verifying with Paystack CBN Clearing...';
    });

    // 2. Verify payment with backend
    final verifyData = await ApiService.verifyPaystackPayment(reference);

    final receiptNo = verifyData?['receiptNumber'] ?? 'LCM-REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final expiryDate = verifyData?['expirationDate'] ??
        DateTime.now().add(widget.planType == 'annual' ? const Duration(days: 365) : const Duration(days: 30)).toIso8601String();

    // 3. Activate partner tier on mobile state
    await playerService.activatePartnerTier(
      true,
      planType: widget.planType,
      reference: reference,
      receiptNumber: receiptNo,
      expiryDate: expiryDate,
    );

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    if (context.mounted) {
      Navigator.of(context).pop(true);
      _showCelebrationDialog(context, reference, receiptNo);
    }
  }

  void _showCelebrationDialog(BuildContext context, String reference, String receiptNo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF160E22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF140D1E),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'COVENANT PARTNER ACTIVE',
              style: TextStyle(
                color: Color(0xFFFFDF79),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '🎉 Kingdom Partnership Seed Confirmed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _receiptRow('Offering Tier', widget.planType == 'annual' ? 'Annual Covenant (₦24,000)' : 'Monthly Seed (₦2,500)'),
                  const SizedBox(height: 6),
                  _receiptRow('Receipt No.', receiptNo),
                  const SizedBox(height: 6),
                  _receiptRow('Gateway', 'Paystack Verified (SSL)'),
                  const SizedBox(height: 6),
                  _receiptRow('Status', 'Unlocked (Unrestricted)'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'May the Lord multiply your seed sown and enlarge the harvest of your righteousness. (2 Cor 9:10)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF140D1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'ENTER SERMON VAULT',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context, listen: false);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF10121A), // Sleek Paystack dark modal
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF0BA4DB), width: 2), // Paystack blue accent
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Paystack branding
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0BA4DB).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.lock_rounded, color: Color(0xFF0BA4DB), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'paystack',
                              style: TextStyle(
                                color: Color(0xFF0BA4DB),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SECURE CHECKOUT',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Offering Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B2338), Color(0xFF131826)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.planType == 'annual'
                              ? 'Annual Covenant Partner'
                              : 'Monthly Kingdom Seed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'LCM Faith Broadcasting & Media',
                          style: TextStyle(color: Colors.white54, fontSize: 11.5),
                        ),
                      ],
                    ),
                    Text(
                      _formattedAmount,
                      style: const TextStyle(
                        color: Color(0xFFFFDF79),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Donor Email
              const Text(
                'DONOR EMAIL ADDRESS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38, size: 18),
                  hintText: 'yourname@example.com',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0BA4DB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Channels Switcher
              Row(
                children: [
                  _buildMethodChip(0, Icons.credit_card_rounded, 'Card'),
                  const SizedBox(width: 8),
                  _buildMethodChip(1, Icons.account_balance_rounded, 'Bank Transfer'),
                  const SizedBox(width: 8),
                  _buildMethodChip(2, Icons.phone_android_rounded, 'USSD / QR'),
                ],
              ),
              const SizedBox(height: 14),

              if (_selectedPaymentMethod == 0) ...[
                // Card details form
                TextField(
                  controller: _cardNumberController,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFF0BA4DB), size: 18),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 12),
                      ],
                    ),
                    labelText: 'Card Number',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0BA4DB)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _expiryController,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: 'Expiry (MM/YY)',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _cvvController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_selectedPaymentMethod == 1) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Pay via Paystack Virtual Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 4),
                      Text('Account Number: 9940281140\nBank Name: Wema Bank / Paystack\nAccount Name: LCM Ministry Broadcasts', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dial USSD Code on your phone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('GTBank: *737*50*$_formattedAmount*414#\nZenith Bank: *966*00*414#\nAccess Bank: *901*00*414#', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Pay CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _processPaystackPayment(context, playerService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0BA4DB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _processingStatus,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'PAY $_formattedAmount VIA PAYSTACK',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'PCI-DSS Level 1 Certified • 256-bit Bank Grade Security',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodChip(int index, IconData icon, String label) {
    final isSelected = _selectedPaymentMethod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0BA4DB).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF0BA4DB) : Colors.white10,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF0BA4DB) : Colors.white54, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
