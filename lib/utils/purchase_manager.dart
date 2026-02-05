import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../main.dart'; // import PrefsHelper

class PurchaseManager {
  static final PurchaseManager instance = PurchaseManager._internal();
  PurchaseManager._internal();

  static const String premiumProductId = 'sake_l1_premium_content2';

  final ValueNotifier<bool> isPremiumNotifier = ValueNotifier(false);
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> initialize() async {
    // 1. Check local status first
    final isPremium = await PrefsHelper.isPremium();
    isPremiumNotifier.value = isPremium;

    // 2. Listen to purchase updates
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      debugPrint("IAP Error: $error");
    });
    
    // 3. Initial connection check (optional but good)
    await _iap.isAvailable();
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show loading if needed
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint("Purchase Error: ${purchaseDetails.error}");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // Verify purchase (simplified for now, ideally server-side)
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            await _unlockPremium();
          }
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // For production without a backend, you might rely on the plugin's status.
    // Ideally, perform receipt validation here.
    return true; 
  }

  Future<void> _unlockPremium() async {
    await PrefsHelper.setPremium(true);
    isPremiumNotifier.value = true;
  }

  Future<void> buyPremium(dynamic productDetails) async {
    // Fetch products if not provided
    ProductDetails? actualProduct;
    if (productDetails is ProductDetails) {
      actualProduct = productDetails;
    } else {
      final response = await _iap.queryProductDetails({premiumProductId});
      if (response.notFoundIDs.contains(premiumProductId) || response.productDetails.isEmpty) {
        debugPrint("Product not found: $premiumProductId");
        return;
      }
      actualProduct = response.productDetails.first;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: actualProduct);
    
    // Assuming non-consumable for premium unlock
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint("Restore error: $e");
    }
  }

  // Helper to fetch product details for Display
  Future<List<ProductDetails>> getProducts() async {
    final response = await _iap.queryProductDetails({premiumProductId});
    return response.productDetails;
  }
}
