import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'models.dart';
import 'providers.dart';
import 'main_flow_screens.dart';

const List<String> kMonths = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

const List<String> kEmojiOptions = [
  '🌾', '🍑', '🫒', '🍯', '🥣', '🍜', '🍅', '🧀', '🥖', '🍇',
];

String? numberValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Gerekli';
  final parsed = double.tryParse(v.replaceAll(',', '.'));
  if (parsed == null || parsed <= 0) return 'Geçerli bir sayı girin';
  return null;
}

Widget fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );

/// =============================================================================
/// PRODUCER DASHBOARD — Two distinct, ayırt edilmiş modüller behind a
/// premium bottom navigation bar:
///   TAB 1: Kampanyalar & Hasat Yönetimi (harvest forecast + active ads)
///   TAB 2: İlçeden Gelen Talepler (İstek Havuzu)
/// =============================================================================
class ProducerDashboardScreen extends ConsumerStatefulWidget {
  const ProducerDashboardScreen({super.key});

  @override
  ConsumerState<ProducerDashboardScreen> createState() =>
      _ProducerDashboardScreenState();
}

class _ProducerDashboardScreenState
    extends ConsumerState<ProducerDashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final producerId = ref.watch(currentProducerIdProvider);
    final producers = ref.watch(producersProvider);
    final producer = producers.firstWhere((p) => p.id == producerId);
    final requestCount = ref.watch(consumerRequestsProvider).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Üretici Paneli'),
        actions: [
          IconButton(
            tooltip: 'Rolü Değiştir',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            _CampaignsAndHarvestTab(producer: producer),
            _RequestPoolTab(producer: producer),
          ],
        ),
      ),
      bottomNavigationBar: _ProducerBottomNav(
        currentIndex: _tabIndex,
        requestBadgeCount: requestCount,
        onChanged: (i) => setState(() => _tabIndex = i),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Premium Bottom Navigation Bar with a live badge for incoming requests.
/// -----------------------------------------------------------------------
class _ProducerBottomNav extends StatelessWidget {
  const _ProducerBottomNav({
    required this.currentIndex,
    required this.requestBadgeCount,
    required this.onChanged,
  });

  final int currentIndex;
  final int requestBadgeCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.storefront_rounded,
                label: 'Kampanyalar & Hasat',
                selected: currentIndex == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.inventory_2_rounded,
                label: 'İlçeden Gelen Talepler',
                selected: currentIndex == 1,
                onTap: () => onChanged(1),
                badgeCount: requestBadgeCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primaryGreen : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardWhite, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =============================================================================
/// TAB 1 — KAMPANYALAR & HASAT YÖNETİMİ
/// =============================================================================
class _CampaignsAndHarvestTab extends ConsumerWidget {
  const _CampaignsAndHarvestTab({required this.producer});

  final Producer producer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final producerId = producer.id;

    final campaigns = ref
        .watch(campaignsProvider)
        .where((c) => c.producerId == producerId)
        .toList();

    final orders = ref
        .watch(ordersProvider)
        .where((o) => campaigns.any((c) => c.id == o.campaignId))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _ProducerProfileCard(producer: producer),
        const SizedBox(height: 28),

        // ----- Bölüm A: Gelecek Hasat Bildirimi Formu -----
        _SectionHeader(
          emoji: '📅',
          title: 'Gelecek Hasat Bildirimi',
          subtitle:
              'Bu formu gönderdiğinizde tüm tüketicilere anında bir "Sezon '
              'Takip Bildirimi" gider ve ürün takvime eklenir. Henüz satışa '
              'açılmaz.',
        ),
        const SizedBox(height: 14),
        _HarvestForecastForm(producer: producer),

        const SizedBox(height: 32),

        // ----- Bölüm B: Aktif Satış İlanı Ver -----
        _SectionHeader(
          emoji: '📣',
          title: 'Aktif Satış İlanı Ver',
          subtitle:
              'Anlık, tiered fiyatlandırmalı bir ön sipariş kampanyası açın. '
              'Kampanya anında tüketici akışında görünür.',
        ),
        const SizedBox(height: 14),
        _ActiveCampaignForm(producer: producer),

        const SizedBox(height: 32),
        Text(
          'Aktif Kampanyalarım (${campaigns.length})',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        if (campaigns.isEmpty)
          _EmptyState(text: 'Henüz kampanyanız yok. Yukarıdan ilk ilanınızı açın.')
        else
          ...campaigns.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CampaignOverviewTile(campaign: c),
              )),

        const SizedBox(height: 32),
        Text(
          'Lojistik Simülasyonu (${orders.length} sipariş)',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gelen siparişler için "Üretici Yola Çıktı ➔ Kamyon Standa Vardı ➔ '
          'Teslimat Başladı" akışını buradan simüle edin.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        if (orders.isEmpty)
          _EmptyState(text: 'Henüz gelen sipariş yok.')
        else
          ...orders.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderLogisticsTile(order: o),
              )),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    );
  }
}

/// -----------------------------------------------------------------------
/// Bölüm A — Gelecek Hasat Bildirimi Formu
/// -----------------------------------------------------------------------
class _HarvestForecastForm extends ConsumerStatefulWidget {
  const _HarvestForecastForm({required this.producer});

  final Producer producer;

  @override
  ConsumerState<_HarvestForecastForm> createState() => _HarvestForecastFormState();
}

class _HarvestForecastFormState extends ConsumerState<_HarvestForecastForm> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  String _monthLabel = 'Eylül';
  ProductCategory _category = ProductCategory.tarimUrunleri;
  String _emoji = '🌾';

  @override
  void dispose() {
    _productNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(ecosystemActionsProvider).publishHarvestForecast(
          producer: widget.producer,
          monthLabel: _monthLabel,
          productName: _productNameController.text.trim(),
          emoji: _emoji,
          category: _category,
        );

    _productNameController.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text(
          '🔔 Sezon Takip Bildirimi tüm tüketicilere gönderildi!',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fieldLabel('Ürün Adı'),
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(hintText: 'Örn. Tarhana & Erişte'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ürün adı gerekli' : null,
            ),
            const SizedBox(height: 14),
            fieldLabel('Simge'),
            _EmojiPicker(
              selected: _emoji,
              onSelected: (e) => setState(() => _emoji = e),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('Beklenen Hasat Ayı'),
                      DropdownButtonFormField<String>(
                        value: _monthLabel,
                        items: kMonths
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(() => _monthLabel = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('Kategori'),
                      DropdownButtonFormField<ProductCategory>(
                        value: _category,
                        items: ProductCategory.values
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c.shortLabel, style: const TextStyle(fontSize: 12.5))))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text('Sezon Takip Bildirimi Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Bölüm B — Aktif Satış İlanı Ver
/// -----------------------------------------------------------------------
class _ActiveCampaignForm extends ConsumerStatefulWidget {
  const _ActiveCampaignForm({required this.producer});

  final Producer producer;

  @override
  ConsumerState<_ActiveCampaignForm> createState() => _ActiveCampaignFormState();
}

class _ActiveCampaignFormState extends ConsumerState<_ActiveCampaignForm> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _targetController = TextEditingController(text: '50');
  final _basePriceController = TextEditingController(text: '200');
  final _discountPriceController = TextEditingController(text: '180');
  final _thresholdController = TextEditingController(text: '25');
  final _deliveryController =
      TextEditingController(text: 'Cumartesi - Somuncu Baba Otoparkı');

  ProductCategory _category = ProductCategory.tarimUrunleri;
  String _unit = 'KG';
  String _emoji = '🍑';

  @override
  void dispose() {
    _productNameController.dispose();
    _targetController.dispose();
    _basePriceController.dispose();
    _discountPriceController.dispose();
    _thresholdController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final target = double.parse(_targetController.text.replaceAll(',', '.'));
    final basePrice = double.parse(_basePriceController.text.replaceAll(',', '.'));
    final discountPrice =
        double.parse(_discountPriceController.text.replaceAll(',', '.'));
    final threshold = double.parse(_thresholdController.text.replaceAll(',', '.'));

    ref.read(ecosystemActionsProvider).publishActiveCampaign(
          producer: widget.producer,
          productName: _productNameController.text.trim(),
          emoji: _emoji,
          category: _category,
          basePrice: basePrice,
          discountedPrice: discountPrice,
          discountThresholdKg: threshold,
          targetVolume: target,
          unit: _unit,
          deliveryInfo: _deliveryController.text.trim(),
        );

    _productNameController.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text(
          'Kampanya yayınlandı ve tüketici akışına eklendi! 🎉',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fieldLabel('Ürün Adı'),
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(hintText: 'Örn. Gün Kurusu Kayısı'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ürün adı gerekli' : null,
            ),
            const SizedBox(height: 14),
            fieldLabel('Simge'),
            _EmojiPicker(
              selected: _emoji,
              onSelected: (e) => setState(() => _emoji = e),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('Birim'),
                      DropdownButtonFormField<String>(
                        value: _unit,
                        items: const ['KG', 'Adet']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _unit = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('Kategori'),
                      DropdownButtonFormField<ProductCategory>(
                        value: _category,
                        items: ProductCategory.values
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c.shortLabel, style: const TextStyle(fontSize: 12.5))))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('Hedef Miktar'),
                      TextFormField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '50'),
                        validator: numberValidator,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('İndirim Eşiği'),
                      TextFormField(
                        controller: _thresholdController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '25'),
                        validator: numberValidator,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('Normal Fiyat (TL)'),
                      TextFormField(
                        controller: _basePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '200'),
                        validator: numberValidator,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('İndirimli Fiyat (TL)'),
                      TextFormField(
                        controller: _discountPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '180'),
                        validator: numberValidator,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            fieldLabel('Teslimat Noktası'),
            TextFormField(
              controller: _deliveryController,
              decoration: const InputDecoration(hintText: 'Örn. Cumartesi - Belediye Standı'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Teslimat bilgisi gerekli' : null,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Kampanyayı Yayınla'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kEmojiOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final emoji = kEmojiOptions[index];
          final isSelected = emoji == selected;
          return GestureDetector(
            onTap: () => onSelected(emoji),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withOpacity(0.14)
                    : AppColors.backgroundCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : AppColors.divider,
                ),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          );
        },
      ),
    );
  }
}

/// =============================================================================
/// TAB 2 — İLÇEDEN GELEN TALEPLER (İSTEK HAVUZU)
/// =============================================================================
class _RequestPoolTab extends ConsumerWidget {
  const _RequestPoolTab({required this.producer});

  final Producer producer;

  void _accept(BuildContext context, WidgetRef ref, ConsumerRequest request) {
    ref.read(ecosystemActionsProvider).acceptConsumerRequest(
          producer: producer,
          request: request,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '"${request.title}" için kampanya açıldı, tüketiciye bildirim gönderildi!',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(consumerRequestsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _SectionHeader(
          emoji: '📥',
          title: 'İlçeden Gelen Talepler',
          subtitle:
              'Tüketicilerin bıraktığı istekleri buradan görüp anında '
              'karşılayabilirsiniz. "Ben Üretebilirim" dediğiniz an istek '
              'havuzdan kalkar ve aktif bir kampanyaya dönüşür.',
        ),
        const SizedBox(height: 18),
        if (requests.isEmpty)
          _EmptyState(text: 'Şu anda bekleyen bir istek yok. Havuz temiz! 🌿')
        else
          ...requests.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ConsumerRequestCard(
                  request: r,
                  onAccept: () => _accept(context, ref, r),
                ),
              )),
      ],
    );
  }
}

class _ConsumerRequestCard extends StatelessWidget {
  const _ConsumerRequestCard({required this.request, required this.onAccept});

  final ConsumerRequest request;
  final VoidCallback onAccept;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.category.shortLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.description,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                _timeAgo(request.createdAt),
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.handshake_rounded, size: 18),
              label: const Text('Ben Üretebilirim'),
            ),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Shared display widgets
/// -----------------------------------------------------------------------
class _ProducerProfileCard extends StatelessWidget {
  const _ProducerProfileCard({required this.producer});

  final Producer producer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(producer.avatarEmoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producer.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  producer.village,
                  style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: AppColors.starGold),
                    const SizedBox(width: 4),
                    Text(
                      producer.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    if (producer.isHighlighted) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentOchre,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Öne Çıkan Üretici',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignOverviewTile extends StatelessWidget {
  const _CampaignOverviewTile({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(campaign.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  campaign.productName,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
              if (campaign.bornFromRequest)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.volunteer_activism_rounded,
                      size: 16, color: AppColors.accentOchre),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: campaign.isDiscountActive
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  campaign.isDiscountActive ? 'İndirim Aktif' : 'Toplanıyor',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: campaign.isDiscountActive
                        ? AppColors.success
                        : AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: campaign.progress,
              minHeight: 7,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${campaign.collectedVolume.toStringAsFixed(0)} / '
            '${campaign.targetVolume.toStringAsFixed(0)} ${campaign.unit} • '
            '${campaign.currentPrice.toStringAsFixed(0)} TL/${campaign.unit}',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OrderLogisticsTile extends ConsumerWidget {
  const _OrderLogisticsTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Text(order.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.productName} • ${order.quantity.toStringAsFixed(0)} ${order.unit}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  order.stage.label,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: order.stage.isFinal
                ? null
                : () => ref.read(ordersProvider.notifier).advanceDeliveryStage(order.id),
            child: Text(order.stage.isFinal ? 'Tamamlandı' : 'Simüle Et'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}
