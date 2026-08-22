import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:apex_hires/core/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  // High-quality recruitment / professional life images
  static const List<_CarouselImage> _images = [
    _CarouselImage(
      url:
          'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=1200&q=80',
      caption: 'Find Your Dream Job',
    ),
    _CarouselImage(
      url:
          'https://images.unsplash.com/photo-1560472355-536de3962603?w=1200&q=80',
      caption: 'Build Your Profile',
    ),
    _CarouselImage(
      url:
          'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=1200&q=80',
      caption: 'Connect with Recruiters',
    ),
    _CarouselImage(
      url:
          'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&q=80',
      caption: 'Grow Your Career',
    ),
    _CarouselImage(
      url:
          'https://images.unsplash.com/photo-1553877522-43269d4ea984?w=1200&q=80',
      caption: 'Smart Recruitment',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Fade-in animation for overlay content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Auto-scroll every 4 seconds
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _images.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Full-screen image carousel ───
          PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: _images[index].url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.darkText,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.darkText,
                  child: const Icon(Icons.work_rounded,
                      color: Colors.white54, size: 64),
                ),
              );
            },
          ),

          // ─── Dark gradient overlays ───
          // Bottom gradient (main content area)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.70,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                    Colors.black87,
                    Colors.black,
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Top gradient (status bar readability)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── Carousel indicators (top area) ───
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Main content (bottom) ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated caption
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _images[_currentPage].caption,
                          key: ValueKey(_currentPage),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Smart recruitment platform for\njob seekers and recruiters.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withAlpha(200),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Create Account button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/role_selection');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            shadowColor:
                                AppColors.primary.withAlpha(100),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sign In button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/login');
                          },
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: Colors.white.withAlpha(100),
                            ),
                          ),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withAlpha(230),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselImage {
  final String url;
  final String caption;

  const _CarouselImage({required this.url, required this.caption});
}
