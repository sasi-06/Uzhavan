import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StarRatingWidget extends StatefulWidget {
  const StarRatingWidget({
    super.key,
    this.rating = 0,
    this.starCount = 5,
    this.starSize = 36,
    this.interactive = false,
    this.onRated,
    this.color = AppColors.starGold,
  });

  final double rating;
  final int starCount;
  final double starSize;
  final bool interactive;
  final ValueChanged<int>? onRated;
  final Color color;

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  int _hovered = 0;

  @override
  Widget build(BuildContext context) {
    final displayRating = _hovered > 0 ? _hovered.toDouble() : widget.rating;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, (i) {
        final filled = (i + 1) <= displayRating;
        final half = !filled && (i + 0.5) <= displayRating;

        return GestureDetector(
          onTap: widget.interactive
              ? () {
                  setState(() => _hovered = i + 1);
                  widget.onRated?.call(i + 1);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled
                  ? Icons.star_rounded
                  : half
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              color: (filled || half) ? widget.color : AppColors.divider,
              size: widget.starSize,
            ),
          ),
        );
      }),
    );
  }
}
