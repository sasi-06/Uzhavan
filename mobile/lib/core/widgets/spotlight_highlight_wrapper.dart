import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../theme/accessibility_theme.dart';

/// Animated luminous border wrapper for active spotlight item being read aloud by Screen Reader.
class SpotlightHighlightWrapper extends StatefulWidget {
  const SpotlightHighlightWrapper({
    super.key,
    required this.spotlightIndex,
    required this.child,
  });

  final int spotlightIndex;
  final Widget child;

  @override
  State<SpotlightHighlightWrapper> createState() => _SpotlightHighlightWrapperState();
}

class _SpotlightHighlightWrapperState extends State<SpotlightHighlightWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _borderPulse;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _borderPulse = Tween<double>(begin: 2.0, end: 5.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccessibilityProvider>();
    final isHighlighted = acc.spotlightActive && acc.activeSpotlightIndex == widget.spotlightIndex;

    if (!isHighlighted) return widget.child;

    final primaryColor = AccessibilityTheme.getPrimaryColor(context);

    return AnimatedBuilder(
      animation: _borderPulse,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor,
              width: _borderPulse.value,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withAlpha(120),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              widget.child,
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
