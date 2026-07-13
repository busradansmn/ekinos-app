import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';
import 'consumer_feed_screen.dart';
import 'producer_dashboard_screen.dart';

/// =============================================================================
/// SPLASH SCREEN
/// =============================================================================
/// Wide-kerning wordmark fade-in, ~2.5 seconds on screen, then hands off to
/// the onboarding flow.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 104,
                  height: 104,
                  child: CustomPaint(painter: _WheatMarkPainter()),
                ),
                const SizedBox(height: 28),
                Text(
                  'EKINOS',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'YEREL TARIM, ORTAK GELECEK.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A minimalist, hand-drawn wheat-stalk brand mark.
class _WheatMarkPainter extends CustomPainter {
  const _WheatMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stemPaint = Paint()
      ..color = AppColors.primaryGreen
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint grainPaint = Paint()
      ..color = AppColors.accentOchre
      ..style = PaintingStyle.fill;

    final double centerX = size.width / 2;
    final double top = size.height * 0.08;
    final double bottom = size.height * 0.95;

    canvas.drawLine(
      Offset(centerX, top + 10),
      Offset(centerX, bottom),
      stemPaint,
    );

    const int pairCount = 5;
    final double usableHeight = bottom - top - 10;
    for (int i = 0; i < pairCount; i++) {
      final double t = i / (pairCount - 1);
      final double y = top + 10 + usableHeight * t;
      final double grainLength = size.width * (0.22 - t * 0.06);

      _drawGrain(
        canvas,
        grainPaint,
        origin: Offset(centerX, y),
        length: grainLength,
        angleDegrees: -35 - t * 10,
      );
      _drawGrain(
        canvas,
        grainPaint,
        origin: Offset(centerX, y),
        length: grainLength,
        angleDegrees: 180 + 35 + t * 10,
      );
    }

    final Path tip = Path()
      ..moveTo(centerX, top)
      ..quadraticBezierTo(
        centerX + size.width * 0.09,
        top + 14,
        centerX,
        top + 26,
      )
      ..quadraticBezierTo(
        centerX - size.width * 0.09,
        top + 14,
        centerX,
        top,
      )
      ..close();
    canvas.drawPath(tip, Paint()..color = AppColors.primaryGreen);
  }

  void _drawGrain(
    Canvas canvas,
    Paint paint, {
    required Offset origin,
    required double length,
    required double angleDegrees,
  }) {
    final double angle = angleDegrees * math.pi / 180;
    final Offset tip = Offset(
      origin.dx + length * math.cos(angle),
      origin.dy + length * math.sin(angle),
    );

    final Path grain = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(
        (origin.dx + tip.dx) / 2,
        (origin.dy + tip.dy) / 2 - 4,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        (origin.dx + tip.dx) / 2,
        (origin.dy + tip.dy) / 2 + 4,
        origin.dx,
        origin.dy,
      )
      ..close();

    canvas.drawPath(grain, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// =============================================================================
/// ONBOARDING — 3 immersive slides
/// =============================================================================
class _OnboardingSlide {
  final String emoji;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.description,
  });
}

const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    emoji: '🌾',
    title: 'Doğrudan Üretici',
    description:
        'Aracıları ortadan kaldırıyoruz. Darende topraklarının emeğini, '
        'hiçbir komisyon olmadan doğrudan üreticiden sofranıza taşıyoruz.',
  ),
  _OnboardingSlide(
    emoji: '🛒',
    title: 'Toplu Alım Gücü',
    description:
        'Mahallenizle veya sitenizle birleşin. Toplanan sipariş hacmi '
        'arttıkça fiyatlar otomatik olarak düşer, herkes kazanır.',
  ),
  _OnboardingSlide(
    emoji: '🚚',
    title: 'Güvenli Teslimat',
    description:
        'Üretici bahçelerinin konumu gizli kalır. Ürünlerinizi belirlenen '
        'resmi teslimat noktalarından güvenle, anlık takip ile teslim alın.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _pageValue = 0;

  int get _currentPage => _pageValue.round();
  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _pageValue = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToRoleSelection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  void _handleNextTap() {
    if (_isLastPage) {
      _goToRoleSelection();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildSkipRow(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _OnboardingSlideView(
                    slide: _slides[index],
                    pageValue: _pageValue,
                    index: index,
                  );
                },
              ),
            ),
            _buildDotIndicators(),
            const SizedBox(height: 32),
            _buildBottomControls(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipRow() {
    final double opacity = _isLastPage ? 0.0 : 1.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: opacity,
            child: IgnorePointer(
              ignoring: _isLastPage,
              child: TextButton(
                onPressed: _goToRoleSelection,
                child: const Text('Geç'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryGreen
                : AppColors.primaryGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_buildNextButton()],
      ),
    );
  }

  Widget _buildNextButton() {
    const double buttonHeight = 60;

    return GestureDetector(
      onTap: _handleNextTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: _isLastPage ? 176 : buttonHeight,
        height: buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(buttonHeight / 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isLastPage ? 0.0 : 1.0,
              child: SizedBox(
                width: buttonHeight,
                height: buttonHeight,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: (_currentPage + 1) / _slides.length,
                    ),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _isLastPage
                  ? const Text(
                      'BAŞLA',
                      key: ValueKey('start-label'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward_rounded,
                      key: ValueKey('arrow-icon'),
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({
    required this.slide,
    required this.pageValue,
    required this.index,
  });

  final _OnboardingSlide slide;
  final double pageValue;
  final int index;

  @override
  Widget build(BuildContext context) {
    final double distance = (pageValue - index).clamp(-1.0, 1.0).abs();
    final double opacity = (1 - distance).clamp(0.0, 1.0);
    final double scale = 0.92 + (1 - distance) * 0.08;

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  slide.emoji,
                  style: const TextStyle(fontSize: 56),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                slide.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =============================================================================
/// ROLE SELECTION — Alıcı Girişi / Üretici Girişi
/// =============================================================================
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const SizedBox(
                width: 84,
                height: 84,
                child: CustomPaint(painter: _WheatMarkPainter()),
              ),
              const SizedBox(height: 24),
              Text(
                'Nasıl Devam Etmek\nİstersiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'EKINOS ekosistemine hangi taraftan katılmak\n'
                'istediğinizi seçin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 2),
              _RoleCard(
                emoji: '🛍️',
                title: 'Alıcı Girişi',
                subtitle: 'Taze, yerel ürünleri keşfedin ve ön sipariş verin.',
                color: AppColors.primaryGreen,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const ConsumerFeedScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _RoleCard(
                emoji: '🌱',
                title: 'Üretici Girişi',
                subtitle: 'Hasat takviminizi paylaşın ve kampanya başlatın.',
                color: AppColors.accentOchre,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const ProducerDashboardScreen(),
                    ),
                  );
                },
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
