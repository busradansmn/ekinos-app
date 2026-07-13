import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

/// ---------------------------------------------------------------------------
/// EKINOS — Fully In-Memory Riverpod Ecosystem
/// ---------------------------------------------------------------------------
/// No database, no network calls. Every list below lives purely in RAM for
/// the lifetime of the app. Mutating one Notifier from the Producer
/// Dashboard is instantly reflected on the Consumer Feed and vice-versa,
/// because both screens watch the exact same provider instances.
/// ---------------------------------------------------------------------------

// =============================================================================
// Producers
// =============================================================================
class ProducersNotifier extends StateNotifier<List<Producer>> {
  ProducersNotifier() : super(_seedProducers);

  static const List<Producer> _seedProducers = [
    Producer(
      id: 'p1',
      name: 'Mehmet Amca',
      village: 'Darende / Balaban',
      avatarEmoji: '👨‍🌾',
      rating: 4.9,
    ),
    Producer(
      id: 'p2',
      name: 'Ayşe Teyze',
      village: 'Darende / Merkez',
      avatarEmoji: '👵',
      rating: 4.6,
    ),
    Producer(
      id: 'p3',
      name: 'Hasan Dayı',
      village: 'Darende / Ulaş',
      avatarEmoji: '🧔',
      rating: 4.95,
    ),
    Producer(
      id: 'p4',
      name: 'Fatma Teyze',
      village: 'Darende / Gürpınar',
      avatarEmoji: '👩‍🌾',
      rating: 4.7,
    ),
  ];

  Producer? byId(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }
}

final producersProvider =
    StateNotifierProvider<ProducersNotifier, List<Producer>>(
  (ref) => ProducersNotifier(),
);

/// The producer currently "logged in" on the Producer Dashboard. Since this
/// is an in-memory simulation with no real auth yet, we simply pin the
/// dashboard to the first seed producer.
final currentProducerIdProvider = Provider<String>((ref) => 'p1');

// =============================================================================
// Campaigns — the single source of truth every screen reads/writes.
// =============================================================================
class CampaignsNotifier extends StateNotifier<List<Campaign>> {
  CampaignsNotifier() : super(_seedCampaigns);

  static const List<Campaign> _seedCampaigns = [
    Campaign(
      id: 'c1',
      producerId: 'p1',
      producerName: 'Mehmet Amca',
      producerRating: 4.9,
      productName: 'Darende Gün Kurusu Kayısı',
      emoji: '🍑',
      category: ProductCategory.tarimUrunleri,
      basePrice: 200,
      discountedPrice: 180,
      discountThresholdKg: 50,
      targetVolume: 100,
      collectedVolume: 45,
      unit: 'KG',
      deliveryInfo: 'Cumartesi - Somuncu Baba Otoparkı',
    ),
    Campaign(
      id: 'c2',
      producerId: 'p2',
      producerName: 'Ayşe Teyze',
      producerRating: 4.6,
      productName: 'Ev Yapımı Tarhana',
      emoji: '🥣',
      category: ProductCategory.elEmegiYoresel,
      basePrice: 250,
      discountedPrice: 220,
      discountThresholdKg: 30,
      targetVolume: 60,
      collectedVolume: 15,
      unit: 'KG',
      deliveryInfo: 'Çarşamba - İlçe Meydanı',
    ),
    Campaign(
      id: 'c3',
      producerId: 'p3',
      producerName: 'Hasan Dayı',
      producerRating: 4.95,
      productName: 'Soğuk Sıkım Zeytinyağı',
      emoji: '🫒',
      category: ProductCategory.tarimUrunleri,
      basePrice: 400,
      discountedPrice: 350,
      discountThresholdKg: 40,
      targetVolume: 80,
      collectedVolume: 38,
      unit: 'KG',
      deliveryInfo: 'Pazar - Belediye Standı',
    ),
    Campaign(
      id: 'c4',
      producerId: 'p4',
      producerName: 'Fatma Teyze',
      producerRating: 4.7,
      productName: 'El Yapımı Yöresel Erişte',
      emoji: '🍜',
      category: ProductCategory.elEmegiYoresel,
      basePrice: 150,
      discountedPrice: 130,
      discountThresholdKg: 25,
      targetVolume: 50,
      collectedVolume: 6,
      unit: 'Adet',
      deliveryInfo: 'Cumartesi - Somuncu Baba Otoparkı',
    ),
  ];

  void addCampaign(Campaign campaign) {
    state = [campaign, ...state];
  }

  /// Adds ordered volume to a campaign's collected total (clamped to the
  /// target), instantly re-triggering the progress bar + dynamic pricing.
  void addOrderVolume(String campaignId, double volume) {
    state = [
      for (final c in state)
        if (c.id == campaignId)
          c.copyWith(
            collectedVolume: (c.collectedVolume + volume).clamp(
              0,
              c.targetVolume,
            ),
          )
        else
          c,
    ];
  }

  Campaign? byId(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }
}

final campaignsProvider =
    StateNotifierProvider<CampaignsNotifier, List<Campaign>>(
  (ref) => CampaignsNotifier(),
);

// =============================================================================
// Harvest / Production Calendar
// =============================================================================
class HarvestCalendarNotifier extends StateNotifier<List<HarvestEntry>> {
  HarvestCalendarNotifier() : super(_seedEntries);

  static const List<HarvestEntry> _seedEntries = [
    HarvestEntry(
      id: 'h1',
      producerId: 'p1',
      producerName: 'Mehmet Amca',
      monthLabel: 'Temmuz',
      productName: 'Gün Kurusu',
      emoji: '🍑',
      category: ProductCategory.tarimUrunleri,
    ),
    HarvestEntry(
      id: 'h2',
      producerId: 'p2',
      producerName: 'Ayşe Teyze',
      monthLabel: 'Eylül',
      productName: 'Tarhana & Erişte 🔔',
      emoji: '🥣',
      category: ProductCategory.elEmegiYoresel,
    ),
    HarvestEntry(
      id: 'h3',
      producerId: 'p3',
      producerName: 'Hasan Dayı',
      monthLabel: 'Kasım',
      productName: 'Zeytin Hasadı',
      emoji: '🫒',
      category: ProductCategory.tarimUrunleri,
    ),
    HarvestEntry(
      id: 'h4',
      producerId: 'p4',
      producerName: 'Fatma Teyze',
      monthLabel: 'Ağustos',
      productName: 'Salça & Turşuluk',
      emoji: '🍅',
      category: ProductCategory.elEmegiYoresel,
    ),
  ];

  void addEntry(HarvestEntry entry) {
    state = [...state, entry];
  }
}

final harvestCalendarProvider =
    StateNotifierProvider<HarvestCalendarNotifier, List<HarvestEntry>>(
  (ref) => HarvestCalendarNotifier(),
);

// =============================================================================
// Harvest Tracking — set of HarvestEntry IDs the consumer tapped to
// "subscribe" to. Purely a local simulation of a future push reminder.
// =============================================================================
class TrackedHarvestNotifier extends StateNotifier<Set<String>> {
  TrackedHarvestNotifier() : super(<String>{});

  /// Returns true if tracking was just turned ON (false if turned off).
  bool toggle(String entryId) {
    final updated = {...state};
    final bool willTrack = !updated.contains(entryId);
    if (willTrack) {
      updated.add(entryId);
    } else {
      updated.remove(entryId);
    }
    state = updated;
    return willTrack;
  }

  bool isTracked(String entryId) => state.contains(entryId);
}

final trackedHarvestProvider =
    StateNotifierProvider<TrackedHarvestNotifier, Set<String>>(
  (ref) => TrackedHarvestNotifier(),
);

// =============================================================================
// Favorites — set of producer IDs the consumer follows with a star tap.
// =============================================================================
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super(<String>{'p1'});

  void toggle(String producerId) {
    final updated = {...state};
    if (updated.contains(producerId)) {
      updated.remove(producerId);
    } else {
      updated.add(producerId);
    }
    state = updated;
  }

  bool isFavorite(String producerId) => state.contains(producerId);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);

// =============================================================================
// Orders — every confirmed order, each carrying its own delivery stage.
// =============================================================================
class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super(const []);

  void addOrder(Order order) {
    state = [...state, order];
  }

  void advanceDeliveryStage(String orderId) {
    state = [
      for (final o in state)
        if (o.id == orderId) o.copyWith(stage: o.stage.next) else o,
    ];
  }

  Order? byId(String id) {
    for (final o in state) {
      if (o.id == id) return o;
    }
    return null;
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>(
  (ref) => OrdersNotifier(),
);

// =============================================================================
// Consumer Request Pool — İstek Havuzu. Consumers ask for products that
// aren't listed yet; any producer can accept one from their dashboard,
// instantly converting it into a live Campaign.
// =============================================================================
class ConsumerRequestsNotifier extends StateNotifier<List<ConsumerRequest>> {
  ConsumerRequestsNotifier() : super(_seedRequests);

  static final List<ConsumerRequest> _seedRequests = [
    ConsumerRequest(
      id: 'r1',
      title: 'Erişte yapan var mı?',
      description:
          'Kışlık erzak için ev yapımı, katkısız erişte arıyorum. 5 kg civarı '
          'yeterli olur.',
      category: ProductCategory.elEmegiYoresel,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    ConsumerRequest(
      id: 'r2',
      title: 'Organik ceviz arıyorum',
      description:
          'Darende çevresinden, ilaçsız yetişmiş taze ceviz bulabilir miyiz? '
          'Kabuklu olması tercih sebebi.',
      category: ProductCategory.tarimUrunleri,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  void addRequest(ConsumerRequest request) {
    state = [request, ...state];
  }

  /// Removes the request the instant a producer accepts it.
  void removeRequest(String requestId) {
    state = state.where((r) => r.id != requestId).toList();
  }

  ConsumerRequest? byId(String id) {
    for (final r in state) {
      if (r.id == id) return r;
    }
    return null;
  }
}

final consumerRequestsProvider =
    StateNotifierProvider<ConsumerRequestsNotifier, List<ConsumerRequest>>(
  (ref) => ConsumerRequestsNotifier(),
);

// =============================================================================
// Smart Notifications — appended for harvest forecasts, new campaigns from
// favorited producers, and accepted İstek Havuzu requests. The Consumer
// Feed listens to `latestNotificationProvider`, shows the overlay banner,
// then clears it back to null so it never refires on an unrelated rebuild.
// =============================================================================
class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super(const []);

  void push(AppNotification notification) {
    state = [notification, ...state];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

/// One-shot "fire and forget" slot for the banner. Set the moment a
/// notification-worthy event happens; the feed screen consumes it and
/// resets it to null.
final latestNotificationProvider =
    StateProvider<AppNotification?>((ref) => null);

/// Interactive unseen-count badge on the notification bell. Incremented on
/// every push, reset to zero the moment the person opens the bell sheet.
final unseenNotificationCountProvider = StateProvider<int>((ref) => 0);

// =============================================================================
// Category Filter — drives the Consumer Feed's chip row. `null` = "Tümü".
// =============================================================================
final categoryFilterProvider = StateProvider<ProductCategory?>((ref) => null);

// =============================================================================
// Cross-Screen Simulation Hub
// =============================================================================
/// Central helper used by both the Producer Dashboard and the Consumer Feed
/// to mutate the shared in-memory ecosystem. Every method here is the
/// single choke point through which cross-screen effects (new calendar
/// rows, new campaigns, smart notification banners) are produced, keeping
/// the "event-driven ecosystem" logic in one auditable place.
class EcosystemActions {
  EcosystemActions(this.ref);
  final Ref ref;

  String _nextId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  void _pushNotification(AppNotification notification) {
    ref.read(notificationsProvider.notifier).push(notification);
    ref.read(latestNotificationProvider.notifier).state = notification;
    ref.read(unseenNotificationCountProvider.notifier).state++;
  }

  /// TAB 1 · Bölüm A — Gelecek Hasat Bildirimi Formu.
  /// Only appends a row to the horizontal harvest calendar and fires a
  /// GLOBAL "Sezon Takip Bildirimi" banner to every consumer — no campaign
  /// is opened yet, this is purely a forward-looking forecast.
  void publishHarvestForecast({
    required Producer producer,
    required String monthLabel,
    required String productName,
    required String emoji,
    required ProductCategory category,
  }) {
    ref.read(harvestCalendarProvider.notifier).addEntry(
          HarvestEntry(
            id: _nextId('h'),
            producerId: producer.id,
            producerName: producer.name,
            monthLabel: monthLabel,
            productName: productName,
            emoji: emoji,
            category: category,
          ),
        );

    _pushNotification(
      AppNotification(
        id: _nextId('n'),
        producerName: producer.name,
        message:
            '🔔 Sezon Takip Bildirimi: ${producer.name}, $monthLabel ayında '
            '"$productName" hasadı bekliyor!',
        type: NotificationType.harvestForecast,
      ),
    );
  }

  /// TAB 1 · Bölüm B — Aktif Satış İlanı Ver.
  /// Opens a brand-new, fully live pre-order Campaign in the shared pool
  /// the Consumer Feed watches. Only notifies consumers who favorited this
  /// producer, since it's a direct purchase opportunity for their followers.
  Campaign publishActiveCampaign({
    required Producer producer,
    required String productName,
    required String emoji,
    required ProductCategory category,
    required double basePrice,
    required double discountedPrice,
    required double discountThresholdKg,
    required double targetVolume,
    required String unit,
    required String deliveryInfo,
  }) {
    final campaign = Campaign(
      id: _nextId('c'),
      producerId: producer.id,
      producerName: producer.name,
      producerRating: producer.rating,
      productName: productName,
      emoji: emoji,
      category: category,
      basePrice: basePrice,
      discountedPrice: discountedPrice,
      discountThresholdKg: discountThresholdKg,
      targetVolume: targetVolume,
      collectedVolume: 0,
      unit: unit,
      deliveryInfo: deliveryInfo,
    );

    ref.read(campaignsProvider.notifier).addCampaign(campaign);

    final isFavorited =
        ref.read(favoritesProvider.notifier).isFavorite(producer.id);

    if (isFavorited) {
      _pushNotification(
        AppNotification(
          id: _nextId('n'),
          producerName: producer.name,
          campaignId: campaign.id,
          message: '${producer.name} yeni bir ön sipariş kampanyası başlattı!',
          type: NotificationType.campaignLaunch,
        ),
      );
    }

    return campaign;
  }

  /// TAB 2 — İlçeden Gelen Talepler. Tapping "Ben Üretebilirim" instantly:
  ///   1) removes the request from the shared pool,
  ///   2) spins up a fresh active Campaign for it (sensible simulated
  ///      defaults based on the request's category),
  ///   3) fires a celebratory banner back on the Consumer Feed.
  Campaign acceptConsumerRequest({
    required Producer producer,
    required ConsumerRequest request,
  }) {
    final bool isElEmegi = request.category == ProductCategory.elEmegiYoresel;
    final String unit = isElEmegi ? 'Adet' : 'KG';
    final double target = isElEmegi ? 40 : 60;
    final double basePrice = isElEmegi ? 160 : 190;
    final double discountedPrice = isElEmegi ? 135 : 165;
    final double threshold = target * 0.5;
    final String emoji = isElEmegi ? '🧺' : '🌿';

    final campaign = Campaign(
      id: _nextId('c'),
      producerId: producer.id,
      producerName: producer.name,
      producerRating: producer.rating,
      productName: request.title,
      emoji: emoji,
      category: request.category,
      basePrice: basePrice,
      discountedPrice: discountedPrice,
      discountThresholdKg: threshold,
      targetVolume: target,
      collectedVolume: 0,
      unit: unit,
      deliveryInfo: 'Yakında duyurulacak - ${producer.village}',
      bornFromRequest: true,
    );

    ref.read(campaignsProvider.notifier).addCampaign(campaign);
    ref.read(consumerRequestsProvider.notifier).removeRequest(request.id);

    _pushNotification(
      AppNotification(
        id: _nextId('n'),
        producerName: producer.name,
        campaignId: campaign.id,
        message:
            '${producer.name} isteğinizi kabul etti! "${request.title}" için '
            'kampanya başladı.',
        type: NotificationType.requestAccepted,
      ),
    );

    return campaign;
  }

  /// The Consumer Feed's "İstek Bırakın" form sheet submits here.
  void submitConsumerRequest({
    required String title,
    required String description,
    required ProductCategory category,
  }) {
    ref.read(consumerRequestsProvider.notifier).addRequest(
          ConsumerRequest(
            id: _nextId('r'),
            title: title,
            description: description,
            category: category,
            createdAt: DateTime.now(),
          ),
        );
  }
}

final ecosystemActionsProvider = Provider<EcosystemActions>(
  (ref) => EcosystemActions(ref),
);
