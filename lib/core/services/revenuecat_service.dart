// lib/core/services/revenuecat_service.dart
import 'dart:developer';
import 'package:beacon_os/core/constants/api_constants.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  bool _isInitialized = false;

  static Future<void> initialize() async {
    final apiKey = ApiConstants.revenueCatApiKey;
    if (apiKey.isEmpty) return;

    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      instance._isInitialized = true;
      log('RevenueCatService: Connected successfully.');
    } catch (e, st) {
      log('RevenueCatService: Init error: $e', stackTrace: st);
    }
  }

  Future<bool> isProUser() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['pro']?.isActive == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> purchasePro() async {
    if (!_isInitialized) return false;
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        final purchaseResult = await Purchases.purchasePackage(
          offerings.current!.availablePackages.first,
        );
        return purchaseResult.entitlements.all['pro']?.isActive == true;
      }
      return false;
    } catch (e) {
      log('RevenueCat Purchase cancelled or failed: $e');
      return false;
    }
  }
}