import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InsightCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? accentColor;

  const InsightCard({
    super.key,
    required this.text,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = (accentColor ?? AppColors.accent).withValues(alpha: 0.8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.kCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: context.kTextSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
