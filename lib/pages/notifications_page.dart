import 'package:flutter/material.dart';
import 'package:padel_connect/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({required this.controller, super.key});

  final dynamic controller;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _markedVisibleRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _markedVisibleRead) {
        return;
      }
      _markedVisibleRead = true;
      widget.controller.markAllNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final items = (widget.controller.notifications as List).toList();
        final pendingRequests = <dynamic>[];
        for (final match in (widget.controller.myHostedMatches as List)) {
          for (final request
              in (widget.controller.pendingRequestsForMatch(match.id.toString())
                  as List)) {
            pendingRequests.add((match: match, request: request));
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.notifications_outlined),
                SizedBox(width: 8),
                Text('Notifications'),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  await widget.controller.refreshNotifications();
                  await widget.controller.markAllNotificationsRead();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: items.isEmpty && pendingRequests.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
                  itemBuilder: (context, index) {
                    if (index < pendingRequests.length) {
                      final entry = pendingRequests[index];
                      final match = entry.match;
                      final request = entry.request;
                      final requestedAt = request.requestedAt as DateTime;

                      return Card(
                        color: const Color(0xFFFFFBEB),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFE8A3),
                            child: Icon(
                              Icons.how_to_reg_outlined,
                              color: Color(0xFF7A5C00),
                            ),
                          ),
                          title: Text('${request.requesterName} wants to join'),
                          subtitle: Text(
                            '${match.title}\n${requestedAt.day}/${requestedAt.month}/${requestedAt.year} ${_two(requestedAt.hour)}:${_two(requestedAt.minute)}',
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Approve',
                                onPressed: () async {
                                  final approved =
                                      await widget.controller
                                              .approveJoinRequest(
                                                request.id.toString(),
                                              )
                                          as bool;
                                  if (context.mounted) {
                                    _showSnack(
                                      context,
                                      approved ? 'Approved.' : 'Game is full.',
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.green,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Reject',
                                onPressed: () async {
                                  await widget.controller.rejectJoinRequest(
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
                    }

                    final notificationIndex = index - pendingRequests.length;
                    final item = items[notificationIndex];
                    final createdAt = item.createdAt as DateTime;
                    final isRead = item.isRead == true;

                    return Card(
                      color: isRead ? Colors.white : const Color(0xFFEFFAF4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isRead
                              ? const Color(0xFFE8EEF0)
                              : const Color(0xFFC9F2DC),
                          child: Icon(
                            _iconForType(item.type.toString()),
                            color: AppColors.green,
                          ),
                        ),
                        title: Text(item.title.toString()),
                        subtitle: Text(
                          '${item.body}\n${createdAt.day}/${createdAt.month}/${createdAt.year} ${_two(createdAt.hour)}:${_two(createdAt.minute)}',
                        ),
                        isThreeLine: true,
                        trailing: isRead
                            ? const Icon(Icons.done_all, color: AppColors.muted)
                            : const Icon(Icons.fiber_manual_record, size: 12),
                        onTap: () async {
                          if (!isRead) {
                            await widget.controller.markNotificationRead(
                              item.id.toString(),
                            );
                          }
                          await widget.controller.syncFromApi();
                          if (!context.mounted) {
                            return;
                          }
                          _openNotificationGame(context, item);
                        },
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemCount: pendingRequests.length + items.length,
                ),
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'invitation':
        return Icons.sports_tennis;
      case 'join_request':
        return Icons.how_to_reg_outlined;
      case 'request_approved':
        return Icons.check_circle_outline;
      case 'request_rejected':
        return Icons.cancel_outlined;
      case 'request_hold':
        return Icons.pause_circle_outline;
      case 'match_reminder':
        return Icons.alarm;
      case 'match_time_changed':
        return Icons.edit_calendar_outlined;
      case 'player_replaced':
        return Icons.swap_horiz_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openNotificationGame(BuildContext context, dynamic notification) {
    final match = widget.controller.matchFromNotification(notification);
    if (match == null) {
      _showSnack(context, 'Game is not available anymore.');
      return;
    }

    final matchId = match.id.toString();
    final isHost = (widget.controller.isHostOfMatch(matchId) as bool?) ?? false;
    final actionLabel =
        (widget.controller.joinActionLabelForMatch(matchId) as String?) ??
        'Join';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.title.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${match.area} • ${match.courtName}'),
                Text('${match.joinedPlayers}/${match.maxPlayers} players'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isHost
                        ? null
                        : () async {
                            final message = await widget.controller
                                .joinMatchFromFeed(matchId);
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop();
                            _showSnack(context, message.toString());
                          },
                    icon: Icon(isHost ? Icons.verified_user : Icons.login),
                    label: Text(isHost ? 'You host this game' : actionLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
