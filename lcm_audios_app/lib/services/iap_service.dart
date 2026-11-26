import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'api_service.dart';
import 'audio_player_service.dart';

/// Native Apple StoreKit / Google Play Billing service for Covenant Partner subscriptions.
class IapService {
  static const String monthlyProductId = 'lcm_covenant_monthly';
  static const String annualProductId = 'lcm_covenant_annual';
  static const Set<String> productIds = {monthlyProductId, annualProductId};

  static final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> products = [];
  bool isAvailable = false;

  void Function(bool success, String message)? onPurchaseResult;

  Future<void> init(AudioPlayerService playerService) async {
    try {
      isAvailable = await _iap.isAvailable();
    } catch (e) {
      debugPrint('[IAP] Availability check error: $e');
      isAvailable = false;
    }

    if (!isAvailable) return;

    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      (purchases) => _handlePurchaseUpdates(purchases, playerService),
      onError: (Object error) {
        debugPrint('[IAP] Stream error: $error');
        onPurchaseResult?.call(false, 'Purchase error: $error');
      },
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!isAvailable) return;
    try {
      final response = await _iap.queryProductDetails(productIds);
      if (response.error != null) {
        debugPrint('[IAP] Product query error: ${response.error}');
      }
      products = response.productDetails;
    } catch (e) {
      debugPrint('[IAP] Failed to load products: $e');
    }
  }

  ProductDetails? getProduct(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<bool> buyPlan(String productId) async {
    if (!isAvailable) {
      onPurchaseResult?.call(false, 'In-App Purchases are unavailable on this device.');
      return false;
    }
    final product = getProduct(productId);
    if (product == null) {
      onPurchaseResult?.call(
        false,
        'Subscription plan ($productId) is not configured in the store yet.',
      );
      return false;
    }

    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    if (!isAvailable) {
      onPurchaseResult?.call(false, 'Store billing is unavailable on this device.');
      return;
    }
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
    AudioPlayerService playerService,
  ) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final planType = purchase.productID == annualProductId ? 'annual' : 'monthly';
        final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'apple' : 'google';

        final verifyRes = await ApiService.verifyInAppPurchase(
          token: playerService.jwtToken,
          platform: platform,
          productId: purchase.productID,
          purchaseId: purchase.purchaseID ?? '',
          verificationData: purchase.verificationData.serverVerificationData,
        );

        await playerService.activatePartnerTier(
          true,
          planType: planType,
          reference: purchase.purchaseID ?? 'IAP-${DateTime.now().millisecondsSinceEpoch}',
          receiptNumber: verifyRes['receiptNumber']?.toString(),
          expiryDate: verifyRes['expirationDate']?.toString(),
        );

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

        onPurchaseResult?.call(
          true,
          purchase.status == PurchaseStatus.restored
              ? 'Covenant Partner subscription restored!'
              : 'Welcome, Covenant Partner! Full catalog unlocked.',
        );
      } else if (purchase.status == PurchaseStatus.error) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        onPurchaseResult?.call(
          false,
          purchase.error?.message ?? 'Purchase could not be completed.',
        );
      } else if (purchase.status == PurchaseStatus.canceled) {
        onPurchaseResult?.call(false, 'Purchase was cancelled.');
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
