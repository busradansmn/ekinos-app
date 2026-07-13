import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'models.dart';
import 'providers.dart';
import 'main_flow_screens.dart';

/// =============================================================================
/// CONSUMER FEED
/// =============================================================================
class ConsumerFeedScreen extends ConsumerStatefulWidget {
  const ConsumerFeedScreen({super.key});

  @override
  ConsumerState<ConsumerFeedScreen> createState() => _ConsumerFeedScreenState();
}

class _ConsumerFeedScreenState extends ConsumerState<ConsumerFeedScreen> {
  AppNotification? _visibleBanner;

  void _showBanner(AppNotification notification) {
    setState(() => _visibleBanner = notification);
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_visibleBanner?.id == notification.id) {
        setState(() => _visibleBanner = null);
      }
    });
  }

  void _dismissBanner() {
    setState(() => _visibleBanner = null);
  }

  void _openCampaignFromNotification(String? campaignId) {
    _dismissBanner();
    if (campaignId == null) return;
    final campaign = ref.read(campaignsProvider.notifier).byId(campaignId);
    if (campaign != null) {
      _openOrderSheet(campaign);
    }
  }

  void _openOrderSheet(Campaign campaign) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderSheet(campaign: campaign),
    );
  }

  void _openRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RequestFormSheet(),
    ).then((submitted) {
      if (submitted == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text(
              'İsteğiniz bölgedeki üreticilere iletildi! 🌱',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    });
  }

  void _openNotificationHistory() {
    ref.read(unseenNotificationCountProvider.notifier).state = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationHistorySheet(),
    );
  }

  void _openProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProfileSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for freshly-fired smart notifications and surface them as a
    // beautiful overlay banner right at the top of the feed.
    ref.listen<AppNotification?>(latestNotificationProvider, (previous, next) {
      if (next != null) {
        _showBanner(next);
        // Reset the one-shot slot so it doesn't refire on rebuild.
        Future.microtask(
          () => ref.read(latestNotificationProvider.notifier).state = null,
        );
      }
    });

    final campaigns = ref.watch(campaignsProvider);
    final categoryFilter = ref.watch(categoryFilterProvider);
    final favorites = ref.watch(favoritesProvider);

    final filteredCampaigns = categoryFilter == null
        ? campaigns
        : campaigns.where((c) => c.category == categoryFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _FeedHeader(
                    onBellTap: _openNotificationHistory,
                    onProfileTap: _openProfileSheet,
                    onSwitchRole: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: _HarvestCalendarStrip()),
                SliverToBoxAdapter(
                  child: _RequestPoolButton(onTap: _openRequestSheet),
                ),
                SliverToBoxAdapter(
                  child: _CategoryFilterRow(selected: categoryFilter),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
                if (filteredCampaigns.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyFeedState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final campaign = filteredCampaigns[index];
                          final isFav =
                              favorites.contains(campaign.producerId);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _CampaignCard(
                              campaign: campaign,
                              isFavorite: isFav,
                              onToggleFavorite: () => ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(campaign.producerId),
                              onOrder: () => _openOrderSheet(campaign),
                            ),
                          );
                        },
                        childCount: filteredCampaigns.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Smart notification overlay banner
          if (_visibleBanner != null)
            _NotificationBanner(
              notification: _visibleBanner!,
              onTap: () =>
                  _openCampaignFromNotification(_visibleBanner!.campaignId),
              onDismiss: _dismissBanner,
            ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Premium Header — wide-tracked EKINOS wordmark, interactive notification
/// bell with a live unseen badge, and a fake circular user profile icon.
/// -----------------------------------------------------------------------
class _FeedHeader extends ConsumerWidget {
  const _FeedHeader({
    required this.onBellTap,
    required this.onProfileTap,
    required this.onSwitchRole,
  });

  final VoidCallback onBellTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSwitchRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unseenCount = ref.watch(unseenNotificationCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Text(
            'EKINOS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 5.5,
              color: AppColors.primaryGreen,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Rolü Değiştir',
            icon: const Icon(Icons.swap_horiz_rounded, size: 22),
            color: AppColors.textSecondary,
            onPressed: onSwitchRole,
          ),
          _NotificationBellButton(count: unseenCount, onTap: onBellTap),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen,
                border: Border.all(color: AppColors.accentOchre, width: 2),
              ),
              alignment: Alignment.center,
              child: const Text('🙂', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded,
                size: 24, color: AppColors.textPrimary),
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.backgroundCream, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Notification History Sheet — everything the bell has ever fired.
/// -----------------------------------------------------------------------
class _NotificationHistorySheet extends ConsumerWidget {
  const _NotificationHistorySheet();

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.harvestForecast:
        return Icons.calendar_month_rounded;
      case NotificationType.campaignLaunch:
        return Icons.campaign_rounded;
      case NotificationType.requestAccepted:
        return Icons.volunteer_activism_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return _SheetScaffold(
      title: 'Bildirimler',
      child: notifications.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Henüz bildiriminiz yok.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                ),
              ),
            )
          : Column(
              children: notifications
                  .map(
                    (n) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(_iconFor(n.type),
                                size: 17, color: AppColors.primaryGreen),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              n.message,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Fake Profile Sheet — decorative, tappable user identity summary.
/// -----------------------------------------------------------------------
class _ProfileSheet extends ConsumerWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final orders = ref.watch(ordersProvider);

    return _SheetScaffold(
      title: 'Profilim',
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreen,
              border: Border.all(color: AppColors.accentOchre, width: 3),
            ),
            alignment: Alignment.center,
            child: const Text('🙂', style: TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 14),
          const Text(
            'Ali Veli',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text('Darende, Malatya',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ProfileStat(label: 'Siparişler', value: '${orders.length}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileStat(
                    label: 'Takip Edilen Üretici', value: '${favorites.length}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Shared bottom-sheet chrome (grab handle + title + scrollable content).
class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Bu kategoride henüz aktif kampanya yok.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Smart Notification Overlay Banner
/// -----------------------------------------------------------------------
class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.harvestForecast:
        return Icons.calendar_month_rounded;
      case NotificationType.campaignLaunch:
        return Icons.campaign_rounded;
      case NotificationType.requestAccepted:
        return Icons.volunteer_activism_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -1.0, end: 0.0),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value * -20),
              child: Opacity(opacity: (1 + value).clamp(0.0, 1.0), child: child),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accentOchre,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(_icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          notification.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70, size: 18),
                        onPressed: onDismiss,
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Production / Harvest Calendar — horizontally scrollable timeline.
/// Tapping any card (especially a future month) simulates subscribing to
/// a season-tracking reminder for that harvest.
/// -----------------------------------------------------------------------
class _HarvestCalendarStrip extends ConsumerWidget {
  const _HarvestCalendarStrip();

  void _handleTap(BuildContext context, WidgetRef ref, HarvestEntry e) {
    final bool nowTracking =
        ref.read(trackedHarvestProvider.notifier).toggle(e.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: nowTracking ? AppColors.primaryGreen : AppColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          nowTracking
              ? '🔔 ${e.monthLabel} ayı "${e.productName}" hasadı için takip başlatıldı!'
              : 'Takip iptal edildi.',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(harvestCalendarProvider);
    final tracked = ref.watch(trackedHarvestProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded,
                  size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text(
                'Üretim / Hasat Takvimi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final e = entries[index];
                final bool isTracked = tracked.contains(e.id);
                return GestureDetector(
                  onTap: () => _handleTap(context, ref, e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 150,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isTracked ? AppColors.primaryGreen : AppColors.divider,
                        width: isTracked ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentOchre.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                e.monthLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentOchre,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              isTracked
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_none_rounded,
                              size: 15,
                              color: isTracked
                                  ? AppColors.primaryGreen
                                  : AppColors.textSecondary.withOpacity(0.5),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${e.emoji} ${e.productName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.producerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// İstek Havuzu Button — full-width minimalist cream card. Opens the
/// immersive request form sheet.
/// -----------------------------------------------------------------------
class _RequestPoolButton extends StatelessWidget {
  const _RequestPoolButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.accentOchre.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🔍', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'İlçede bulamadığınız bir yöresel ürün mü var? İstek Bırakın',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.accentOchre),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Request Form Sheet — Title, description, category. Submitting drops a
/// new ConsumerRequest into the shared İstek Havuzu.
/// -----------------------------------------------------------------------
class _RequestFormSheet extends ConsumerStatefulWidget {
  const _RequestFormSheet();

  @override
  ConsumerState<_RequestFormSheet> createState() => _RequestFormSheetState();
}

class _RequestFormSheetState extends ConsumerState<_RequestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ProductCategory _category = ProductCategory.tarimUrunleri;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(ecosystemActionsProvider).submitConsumerRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'İstek Bırakın',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Aradığınız yöresel ürünü yazın, bölgedeki üreticiler '
                  'bu isteği görüp karşılayabilir.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),
                _label('Başlık'),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'Örn. Erişte yapan var mı?'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
                ),
                const SizedBox(height: 14),
                _label('Açıklama'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Miktar, tercih ettiğiniz teslimat günü vb. detaylar...',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Açıklama gerekli' : null,
                ),
                const SizedBox(height: 14),
                _label('Kategori'),
                SegmentedButton<ProductCategory>(
                  segments: [
                    ButtonSegment(
                      value: ProductCategory.tarimUrunleri,
                      label: Text(ProductCategory.tarimUrunleri.shortLabel,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: ProductCategory.elEmegiYoresel,
                      label: Text(ProductCategory.elEmegiYoresel.shortLabel,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {_category},
                  onSelectionChanged: (s) => setState(() => _category = s.first),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith((states) {
                      return states.contains(MaterialState.selected)
                          ? AppColors.primaryGreen
                          : AppColors.cardWhite;
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith((states) {
                      return states.contains(MaterialState.selected)
                          ? Colors.white
                          : AppColors.textSecondary;
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('İsteği Gönder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
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
}

/// -----------------------------------------------------------------------
/// Category Filter Chips
/// -----------------------------------------------------------------------
class _CategoryFilterRow extends ConsumerWidget {
  const _CategoryFilterRow({required this.selected});

  final ProductCategory? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(
            label: 'Tümü',
            selected: selected == null,
            onTap: () => ref.read(categoryFilterProvider.notifier).state = null,
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: ProductCategory.tarimUrunleri.label,
            selected: selected == ProductCategory.tarimUrunleri,
            onTap: () => ref.read(categoryFilterProvider.notifier).state =
                ProductCategory.tarimUrunleri,
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: ProductCategory.elEmegiYoresel.label,
            selected: selected == ProductCategory.elEmegiYoresel,
            onTap: () => ref.read(categoryFilterProvider.notifier).state =
                ProductCategory.elEmegiYoresel,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Campaign Card — rating, highlight badge, dynamic price-drop engine
/// -----------------------------------------------------------------------
class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOrder,
  });

  final Campaign campaign;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = campaign.isHighlightedProducer;
    final bool discountActive = campaign.isDiscountActive;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? AppColors.accentOchre
              : AppColors.divider,
          width: highlighted ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(campaign.emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              campaign.producerName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.star_rounded,
                              size: 15, color: AppColors.starGold),
                          const SizedBox(width: 2),
                          Text(
                            campaign.producerRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFavorite ? AppColors.starGold : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (highlighted || campaign.bornFromRequest) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (highlighted)
                    _Badge(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Öne Çıkan Üretici',
                      color: AppColors.accentOchre,
                    ),
                  if (campaign.bornFromRequest)
                    _Badge(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'İstek Havuzundan Doğdu',
                      color: AppColors.primaryGreen,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // ----- Dynamic Price Drop Engine -----
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Mevcut: ',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  '${campaign.basePrice.toStringAsFixed(0)} TL',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: discountActive
                        ? AppColors.textSecondary
                        : AppColors.primaryGreen,
                    decoration:
                        discountActive ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${campaign.discountThresholdKg.toStringAsFixed(0)} '
                    '${campaign.unit} geçilirse: ${campaign.discountedPrice.toStringAsFixed(0)} TL!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: discountActive ? FontWeight.w800 : FontWeight.w500,
                      color: discountActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: campaign.progress,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  discountActive ? AppColors.success : AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${campaign.collectedVolume.toStringAsFixed(0)} / '
                  '${campaign.targetVolume.toStringAsFixed(0)} ${campaign.unit} toplandı',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Icon(Icons.place_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    campaign.deliveryInfo,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onOrder,
                child: const Text('Sipariş Ver'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Order Sheet — quantity picker, then confirms and pushes the receipt
/// -----------------------------------------------------------------------
class _OrderSheet extends ConsumerStatefulWidget {
  const _OrderSheet({required this.campaign});

  final Campaign campaign;

  @override
  ConsumerState<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends ConsumerState<_OrderSheet> {
  double _quantity = 5;

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignsProvider);
    final campaign = campaigns.firstWhere(
      (c) => c.id == widget.campaign.id,
      orElse: () => widget.campaign,
    );
    final total = campaign.currentPrice * _quantity;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: AppColors.backgroundCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(campaign.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.productName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        campaign.producerName,
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Text(
                    'Miktar',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  _QtyButton(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      setState(() {
                        _quantity = (_quantity - 5).clamp(5, 1000);
                      });
                    },
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${_quantity.toStringAsFixed(0)} ${campaign.unit}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add_rounded,
                    onTap: () {
                      setState(() {
                        _quantity = (_quantity + 5).clamp(5, 1000);
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Birim Fiyat: ${campaign.currentPrice.toStringAsFixed(0)} TL'
                  '${campaign.isDiscountActive ? " (indirimli)" : ""}',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  'Toplam: ${total.toStringAsFixed(0)} TL',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final order = Order(
                  id: 'o_${DateTime.now().microsecondsSinceEpoch}',
                  campaignId: campaign.id,
                  productName: campaign.productName,
                  emoji: campaign.emoji,
                  producerName: campaign.producerName,
                  quantity: _quantity,
                  unit: campaign.unit,
                  totalPrice: total,
                );
                ref.read(ordersProvider.notifier).addOrder(order);
                ref
                    .read(campaignsProvider.notifier)
                    .addOrderVolume(campaign.id, _quantity);

                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderReceiptScreen(orderId: order.id),
                  ),
                );
              },
              child: const Text('Siparişi Onayla'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.primaryGreen),
      ),
    );
  }
}

/// =============================================================================
/// ORDER RECEIPT — Local Logistics Stepper with manual "Simüle Et" control
/// =============================================================================
class OrderReceiptScreen extends ConsumerWidget {
  const OrderReceiptScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final order = orders.firstWhere((o) => o.id == orderId);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(title: const Text('Sipariş Fişi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.emoji, style: const TextStyle(fontSize: 34)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.productName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                order.producerName,
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _receiptRow('Miktar', '${order.quantity.toStringAsFixed(0)} ${order.unit}'),
                    const SizedBox(height: 10),
                    _receiptRow('Sipariş No', '#${order.id.substring(order.id.length - 6)}'),
                    const SizedBox(height: 10),
                    _receiptRow(
                      'Toplam Tutar',
                      '${order.totalPrice.toStringAsFixed(0)} TL',
                      emphasize: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Yerel Lojistik Takibi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _LogisticsStepper(stage: order.stage),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: order.stage.isFinal
                    ? null
                    : () => ref
                        .read(ordersProvider.notifier)
                        .advanceDeliveryStage(order.id),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  order.stage.isFinal ? 'Teslimat Tamamlandı' : 'Simüle Et',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 17 : 14,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            color: emphasize ? AppColors.primaryGreen : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _LogisticsStepper extends StatelessWidget {
  const _LogisticsStepper({required this.stage});

  final DeliveryStage stage;

  @override
  Widget build(BuildContext context) {
    final stages = DeliveryStage.values;

    return Column(
      children: List.generate(stages.length, (index) {
        final s = stages[index];
        final bool isDone = index < stage.stepIndex;
        final bool isActive = index == stage.stepIndex;
        final bool isLast = index == stages.length - 1;

        final Color circleColor = (isDone || isActive)
            ? AppColors.primaryGreen
            : AppColors.divider;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : isActive
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isDone ? AppColors.primaryGreen : AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 4),
                  child: Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: (isDone || isActive)
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
