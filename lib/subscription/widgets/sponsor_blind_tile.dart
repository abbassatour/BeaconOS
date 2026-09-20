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
          color: AppTheme.deepSlate,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.iceBlue.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.volunteer_activism_rounded, color: AppTheme.iceBlue, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sponsor a Blind User',
                    style: TextStyle(
                      color: AppTheme.iceBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pay it forward. Gift unlimited AI spatial vision to someone in need.',
                    style: TextStyle(
                      color: AppTheme.pureWhite,
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