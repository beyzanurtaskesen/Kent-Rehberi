import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'harita_sayfasi.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 1.0;
  @override
  void initState() {
    super.initState();
    // 2 saniye sonra animasyon başlasın
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _opacity = 0.0;
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan (harita)
          const HaritaSayfasi(),
          // Splash katmanı sabit kalır, sadece içeriği yavaşça kaybolur
          IgnorePointer(
            // Kullanıcı etkileşimini alttaki Harita'ya geçiriyoruz
            ignoring: _opacity == 0.0,
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              child: Stack(
                children: [
                  // Arka plan görseli
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("resimler/anaekran.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Blur efekti (sabitte kalır ama görünürlüğü azalır)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                    child: Container(color: Colors.black.withOpacity(0.1)),
                  ),
                  // Logo ve yazı
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset("resimler/logo.png",
                            width: 120, height: 120),
                        const SizedBox(height: 40),
                        const Text(
                          "Hoşgeldiniz...",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                            shadows: [
                              Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black54),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Küçük logo köşede
                  Positioned(
                    top: 245,
                    left: 160,
                    child: Image.asset(
                      "resimler/kirmizilogo.png",
                      width: 40,
                      height: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}