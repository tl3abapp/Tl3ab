import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padel_connect/pages/chat_thread_page.dart';
import 'package:padel_connect/theme/app_theme.dart';
import 'package:padel_connect/widgets/court_photo.dart';
import 'package:padel_connect/widgets/game_card.dart';
import 'package:padel_connect/widgets/user_avatar.dart';
import 'package:share_plus/share_plus.dart';

class MyGamesPage extends StatelessWidget {
  const MyGamesPage({required this.controller, super.key});

  final dynamic controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final games = (controller.myHostedMatches as List).toList();
        final history = (controller.myMatchHistory as List).toList();
        final syncing = (controller.syncing as bool?) ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Text('My Games (${games.length})'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: syncing ? null : () => controller.syncFromApi(),
                icon: syncing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => controller.syncFromApi(),
            child: games.isEmpty && history.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: const [
                      SizedBox(height: 120),
                      Icon(
                        Icons.sports_tennis_outlined,
                        size: 46,
                        color: AppColors.muted,
                      ),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'No games created yet.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                    children: [
                      if (games.isNotEmpty) ...[
                        const Text(
                          'Manage your active games',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...games.map((match) {
                          final matchId = match.id.toString();
                          final pendingCount =
                              (controller.pendingRequestsCountForMatch(matchId)
                                  as int?) ??
                              0;
                          final inviteLink = match.inviteLink?.toString() ?? '';

                          return GameCard(
                            highlighted: true,
                            title: (match.title ?? 'Game').toString(),
                            area: (match.area ?? '-').toString(),
                            time: _formatDate(match.startTime as DateTime),
                            players:
                                '${match.joinedPlayers}/${match.maxPlayers} players',
                            hostName: match.hostName.toString(),
                            joinedNames: match.sideSummary.toString(),
                            courtPhotoData: match.courtPhotoData?.toString(),
                            badge:
                                '${(controller.targetScopeLabelForMatch(matchId).toString() == 'Public') ? 'MY PUBLIC' : 'MY'} GAME',
                            statusLabel: pendingCount > 0
                                ? '$pendingCount pending'
                                : 'Host',
                            primaryLabel: pendingCount > 0
                                ? 'Requests'
                                : 'Manage',
                            secondaryLabel: inviteLink.isEmpty ? null : 'Share',
                            onSecondaryAction: inviteLink.isEmpty
                                ? null
                                : () => Share.share(
                                    'Join my padel game:\n$inviteLink',
                                  ),
                            onTap: () => _openGameDetailsSheet(context, match),
                            onMenuTap: () => _openManageSheet(context, matchId),
                            onPrimaryAction: () =>
                                _openManageSheet(context, matchId),
                          );
                        }),
                      ] else ...[
                        const Text(
                          'No active games',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Finished games move to your history.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                      if (history.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'History (${history.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...history.map((match) {
                          final matchId = match.id.toString();
                          return GameCard(
                            title: (match.title ?? 'Game').toString(),
                            area: (match.area ?? '-').toString(),
                            time: _formatDate(match.startTime as DateTime),
                            players:
                                '${match.joinedPlayers}/${match.maxPlayers} players',
                            hostName: match.hostName.toString(),
                            joinedNames: match.sideSummary.toString(),
                            courtPhotoData: match.courtPhotoData?.toString(),
                            badge:
                                '${(controller.targetScopeLabelForMatch(matchId).toString() == 'Public') ? 'PUBLIC ' : ''}HISTORY',
                            statusLabel:
                                (controller.isHostOfMatch(matchId) as bool?) ??
                                    false
                                ? 'Host'
                                : 'Played',
                            primaryLabel: null,
                            onTap: () => _openGameDetailsSheet(context, match),
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _openGameDetailsSheet(BuildContext context, dynamic match) {
    final joined = (match.joinedParticipants as List).toList();
    final inviteLink = match.inviteLink?.toString() ?? '';
    final matchId = match.id.toString();
    final canChat = (controller.canChatInMatch(matchId) as bool?) ?? false;
    final courtImage = CourtPhoto.imageProvider(
      match.courtPhotoData?.toString(),
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (courtImage != null) ...[
                CourtPhoto.fromProvider(
                  imageProvider: courtImage,
                  borderRadius: 20,
                ),
                const SizedBox(height: 14),
              ],
              Text(
                match.title.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: UserAvatar(
                  name: match.hostName.toString(),
                  photoData: match.hostPhotoData?.toString(),
                  fallbackIcon: Icons.person_outline,
                ),
                title: const Text('Hosted by'),
                subtitle: Text(match.hostName.toString()),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.location_on_outlined),
                ),
                title: Text(match.courtName.toString()),
                subtitle: Text(
                  '${match.area} • ${_formatDate(match.startTime as DateTime)}',
                ),
              ),
              if (canChat) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    final threadId = await controller.openOrCreateGameThread(
                      matchId,
                    );
                    if (!context.mounted) {
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
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Open game chat'),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Joined players (${joined.length})',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (joined.isEmpty)
                const Text(
                  'No players accepted yet.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                ...joined.map(
                  (player) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatar(
                      name: player.name.toString(),
                      photoData: player.photoData?.toString(),
                      fallbackIcon: Icons.how_to_reg_outlined,
                    ),
                    title: Text(player.name.toString()),
                    subtitle: Text(
                      '@${player.handle} • ${_sideLabel(player.side?.toString())}',
                    ),
                  ),
                ),
              if (inviteLink.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      Share.share('Join my padel game:\n$inviteLink'),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Share invite'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _sideLabel(String? side) {
    if (side == 'left') {
      return 'Left';
    }
    if (side == 'right') {
      return 'Right';
    }
    return 'No side';
  }

  void _openManageSheet(BuildContext context, String matchId) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final match = controller.matchById(matchId);
            final requests = (controller.allRequestsForMatch(matchId) as List)
                .toList();
            final inviteLink = match?.inviteLink?.toString() ?? '';

            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match?.title.toString() ?? 'Game',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Game options',
                        onSelected: (value) async {
                          if (value == 'private') {
                            final result = await controller
                                .makeHostedMatchPrivate(matchId);
                            if (context.mounted) {
                              _showSnack(context, result.toString());
                            }
                            return;
                          }

                          if (value == 'delete') {
                            if (!context.mounted) {
                              return;
                            }
                            final confirmed = await _confirmDelete(context);
                            if (confirmed != true) {
                              return;
                            }
                            final result = await controller.deleteHostedMatch(
                              matchId,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              _showSnack(context, result.toString());
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'private',
                            child: Text('Make private'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete game'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openInviteMoreDialog(context, matchId),
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text('Invite more'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: inviteLink.isEmpty
                              ? null
                              : () => Share.share(
                                  'Join my padel game:\n$inviteLink',
                                ),
                          icon: const Icon(Icons.ios_share_outlined),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: match == null
                              ? null
                              : () => _openEditGameDialog(context, match),
                          icon: const Icon(Icons.edit_calendar_outlined),
                          label: const Text('Edit time/photo'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: match == null
                              ? null
                              : () => _openReplacePlayerDialog(context, match),
                          icon: const Icon(Icons.swap_horiz_outlined),
                          label: const Text('Replace player'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Players / Requests',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  if (requests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No players joined yet.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  else
                    ...requests.map((request) {
                      final status = request.status.toString().split('.').last;
                      return Card(
                        child: ListTile(
                          title: Text(request.requesterName.toString()),
                          subtitle: Text(status),
                          trailing: Wrap(
                            spacing: 2,
                            children: [
                              if (status == 'pending' || status == 'onHold')
                                IconButton(
                                  tooltip: 'Approve',
                                  onPressed: () async {
                                    final approved =
                                        await controller.approveJoinRequest(
                                              request.id.toString(),
                                            )
                                            as bool;
                                    if (context.mounted) {
                                      _showSnack(
                                        context,
                                        approved
                                            ? 'Approved.'
                                            : 'Game is full.',
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.green,
                                  ),
                                ),
                              if (status == 'pending' ||
                                  status == 'onHold' ||
                                  status == 'full')
                                IconButton(
                                  tooltip: 'Reject',
                                  onPressed: () async {
                                    await controller.rejectJoinRequest(
                                      request.id.toString(),
                                    );
                                    if (context.mounted) {
                                      _showSnack(context, 'Rejected.');
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    color: Color(0xFF8A2B16),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openEditGameDialog(BuildContext context, dynamic match) async {
    var selectedDate = match.startTime as DateTime;
    var selectedTime = TimeOfDay.fromDateTime(selectedDate);
    var existingPhoto = match.courtPhotoData?.toString();
    Uint8List? pickedPhotoBytes;
    final courtController = TextEditingController(
      text: match.courtName?.toString() ?? 'Pending Court',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewPhoto = pickedPhotoBytes == null
                ? CourtPhoto.imageProvider(existingPhoto)
                : MemoryImage(pickedPhotoBytes!) as ImageProvider<Object>;

            return AlertDialog(
              title: const Text('Edit game'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: courtController,
                        decoration: const InputDecoration(
                          labelText: 'Court / booking name',
                          prefixIcon: Icon(Icons.stadium_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 1),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedTime = picked;
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      picked.hour,
                                      picked.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.access_time),
                              label: Text(selectedTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (previewPhoto != null) ...[
                        CourtPhoto.fromProvider(
                          imageProvider: previewPhoto,
                          borderRadius: 14,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final file = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 1600,
                                  imageQuality: 72,
                                );
                                if (file == null) {
                                  return;
                                }
                                final bytes = await file.readAsBytes();
                                setDialogState(() {
                                  pickedPhotoBytes = bytes;
                                });
                              },
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                              ),
                              label: const Text('Booking photo'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            tooltip: 'Remove photo',
                            onPressed: previewPhoto == null
                                ? null
                                : () {
                                    setDialogState(() {
                                      pickedPhotoBytes = null;
                                      existingPhoto = '';
                                    });
                                  },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final photoData = pickedPhotoBytes == null
                        ? existingPhoto
                        : base64Encode(pickedPhotoBytes!);
                    final result = await controller.updateHostedMatchDetails(
                      match.id.toString(),
                      startTime: selectedDate,
                      courtName: courtController.text,
                      courtPhotoData: photoData,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                    _showSnack(context, result.toString());
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    courtController.dispose();
  }

  Future<void> _openReplacePlayerDialog(
    BuildContext context,
    dynamic match,
  ) async {
    final matchId = match.id.toString();
    final joined = (match.joinedParticipants as List).toList();
    final candidates = (controller.inviteCandidatesForMatch(matchId) as List)
        .toList();
    String? removeUserId = joined.isEmpty
        ? null
        : joined.first.userId.toString();
    String? inviteUserId = candidates.isEmpty
        ? null
        : candidates.first.id.toString();
    var side = joined.isEmpty
        ? 'left'
        : joined.first.side?.toString() ?? 'left';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Replace player'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (joined.isEmpty || candidates.isEmpty)
                      Text(
                        joined.isEmpty
                            ? 'No joined players to replace yet.'
                            : 'No available players to invite.',
                        style: const TextStyle(color: AppColors.muted),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        initialValue: removeUserId,
                        decoration: const InputDecoration(
                          labelText: 'Remove joined player',
                        ),
                        items: joined
                            .map<DropdownMenuItem<String>>(
                              (player) => DropdownMenuItem<String>(
                                value: player.userId.toString(),
                                child: Text(player.name.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            removeUserId = value;
                            for (final player in joined) {
                              if (player.userId.toString() == value) {
                                side = player.side?.toString() ?? side;
                                break;
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: inviteUserId,
                        decoration: const InputDecoration(
                          labelText: 'Invite replacement',
                        ),
                        items: candidates
                            .map<DropdownMenuItem<String>>(
                              (user) => DropdownMenuItem<String>(
                                value: user.id.toString(),
                                child: Text(user.name.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => inviteUserId = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'left',
                            label: Text('Left'),
                            icon: Icon(Icons.keyboard_double_arrow_left),
                          ),
                          ButtonSegment(
                            value: 'right',
                            label: Text('Right'),
                            icon: Icon(Icons.keyboard_double_arrow_right),
                          ),
                        ],
                        selected: {side},
                        onSelectionChanged: (value) {
                          setDialogState(() => side = value.first);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: removeUserId == null || inviteUserId == null
                      ? null
                      : () async {
                          final result = await controller
                              .replaceJoinedPlayerWithInvite(
                                matchId,
                                removeUserId: removeUserId!,
                                inviteUserId: inviteUserId!,
                                side: side,
                              );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pop();
                          _showSnack(context, result.toString());
                        },
                  child: const Text('Replace'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openInviteMoreDialog(
    BuildContext context,
    String matchId,
  ) async {
    final selectedIds = <String>{};
    var ratingFilter = 'all';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final candidates =
                (controller.inviteCandidatesForMatch(matchId) as List)
                    .where((user) => _matchesRatingFilter(user, ratingFilter))
                    .toList();

            return AlertDialog(
              title: const Text('Invite more players'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ratingFilterBar(
                      selected: ratingFilter,
                      onSelected: (value) {
                        setDialogState(() => ratingFilter = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (candidates.isEmpty)
                      const Text(
                        'No new players available to invite right now.',
                        style: TextStyle(color: AppColors.muted),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: candidates.length,
                          itemBuilder: (context, index) {
                            final user = candidates[index];
                            final userId = user.id.toString();
                            return CheckboxListTile(
                              value: selectedIds.contains(userId),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedIds.add(userId);
                                  } else {
                                    selectedIds.remove(userId);
                                  }
                                });
                              },
                              title: Text(user.name.toString()),
                              subtitle: Text(
                                '@${user.handle}\n${controller.privateRatingLabelForUser(userId)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () async {
                          final result = await controller
                              .invitePlayersToHostedMatch(
                                matchId,
                                selectedIds.toList(growable: false),
                              );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pop();
                          _showSnack(context, result.toString());
                        },
                  child: const Text('Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete game?'),
        content: const Text(
          'This removes the game for you and invited players.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8A2B16),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  bool _matchesRatingFilter(dynamic user, String filter) {
    final rating = controller.privateRatingForUser(user.id.toString()) as int?;
    return switch (filter) {
      'beginner' => rating != null && rating <= 3,
      'intermediate' => rating != null && rating >= 4 && rating <= 6,
      'pro' => rating != null && rating >= 7,
      'unrated' => rating == null,
      _ => true,
    };
  }

  Widget _ratingFilterBar({
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ratingFilterChip('all', 'All', selected, onSelected),
        _ratingFilterChip('beginner', 'Beginner', selected, onSelected),
        _ratingFilterChip('intermediate', 'Intermediate', selected, onSelected),
        _ratingFilterChip('pro', 'Pro', selected, onSelected),
        _ratingFilterChip('unrated', 'Unrated', selected, onSelected),
      ],
    );
  }

  Widget _ratingFilterChip(
    String key,
    String label,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return ChoiceChip(
      selected: selected == key,
      label: Text(label),
      onSelected: (_) => onSelected(key),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _formatDate(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year}, $hour:$minute';
  }
}
