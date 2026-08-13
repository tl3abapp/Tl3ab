import 'package:flutter/material.dart';
import 'package:padel_connect/theme/app_theme.dart';
import 'package:padel_connect/widgets/court_photo.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    required this.title,
    required this.area,
    required this.time,
    this.scheduleLabel,
    required this.players,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.primaryLabel = 'Join',
    this.secondaryLabel,
    this.badge = 'PRIVATE MATCH',
    this.statusLabel,
    this.actionEnabled = true,
    this.highlighted = false,
    this.accentColor,
    this.surfaceColor,
    this.borderColor,
    this.hostName,
    this.joinedNames,
    this.courtPhotoData,
    this.onTap,
    this.onMenuTap,
    super.key,
  });

  final String title;
  final String area;
  final String time;
  final String? scheduleLabel;
  final String players;
  final String badge;
  final String? primaryLabel;
  final String? secondaryLabel;
  final String? statusLabel;
  final bool actionEnabled;
  final bool highlighted;
  final Color? accentColor;
  final Color? surfaceColor;
  final Color? borderColor;
  final String? hostName;
  final String? joinedNames;
  final String? courtPhotoData;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final accent =
        accentColor ??
        (highlighted ? const Color(0xFF9A6512) : AppColors.green);
    final cardColor =
        surfaceColor ??
        (highlighted ? const Color(0xFFFFFBEB) : AppColors.card);
    final strokeColor =
        borderColor ??
        (highlighted ? const Color(0xFFF2C94C) : AppColors.stroke);
    final courtImage = CourtPhoto.imageProvider(courtPhotoData);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: strokeColor),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1F17).withValues(alpha: .06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (courtImage != null) ...[
              CourtPhoto.fromProvider(imageProvider: courtImage),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Game options',
                  visualDensity: VisualDensity.compact,
                  onPressed: onMenuTap,
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: AppColors.muted.withValues(alpha: .8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(Icons.location_on_outlined, area, accent),
                _infoChip(Icons.access_time, time, accent),
                if (scheduleLabel != null && scheduleLabel!.trim().isNotEmpty)
                  _infoChip(
                    Icons.event_repeat_outlined,
                    scheduleLabel!,
                    accent,
                  ),
                _infoChip(Icons.groups_2_outlined, players, accent),
                if (hostName != null && hostName!.trim().isNotEmpty)
                  _infoChip(Icons.person_outline, 'Host: $hostName', accent),
                if (joinedNames != null && joinedNames!.trim().isNotEmpty)
                  _infoChip(
                    Icons.how_to_reg_outlined,
                    'Joined: $joinedNames',
                    accent,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (statusLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel!,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                const Spacer(),
                if (onSecondaryAction != null && secondaryLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: onSecondaryAction,
                      child: Text(secondaryLabel!),
                    ),
                  ),
                if (onPrimaryAction != null && primaryLabel != null)
                  ElevatedButton(
                    onPressed: actionEnabled ? onPrimaryAction : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text(primaryLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accentColor),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
