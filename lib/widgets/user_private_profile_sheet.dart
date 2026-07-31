import 'package:flutter/material.dart';
import 'package:padel_connect/pages/chat_thread_page.dart';
import 'package:padel_connect/theme/app_theme.dart';
import 'package:padel_connect/widgets/user_avatar.dart';

Future<void> showUserPrivateProfileSheet({
  required BuildContext context,
  required dynamic controller,
  required dynamic user,
}) {
  final userId = user.id.toString();
  int? draftRating = controller.privateRatingForUser(userId) as int?;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final hasRating = draftRating != null;
          final ratingValue = draftRating ?? 5;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        radius: 26,
                        name: user.name.toString(),
                        photoData: user.photoData?.toString(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '@${user.handle}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final threadId = await controller
                            .openOrCreateDirectThread(
                              userId,
                              user.name.toString(),
                            );
                        if (!context.mounted) {
                          return;
                        }
                        if (threadId.toString().isEmpty) {
                          return;
                        }
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatThreadPage(
                              controller: controller,
                              threadId: threadId.toString(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text('Message ${user.name}'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your private rating',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Only you can see this. It helps filter players when you send games.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ratingChip(
                        label: 'Beginner',
                        selected: hasRating && ratingValue <= 3,
                        onTap: () => setSheetState(() => draftRating = 2),
                      ),
                      _ratingChip(
                        label: 'Intermediate',
                        selected:
                            hasRating && ratingValue >= 4 && ratingValue <= 6,
                        onTap: () => setSheetState(() => draftRating = 5),
                      ),
                      _ratingChip(
                        label: 'Pro',
                        selected: hasRating && ratingValue >= 7,
                        onTap: () => setSheetState(() => draftRating = 8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        hasRating ? '$ratingValue/10' : 'Not rated',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      if (hasRating)
                        Text(
                          _ratingLabel(ratingValue),
                          style: const TextStyle(color: AppColors.green),
                        ),
                    ],
                  ),
                  Slider(
                    value: ratingValue.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: hasRating
                        ? '${_ratingLabel(ratingValue)} $ratingValue/10'
                        : 'Not rated',
                    onChanged: (value) {
                      setSheetState(() => draftRating = value.round());
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          await controller.updatePrivateRatingForUser(
                            userId,
                            null,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          await controller.updatePrivateRatingForUser(
                            userId,
                            draftRating,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _ratingChip({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return ChoiceChip(
    selected: selected,
    onSelected: (_) => onTap(),
    label: Text(label),
  );
}

String _ratingLabel(int rating) {
  if (rating <= 3) {
    return 'Beginner';
  }
  if (rating <= 6) {
    return 'Intermediate';
  }
  return 'Pro';
}
