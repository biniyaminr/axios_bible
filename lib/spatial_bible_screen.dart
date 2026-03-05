import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main.dart'; // Import BibleProvider

class SpatialBibleScreen extends StatefulWidget {
  const SpatialBibleScreen({super.key});

  @override
  State<SpatialBibleScreen> createState() => _SpatialBibleScreenState();
}

class _SpatialBibleScreenState extends State<SpatialBibleScreen> {
  late PageController _pageController;
  double _page = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.25);
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_pageController.hasClients && _pageController.page != null) {
      if (_page != _pageController.page) {
        setState(() {
          _page = _pageController.page!;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure OLED black
      body: Consumer<BibleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 1.5));
          }
          if (provider.error != null) {
            return Center(child: Text(provider.error!, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w300)));
          }

          final verses = provider.verses.entries.toList();
          if (verses.isEmpty) {
            return const Center(child: Text('No verses found yet.', style: TextStyle(color: Colors.white24, letterSpacing: 2)));
          }

          return GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 300) {
                provider.previousChapter();
                if (_pageController.hasClients) _pageController.jumpToPage(0);
              } else if (details.primaryVelocity! < -300) {
                provider.nextChapter();
                if (_pageController.hasClients) _pageController.jumpToPage(0);
              }
            },
            child: Stack(
              children: [
                // Top aura (Spatial Void depth)
                Positioned(
                  top: -150,
                  left: -50,
                  right: -50,
                  child: IgnorePointer(
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.02),
                            blurRadius: 150,
                            spreadRadius: 80,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Spatial verses Pages
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: verses.length,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    final double distance = (_page - index).abs();
                    
                    // Zero-gravity physics
                    final double scale = (1 - (distance * 0.3)).clamp(0.4, 1.0);
                    final double opacity = (1 - (distance * 0.5)).clamp(0.0, 1.0);
                    final double rotateX = (index - _page) * 0.15; 

                    final isActive = distance < 0.5;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002) // subtle perspective depth
                        ..rotateX(rotateX)
                        ..scale(scale),
                      child: Opacity(
                        opacity: opacity,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: isActive ? 1.0 : 0.0,
                                  child: Text(
                                    '${provider.selectedBook} ${provider.selectedChapter}:${verse.key}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 10,
                                      letterSpacing: 4,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isActive ? 16 : 0),
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    if (!isActive) {
                                      return LinearGradient(
                                        colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.3)],
                                      ).createShader(bounds);
                                    }
                                    return const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700), // Gold
                                        Color(0xFFE6E8FA), // Silver/Platinum
                                        Color(0xFFDAA520), // Goldenrod
                                        Color(0xFF8A9A5B), // Subtle Bioluminescent Green/Blue
                                      ],
                                      stops: [0.0, 0.4, 0.7, 1.0],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    verse.value,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isActive ? 28 : 20,
                                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w300,
                                      height: 1.6,
                                      color: Colors.white, 
                                      shadows: isActive
                                          ? [
                                              Shadow(
                                                color: const Color(0xFFFFD700).withOpacity(0.25),
                                                blurRadius: 20,
                                              ),
                                              Shadow(
                                                color: const Color(0xFFE6E8FA).withOpacity(0.15),
                                                blurRadius: 40,
                                              ),
                                            ]
                                          : [],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Navigation Aura at the bottom
                Positioned(
                  bottom: -100,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.06),
                            blurRadius: 100,
                            spreadRadius: 40,
                          ),
                          BoxShadow(
                            color: const Color(0xFF8A9A5B).withOpacity(0.04),
                            blurRadius: 150,
                            spreadRadius: 80,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
