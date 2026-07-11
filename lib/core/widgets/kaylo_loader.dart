import 'package:flutter/material.dart';
import 'kaylo_logo.dart';

class KayloLoader extends StatefulWidget {
  final double size;
  final bool isMono;
  final Color? monoColor;

  const KayloLoader({
    super.key,
    this.size = 48.0,
    this.isMono = false,
    this.monoColor,
  });

  @override
  State<KayloLoader> createState() => _KayloLoaderState();
}

class _KayloLoaderState extends State<KayloLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: KayloLogo(
              width: widget.size,
              isMono: widget.isMono,
              monoColor: widget.monoColor,
            ),
          ),
        );
      },
    );
  }
}
