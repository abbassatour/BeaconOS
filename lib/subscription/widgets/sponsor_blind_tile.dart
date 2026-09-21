// lib/subscription/widgets/sponsor_blind_tile.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SponsorBlindTile extends StatelessWidget {
  const SponsorBlindTile({
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.softBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.carbonInk.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFFFFEDD5),
              child: Icon(
                Icons.volunteer_activism_rounded,
                color: AppTheme.terracotta,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sponsor a Blind User',
                    style: TextStyle(
                      color: AppTheme.carbonInk,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pay it forward. Gift unlimited AI spatial vision to someone in need.',
                    style: TextStyle(
                      color: AppTheme.mutedInk,
                      fontSize: 13,
                      height: 1.4,
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