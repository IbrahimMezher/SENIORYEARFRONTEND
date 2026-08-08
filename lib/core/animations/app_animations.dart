import 'package:flutter/material.dart';

mixin AppAnimationsMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {

  late AnimationController headerController;
  late AnimationController pulseController;
  late AnimationController staggerController;

  late Animation<double> headerFade;
  late Animation<double> headerScale;

  late Animation<double> pulse;

  late Animation<double> s1Fade;
  late Animation<Offset> s1Slide;
  late Animation<double> s2Fade;
  late Animation<Offset> s2Slide;
  late Animation<double> s3Fade;
  late Animation<Offset> s3Slide;
  late Animation<double> s4Fade;
  late Animation<Offset> s4Slide;
  late Animation<double> s5Fade;
  late Animation<Offset> s5Slide;
  late Animation<double> s6Fade;
  late Animation<Offset> s6Slide;

  void initAnimations() {
    headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: headerController, curve: Curves.easeOut),
    );
    headerScale = Tween<double>(begin: 1.06, end: 1.0).animate(
      CurvedAnimation(parent: headerController, curve: Curves.easeOut),
    );

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    s1Fade  = _sFade(0.0,  0.3);
    s1Slide = _sSlide(0.0,  0.3);
    s2Fade  = _sFade(0.15, 0.45);
    s2Slide = _sSlide(0.15, 0.45);
    s3Fade  = _sFade(0.3,  0.6);
    s3Slide = _sSlide(0.3,  0.6);
    s4Fade  = _sFade(0.45, 0.75);
    s4Slide = _sSlide(0.45, 0.75);
    s5Fade  = _sFade(0.6,  0.9);
    s5Slide = _sSlide(0.6,  0.9);
    s6Fade  = _sFade(0.75, 1.0);
    s6Slide = _sSlide(0.75, 1.0);
  }

  void startAnimations() {
    headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) staggerController.forward();
    });
  }

  void disposeAnimations() {
    headerController.dispose();
    pulseController.dispose();
    staggerController.dispose();
  }

  Animation<double> _sFade(double start, double end) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: staggerController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );

  Animation<Offset> _sSlide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(
          parent: staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  Widget animatedSection({
    required int index,
    required Widget child,
  }) {
    final fades  = [s1Fade, s2Fade, s3Fade, s4Fade, s5Fade, s6Fade];
    final slides = [s1Slide, s2Slide, s3Slide, s4Slide, s5Slide, s6Slide];
    final i = (index - 1).clamp(0, 5);
    return FadeTransition(
      opacity: fades[i],
      child: SlideTransition(
        position: slides[i],
        child: child,
      ),
    );
  }
}
