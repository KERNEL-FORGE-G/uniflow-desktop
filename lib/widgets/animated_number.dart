import 'package:flutter/material.dart';

/// Anime l'apparition d'un chiffre en le faisant défiler de 0 → [value] sur
/// [duration]. Utilisé dans les StatCards du dashboard pour rendre les
/// métriques plus vivantes à l'affichage initial.
///
/// Fonctionne avec n'importe quelle chaîne : si [value] se termine par un
/// suffixe non numérique (« % », « /20 »…), il est isolé et réapposé.
class AnimatedNumber extends StatefulWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// Valeur numérique extraite (null si le texte n'est pas un nombre).
  double? _numericValue;

  /// Suffixe conservé après le nombre (ex: « % », «  étudiants »).
  String _suffix = '';

  /// Préfixe conservé avant le nombre (ex: « + »).
  String _prefix = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _parseValue(widget.value);
    _animation = Tween<double>(begin: 0, end: _numericValue ?? 0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  void _parseValue(String raw) {
    // Retire les séparateurs de milliers et remplace la virgule par un point
    final cleaned = raw.replaceAll('\u202f', '').replaceAll(' ', '').replaceAll(',', '.');

    // Cherche une suite de chiffres (avec point éventuel) n'importe où
    final match = RegExp(r'^([^0-9]*)([0-9]+(?:\.[0-9]+)?)(.*)$').firstMatch(cleaned);
    if (match != null) {
      _prefix = match.group(1) ?? '';
      _numericValue = double.tryParse(match.group(2) ?? '');
      _suffix = match.group(3) ?? '';
    }
  }

  @override
  void didUpdateWidget(AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final oldVal = _numericValue ?? 0;
      _parseValue(widget.value);
      _animation = Tween<double>(begin: oldVal, end: _numericValue ?? 0)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double v) {
    if (_numericValue == null) return widget.value;
    // Entier si la valeur cible est entière
    if (_numericValue == _numericValue!.floorToDouble()) {
      final intVal = v.round();
      // Séparateur de milliers (espace fine)
      final s = intVal.abs().toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202f');
        buf.write(s[i]);
      }
      return '$_prefix${intVal < 0 ? '-' : ''}${buf.toString()}$_suffix';
    }
    return '$_prefix${v.toStringAsFixed(1)}$_suffix';
  }

  @override
  Widget build(BuildContext context) {
    if (_numericValue == null) {
      return Text(widget.value, style: widget.style);
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Text(_format(_animation.value), style: widget.style),
    );
  }
}

/// Variante slide-fade : fait monter le widget depuis le bas + fade in.
/// Utile pour les cards qui chargent en cascade.
class SlideFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const SlideFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends State<SlideFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}
