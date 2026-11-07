import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Catalogue en lecture seule des abonnements de 6 mois.
/// Aucun achat, aucun droit professionnel et aucune écriture Firebase.
class StoreSubscriptionService {
  StoreSubscriptionService({InAppPurchase? store})
    : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;

  static const Map<String, String> _androidIds = {
    'silver': 'eurohabesha_silver_6m',
    'gold': 'eurohabesha_gold_6m',
    'vip': 'eurohabesha_vip_6m',
  };

  static const Map<String, String> _iosIds = {
    'silver': 'eurohabesha_silver',
    'gold': 'eurohabesha_gold',
    'vip': 'eurohabesha_vip',
  };

  static Map<String, String> get productIds {
    if (kIsWeb) return const {};
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidIds;
      case TargetPlatform.iOS:
        return _iosIds;
      default:
        return const {};
    }
  }

  /// Récupère uniquement les informations publiées par la boutique.
  /// Une réponse vide ne signifie pas que les produits n'existent pas :
  /// vérifier leur état, le compte testeur et l'installation de l'application.
  Future<StoreSubscriptionCatalog> loadCatalog() async {
    final ids = productIds;
    if (ids.isEmpty) {
      return const StoreSubscriptionCatalog(
        available: false,
        products: {},
        missingProductIds: [],
        error: 'Plateforme non prise en charge.',
      );
    }

    try {
      final available = await _store.isAvailable();
      if (!available) {
        return const StoreSubscriptionCatalog(
          available: false,
          products: {},
          missingProductIds: [],
          error: 'Boutique indisponible sur cet appareil.',
        );
      }

      final response = await _store.queryProductDetails(ids.values.toSet());
      final byId = {
        for (final product in response.productDetails) product.id: product,
      };
      final products = <String, ProductDetails>{};
      for (final entry in ids.entries) {
        final product = byId[entry.value];
        if (product != null) products[entry.key] = product;
      }
      return StoreSubscriptionCatalog(
        available: true,
        products: products,
        missingProductIds: response.notFoundIDs,
        error: response.error?.message,
      );
    } catch (error) {
      return StoreSubscriptionCatalog(
        available: false,
        products: const {},
        missingProductIds: const [],
        error: 'Impossible de consulter la boutique : $error',
      );
    }
  }
}

@immutable
class StoreSubscriptionCatalog {
  const StoreSubscriptionCatalog({
    required this.available,
    required this.products,
    required this.missingProductIds,
    this.error,
  });

  final bool available;

  /// Clés : silver, gold, vip. Le prix localisé est dans ProductDetails.price.
  final Map<String, ProductDetails> products;
  final List<String> missingProductIds;
  final String? error;
}
