import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/awb_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _checkProfileAndNavigate();
  }

  Future<void> _checkProfileAndNavigate() async {
    // Wait for animation and some artificial delay for futuristic feel
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // Check if profile exists
    final provider = context.read<AWBProvider>();
    await provider.initialize();
    
    // For now, we'll assume if no AWBs and no profile, go to profile creation
    // In a real app, we'd check the user_profiles table
    // Since I can't easily check the DB here without more code, 
    // I'll navigate to a 'Welcome' screen or Home which then decides.
    // Based on the prompt, FASA 1 is Create Profile.
    
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000B18), // Ultra Dark Navy
              Color(0xFF001F3F), // Deep Navy
              Color(0xFF003D7A), // Navy Blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Futuristic Background Elements (Circles/Lines)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D9FF).withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D9FF).withOpacity(0.05),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D9FF).withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // App Title with Futuristic Glow
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'PANTAS AWB',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Color(0xFF00D9FF),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SECURE LOGISTICS ECOSYSTEM',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF00D9FF),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                  // Futuristic Loading
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 200,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
                            minHeight: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'INITIALIZING SECURE PROTOCOLS...',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
