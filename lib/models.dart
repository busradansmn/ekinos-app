/// ---------------------------------------------------------------------------
/// EKINOS — Data Blueprints
/// ---------------------------------------------------------------------------
/// Every model below is a plain, immutable Dart class. No backend, no JSON —
/// everything is created, mutated (via copyWith) and destroyed purely inside
/// the Riverpod in-memory Notifiers defined in providers.dart.
/// ---------------------------------------------------------------------------

/// The two top-level categories the Consumer Feed can be filtered by.
enum ProductCategory { tarimUrunleri, elEmegiYoresel }

extension ProductCategoryX on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.tarimUrunleri:
        return 'Tarım Ürünleri';
      case ProductCategory.elEmegiYoresel:
        return 'El Emeği / Yöresel Ürünler';
    }
  }

  String get shortLabel {
    switch (this) {
      case ProductCategory.tarimUrunleri:
        return 'Tarım Ürünleri';
      case ProductCategory.elEmegiYoresel:
        return 'El Emeği';
    }
  }
}

/// -----------------------------------------------------------------------
/// Producer — a local farmer / artisan. Rating drives the automatic
/// "Öne Çıkan Üretici" premium badge across the app.
/// -----------------------------------------------------------------------
class Producer {
  final String id;
  final String name;
  final String village;
  final String avatarEmoji;
  final double rating;

  const Producer({
    required this.id,
    required this.name,
    required this.village,
    required this.avatarEmoji,
    required this.rating,
  });

  /// Producers rated 4.8 and above are automatically highlighted with a
  /// premium ochre border + badge everywhere their campaigns appear.
  bool get isHighlighted => rating >= 4.8;

  Producer copyWith({double? rating}) {
    return Producer(
      id: id,
      name: name,
      village: village,
      avatarEmoji: avatarEmoji,
      rating: rating ?? this.rating,
    );
  }
}

/// -----------------------------------------------------------------------
/// HarvestEntry — a single row on the horizontally scrolling Production /
/// Harvest Calendar at the top of the Consumer Feed. Producers add these
/// from their dashboard; each one instantly appears on every device's
/// calendar strip. Consumers can tap an entry to simulate subscribing to
/// a "season tracking" alert for that future harvest.
/// -----------------------------------------------------------------------
class HarvestEntry {
  final String id;
  final String producerId;
  final String producerName;
  final String monthLabel; // e.g. "Temmuz", "Eylül"
  final String productName; // e.g. "Gün Kurusu", "Tarhana & Erişte"
  final String emoji;
  final ProductCategory category;

  const HarvestEntry({
    required this.id,
    required this.producerId,
    required this.producerName,
    required this.monthLabel,
    required this.productName,
    required this.emoji,
    required this.category,
  });
}

/// -----------------------------------------------------------------------
/// Campaign — a live, collective pre-order pool for one product. Volume
/// collected from consumer orders drives the dynamic price-drop engine.
/// -----------------------------------------------------------------------
class Campaign {
  final String id;
  final String producerId;
  final String producerName;
  final double producerRating;
  final String productName;
  final String emoji;
  final ProductCategory category;

  /// Price per KG/Adet while under the discount threshold.
  final double basePrice;

  /// Price per KG/Adet once [collectedVolume] passes [discountThresholdKg].
  final double discountedPrice;

  /// Volume (KG or Adet) at which the discounted price unlocks.
  final double discountThresholdKg;

  final double targetVolume;
  final double collectedVolume;
  final String unit; // "KG" or "Adet"
  final String deliveryInfo;

  /// True when this campaign was born directly from an accepted consumer
  /// request in the İstek Havuzu, rather than a producer-initiated ad.
  final bool bornFromRequest;

  const Campaign({
    required this.id,
    required this.producerId,
    required this.producerName,
    required this.producerRating,
    required this.productName,
    required this.emoji,
    required this.category,
    required this.basePrice,
    required this.discountedPrice,
    required this.discountThresholdKg,
    required this.targetVolume,
    required this.collectedVolume,
    required this.unit,
    required this.deliveryInfo,
    this.bornFromRequest = false,
  });

  double get progress =>
      targetVolume <= 0 ? 0 : (collectedVolume / targetVolume).clamp(0.0, 1.0);

  double get remainingVolume =>
      (targetVolume - collectedVolume).clamp(0, targetVolume);

  /// Whether collective demand has crossed the discount line.
  bool get isDiscountActive => collectedVolume >= discountThresholdKg;

  /// The price that should actually be charged right now.
  double get currentPrice => isDiscountActive ? discountedPrice : basePrice;

  bool get isHighlightedProducer => producerRating >= 4.8;

  Campaign copyWith({double? collectedVolume}) {
    return Campaign(
      id: id,
      producerId: producerId,
      producerName: producerName,
      producerRating: producerRating,
      productName: productName,
      emoji: emoji,
      category: category,
      basePrice: basePrice,
      discountedPrice: discountedPrice,
      discountThresholdKg: discountThresholdKg,
      targetVolume: targetVolume,
      collectedVolume: collectedVolume ?? this.collectedVolume,
      unit: unit,
      deliveryInfo: deliveryInfo,
      bornFromRequest: bornFromRequest,
    );
  }
}

/// -----------------------------------------------------------------------
/// ConsumerRequest — İstek Havuzu entry. A consumer asks for a local
/// product that isn't currently listed; any producer can accept it,
/// instantly turning it into a live Campaign.
/// -----------------------------------------------------------------------
class ConsumerRequest {
  final String id;
  final String title;
  final String description;
  final ProductCategory category;
  final DateTime createdAt;

  const ConsumerRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
  });
}

/// -----------------------------------------------------------------------
/// Order lifecycle — the "Simüle Et" logistics stepper on the receipt
/// screen walks through these three stages, in order.
/// -----------------------------------------------------------------------
enum DeliveryStage { ureticiYolaCikti, kamyonStandaVardi, teslimatBasladi }

extension DeliveryStageX on DeliveryStage {
  String get label {
    switch (this) {
      case DeliveryStage.ureticiYolaCikti:
        return 'Üretici Yola Çıktı';
      case DeliveryStage.kamyonStandaVardi:
        return 'Kamyon Standa Vardı';
      case DeliveryStage.teslimatBasladi:
        return 'Teslimat Başladı';
    }
  }

  int get stepIndex => index;

  bool get isFinal => this == DeliveryStage.teslimatBasladi;

  DeliveryStage get next {
    switch (this) {
      case DeliveryStage.ureticiYolaCikti:
        return DeliveryStage.kamyonStandaVardi;
      case DeliveryStage.kamyonStandaVardi:
        return DeliveryStage.teslimatBasladi;
      case DeliveryStage.teslimatBasladi:
        return DeliveryStage.teslimatBasladi;
    }
  }
}

/// A confirmed pre-order, created the moment a consumer taps
/// "Siparişi Onayla". Lives entirely in memory via OrdersNotifier.
class Order {
  final String id;
  final String campaignId;
  final String productName;
  final String emoji;
  final String producerName;
  final double quantity;
  final String unit;
  final double totalPrice;
  final DeliveryStage stage;

  const Order({
    required this.id,
    required this.campaignId,
    required this.productName,
    required this.emoji,
    required this.producerName,
    required this.quantity,
    required this.unit,
    required this.totalPrice,
    this.stage = DeliveryStage.ureticiYolaCikti,
  });

  Order copyWith({DeliveryStage? stage}) {
    return Order(
      id: id,
      campaignId: campaignId,
      productName: productName,
      emoji: emoji,
      producerName: producerName,
      quantity: quantity,
      unit: unit,
      totalPrice: totalPrice,
      stage: stage ?? this.stage,
    );
  }
}

/// -----------------------------------------------------------------------
/// AppNotification — an in-app smart notification. Fired for three
/// distinct ecosystem events, each with its own icon/tone in the UI:
///   • harvestForecast   -> a producer announced a future harvest
///   • campaignLaunch    -> a favorited producer opened a live pre-order
///   • requestAccepted   -> a producer fulfilled a consumer's İstek Havuzu ask
/// -----------------------------------------------------------------------
enum NotificationType { harvestForecast, campaignLaunch, requestAccepted }

class AppNotification {
  final String id;
  final String producerName;
  final String? campaignId;
  final String message;
  final NotificationType type;

  const AppNotification({
    required this.id,
    required this.producerName,
    this.campaignId,
    required this.message,
    this.type = NotificationType.campaignLaunch,
  });
}
