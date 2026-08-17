import 'package:flutter/material.dart';
import 'package:padel_connect/app_language.dart';
import 'package:padel_connect/pages/chat_thread_page.dart';
import 'package:padel_connect/pages/create_game_page.dart';
import 'package:padel_connect/theme/app_theme.dart';
import 'package:padel_connect/widgets/brand_logo.dart';
import 'package:padel_connect/widgets/court_photo.dart';
import 'package:padel_connect/widgets/game_card.dart';
import 'package:padel_connect/widgets/user_avatar.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.controller,
    required this.onOpenSearch,
    required this.onOpenNotifications,
    super.key,
  });

  final dynamic controller;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenNotifications;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  dynamic get controller => widget.controller;
  VoidCallback get onOpenSearch => widget.onOpenSearch;
  VoidCallback get onOpenNotifications => widget.onOpenNotifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.syncFromApi();
    });
  }

  String _inviteLinkForMatch(dynamic match) {
    try {
      final link = controller.inviteLinkForMatch(match).toString().trim();
      if (link.isNotEmpty) {
        return link;
      }
    } catch (_) {
      // Older controller builds may not expose the helper yet.
    }
    return match?.inviteLink?.toString().trim() ?? '';
  }

  Rect _sharePositionOrigin(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.localToGlobal(Offset.zero) & renderObject.size;
    }

    final overlayObject = Overlay.maybeOf(context)?.context.findRenderObject();
    if (overlayObject is RenderBox && overlayObject.hasSize) {
      final center = overlayObject.localToGlobal(
        overlayObject.size.center(Offset.zero),
      );
      return Rect.fromCenter(center: center, width: 1, height: 1);
    }

    return const Rect.fromLTWH(0, 0, 1, 1);
  }

  Future<void> _shareInvite(BuildContext context, String text) async {
    await Share.share(text, sharePositionOrigin: _sharePositionOrigin(context));
  }

  @override
  Widget build(BuildContext context) {
    final userName = (controller.currentUser?.name ?? 'Player').toString();
    final games = (controller.nearbyMatches as List).take(4).toList();
    final myGames = (controller.myHostedMatches as List).take(3).toList();
    final nearbyPlayers = (controller.nearbyPlayersCount as int?) ?? 0;
    final unread =
        (controller.unreadInviteNotificationsCount as int?) ??
        (controller.unreadNotificationsCount as int?) ??
        0;
    final languageCode = controller.generalSettings.languageCode.toString();
    final appTitle = brandTitleForLanguage(languageCode);
    String tr(String english, String arabic) =>
        appText(languageCode, english, arabic);
    String playersLabel(int joined, int max) => appIsArabic(languageCode)
        ? '$joined/$max لاعبين'
        : '$joined/$max players';
    String nearbyPlayersLabel(int count) => appIsArabic(languageCode)
        ? '$count لاعبين قريبين'
        : '$count players nearby';
    String alertsLabel(int count) => count > 0
        ? (appIsArabic(languageCode)
              ? '$count تنبيهات جديدة'
              : '$count new alerts')
        : tr('No alerts', 'لا توجد تنبيهات');
    String actionText(String value) {
      switch (value.toLowerCase()) {
        case 'manage':
          return tr('Manage', 'إدارة');
        case 'request':
          return tr('Request', 'طلب');
        case 'join':
          return tr('Join', 'انضم');
        case 'leave':
          return tr('Leave', 'خروج');
        default:
          return value;
      }
    }

    return SafeArea(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FBF9), AppColors.bg],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => controller.syncFromApi(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              Row(
                children: [
                  const BrandIconTile(size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appTitle,
                      textDirection: brandTextDirectionForLanguage(
                        languageCode,
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamilyFallback: isArabicLanguage(languageCode)
                            ? brandArabicFontFallback
                            : brandLatinFontFallback,
                      ),
                    ),
                  ),
                  _actionIconButton(icon: Icons.search, onTap: onOpenSearch),
                  const SizedBox(width: 6),
                  _notificationButton(unread),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A7A47), Color(0xFF0C5737)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: .26),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appIsArabic(languageCode)
                          ? 'هلا $userName 👋'
                          : 'Hi $userName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(
                        'Ready for your next match?',
                        'جاهز لمباراتك القادمة؟',
                      ),
                      style: const TextStyle(
                        color: Color(0xFFD8F3E7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _heroChip(
                          icon: Icons.location_on_outlined,
                          label: controller.selectedArea.toString(),
                        ),
                        _heroChip(
                          icon: Icons.groups_2_outlined,
                          label: nearbyPlayersLabel(nearbyPlayers),
                        ),
                        _heroChip(
                          icon: Icons.notifications_active_outlined,
                          label: alertsLabel(unread),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.sports_score_outlined,
                    size: 19,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('My Games', 'مبارياتي'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  if (myGames.isNotEmpty)
                    Text(
                      '${myGames.length}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (myGames.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    tr(
                      'Create a game to see it here.',
                      'أنشئ مباراة عشان تظهر هنا.',
                    ),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                )
              else
                ...myGames.map((match) {
                  final matchId = match.id.toString();
                  final pendingCount =
                      (controller.pendingRequestsCountForMatch(matchId)
                          as int?) ??
                      0;
                  final inviteLink = _inviteLinkForMatch(match);

                  return GameCard(
                    highlighted: true,
                    isScheduled: match.isScheduledGame == true,
                    title: (match.title ?? 'Game').toString(),
                    area: (match.area ?? '-').toString(),
                    time: _formatDate(match.startTime as DateTime),
                    scheduleLabel: match.isScheduledGame == true
                        ? tr('Play scheduling', 'جدولة اللعب')
                        : null,
                    players: playersLabel(
                      match.joinedPlayers as int,
                      match.maxPlayers as int,
                    ),
                    hostName: match.hostName.toString(),
                    joinedNames: match.sideSummary.toString(),
                    courtPhotoData: match.courtPhotoData?.toString(),
                    badge: appIsArabic(languageCode)
                        ? (match.isScheduledGame == true
                              ? 'لعبة مجدولة'
                              : ((controller
                                            .targetScopeLabelForMatch(matchId)
                                            .toString() ==
                                        'Public')
                                    ? 'مباراتي العامة'
                                    : 'مباراتي'))
                        : (match.isScheduledGame == true
                              ? 'MY SCHEDULED GAME'
                              : '${(controller.targetScopeLabelForMatch(matchId).toString() == 'Public') ? 'MY PUBLIC' : 'MY'} GAME'),
                    statusLabel: pendingCount > 0
                        ? tr('$pendingCount pending', '$pendingCount بانتظارك')
                        : tr('Host', 'الهوست'),
                    primaryLabel: pendingCount > 0
                        ? tr('Requests', 'الطلبات')
                        : tr('Manage', 'إدارة'),
                    secondaryLabel: inviteLink.isEmpty
                        ? null
                        : tr('Share', 'مشاركة'),
                    onSecondaryAction: inviteLink.isEmpty
                        ? null
                        : () => _shareInvite(
                            context,
                            '${tr('Join my padel game:', 'انضم لمباراة البادل:')}\n$inviteLink',
                          ),
                    onMenuTap: () => _openRequestsDialog(context, matchId),
                    onTap: () => _openGameDetailsSheet(context, match),
                    onPrimaryAction: () =>
                        _openRequestsDialog(context, matchId),
                  );
                }),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 19,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('Games Near You', 'مباريات قريبة منك'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (games.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    tr(
                      'No games yet in this area.',
                      'ما فيه مباريات حالياً بهالمنطقة.',
                    ),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                )
              else
                ...games.map((match) {
                  final matchId = match.id.toString();
                  final isHost =
                      (controller.isHostOfMatch(matchId) as bool?) ?? false;
                  final pendingCount =
                      (controller.pendingRequestsCountForMatch(matchId)
                          as int?) ??
                      0;
                  final targetLabel =
                      (controller.targetScopeLabelForMatch(matchId)
                          as String?) ??
                      'Public';
                  final actionLabel = isHost
                      ? 'Manage'
                      : (controller.joinActionLabelForMatch(matchId)
                                as String?) ??
                            'Join';
                  final myStatus = controller
                      .myRequestStatusLabelForMatch(matchId)
                      ?.toString();
                  final targetBadge = targetLabel.toUpperCase();
                  final isPublicGame = targetLabel == 'Public';

                  return GameCard(
                    isScheduled: match.isScheduledGame == true,
                    title: (match.title ?? 'Game').toString(),
                    area: (match.area ?? '-').toString(),
                    time: _formatDate(match.startTime as DateTime),
                    scheduleLabel: match.isScheduledGame == true
                        ? tr('Play scheduling', 'جدولة اللعب')
                        : null,
                    players: playersLabel(
                      match.joinedPlayers as int,
                      match.maxPlayers as int,
                    ),
                    hostName: match.hostName.toString(),
                    joinedNames: match.sideSummary.toString(),
                    courtPhotoData: match.courtPhotoData?.toString(),
                    badge: appIsArabic(languageCode)
                        ? (match.isScheduledGame == true
                              ? 'لعبة مجدولة'
                              : (isPublicGame ? 'مباراة عامة' : 'مباراة'))
                        : (match.isScheduledGame == true
                              ? 'SCHEDULED GAME'
                              : (isPublicGame ? '$targetBadge GAME' : 'GAME')),
                    statusLabel: myStatus,
                    primaryLabel: actionText(actionLabel),
                    secondaryLabel: isHost && pendingCount > 0
                        ? tr(
                            'Requests ($pendingCount)',
                            'الطلبات ($pendingCount)',
                          )
                        : null,
                    onSecondaryAction: isHost && pendingCount > 0
                        ? () => _openRequestsDialog(context, matchId)
                        : null,
                    onMenuTap: isHost
                        ? () => _openRequestsDialog(context, matchId)
                        : null,
                    onTap: () => _openGameDetailsSheet(context, match),
                    onPrimaryAction: () async {
                      if (isHost) {
                        _openRequestsDialog(context, matchId);
                        return;
                      }
                      String? side;
                      if (actionLabel != 'Leave') {
                        side = await _pickJoinSide(context, match);
                        if (side == null) {
                          return;
                        }
                      }
                      final result = await controller.joinMatchFromFeed(
                        matchId,
                        preferredSide: side,
                      );
                      if (context.mounted) {
                        _showSnack(context, result.toString());
                      }
                    },
                  );
                }),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.flash_on_outlined,
                    size: 20,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tr('Quick Actions', 'إجراءات سريعة'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _quickActionTile(
                      icon: Icons.qr_code_rounded,
                      title: tr('Join with Link', 'انضم برابط'),
                      subtitle: tr('Paste invite URL', 'الصق رابط الدعوة'),
                      solid: false,
                      onTap: () => _openJoinCodeDialog(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickActionTile(
                      icon: Icons.add_circle_outline,
                      title: tr('Create Game', 'إنشاء مباراة'),
                      subtitle: tr(
                        'Circle / Friends / Public',
                        'السيركل / الأصدقاء / عام',
                      ),
                      solid: true,
                      onTap: () async {
                        final dynamic created = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateGamePage(controller: controller),
                          ),
                        );
                        if (created != null && context.mounted) {
                          try {
                            final match = created.match;
                            final inviteLink = _inviteLinkForMatch(match);
                            _showCreatedGameActions(
                              context,
                              match.title.toString(),
                              inviteLink,
                            );
                          } catch (_) {
                            _showCreatedGameActions(
                              context,
                              tr('Game created', 'تم إنشاء المباراة'),
                              '',
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatedGameActions(
    BuildContext context,
    String title,
    String inviteLink,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title created.'),
          action: inviteLink.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Share',
                  onPressed: () {
                    _shareInvite(context, 'Join my padel game:\n$inviteLink');
                  },
                ),
        ),
      );
  }

  Future<String?> _pickJoinSide(BuildContext context, dynamic match) {
    final leftCount = (match.playersOnSide('left') as List).length;
    final rightCount = (match.playersOnSide('right') as List).length;

    return showModalBottomSheet<String>(
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
                const Text(
                  'Pick your side',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Each side can have 2 players.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: leftCount >= 2
                            ? null
                            : () => Navigator.of(context).pop('left'),
                        icon: const Icon(Icons.keyboard_double_arrow_left),
                        label: Text('Left ($leftCount/2)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: rightCount >= 2
                            ? null
                            : () => Navigator.of(context).pop('right'),
                        icon: const Icon(Icons.keyboard_double_arrow_right),
                        label: Text('Right ($rightCount/2)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openGameDetailsSheet(BuildContext context, dynamic match) {
    final joined = (match.joinedParticipants as List).toList();
    final inviteLink = _inviteLinkForMatch(match);
    final matchId = match.id.toString();
    final canChat = (controller.canChatInMatch(matchId) as bool?) ?? false;
    final languageCode = controller.generalSettings.languageCode.toString();
    String tr(String english, String arabic) =>
        appText(languageCode, english, arabic);
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
                title: Text(tr('Hosted by', 'الهوست')),
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
              if (match.isScheduledGame == true) ...[
                const SizedBox(height: 8),
                Text(
                  tr('Play scheduling', 'جدولة اللعب'),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ..._timeOptionTiles(context, match, tr),
              ],
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
                  label: Text(tr('Open game chat', 'افتح محادثة المباراة')),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                tr(
                  'Joined players (${joined.length})',
                  'اللاعبون المنضمون (${joined.length})',
                ),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (joined.isEmpty)
                Text(
                  tr(
                    'No players accepted yet.',
                    'لم يتم قبول أي لاعب حتى الآن.',
                  ),
                  style: const TextStyle(color: AppColors.muted),
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
                  onPressed: () => _shareInvite(
                    context,
                    '${tr('Join my padel game:', 'انضم لمباراة البادل:')}\n$inviteLink',
                  ),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(tr('Share invite', 'مشاركة الدعوة')),
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

  List<Widget> _timeOptionTiles(
    BuildContext context,
    dynamic match,
    String Function(String english, String arabic) tr,
  ) {
    final currentUserId = controller.currentUser?.id?.toString();
    final options = (match.timeOptions as List).toList();
    final totalVotes = options.fold<int>(
      0,
      (sum, option) => sum + (option.voteCount as int),
    );

    return options
        .map<Widget>((option) {
          final voteCount = option.voteCount as int;
          final percent = totalVotes == 0
              ? 0
              : ((voteCount / totalVotes) * 100).round();
          final selected =
              currentUserId != null &&
              (option.voterIds as List).contains(currentUserId);

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: selected
                  ? AppColors.green.withValues(alpha: .14)
                  : AppColors.stroke.withValues(alpha: .4),
              child: Icon(
                selected ? Icons.check_circle : Icons.schedule_outlined,
                color: selected ? AppColors.green : AppColors.muted,
              ),
            ),
            title: Text(_formatDate(option.startTime as DateTime)),
            subtitle: Text(
              tr(
                '$voteCount votes • $percent%',
                '$voteCount أصوات • $percent%',
              ),
            ),
            trailing: TextButton(
              onPressed: selected
                  ? null
                  : () async {
                      final result = await controller.voteForMatchTimeOption(
                        match.id.toString(),
                        option.id.toString(),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      _showSnack(context, result.toString());
                      Navigator.of(context).pop();
                    },
              child: Text(
                selected ? tr('Selected', 'مختار') : tr('Choose', 'اختيار'),
              ),
            ),
          );
        })
        .toList(growable: false);
  }

  Widget _actionIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: AppColors.stroke),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _notificationButton(int unread) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _actionIconButton(
          icon: Icons.notifications_none,
          onTap: onOpenNotifications,
        ),
        if (unread > 0)
          Positioned(
            right: -1,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFB42318),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unread > 99 ? '99+' : unread.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _heroChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFE5F8EF)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE5F8EF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool solid,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: solid
              ? const LinearGradient(
                  colors: [AppColors.lime, Color(0xFF94E73D)],
                )
              : null,
          color: solid ? null : Colors.white,
          border: Border.all(
            color: solid ? const Color(0xFF94E73D) : AppColors.stroke,
          ),
          boxShadow: [
            if (solid)
              BoxShadow(
                color: AppColors.lime.withValues(alpha: .35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: solid ? AppColors.dark : AppColors.green,
              size: 21,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: solid ? AppColors.dark : AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: solid
                    ? AppColors.dark.withValues(alpha: .72)
                    : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openJoinCodeDialog(BuildContext context) async {
    final linkController = TextEditingController();
    var selectedSide = 'left';
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Join by Link'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: linkController,
                    decoration: const InputDecoration(
                      hintText: 'https://www.til3b.com/join?m=...&code=...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    selected: {selectedSide},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setDialogState(() => selectedSide = selection.first);
                    },
                    segments: const [
                      ButtonSegment<String>(
                        value: 'left',
                        icon: Icon(Icons.keyboard_double_arrow_left),
                        label: Text('Left'),
                      ),
                      ButtonSegment<String>(
                        value: 'right',
                        icon: Icon(Icons.keyboard_double_arrow_right),
                        label: Text('Right'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final result = await controller.requestPrivateJoinByLink(
                      inviteLink: linkController.text,
                      preferredSide: selectedSide,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      _showSnack(context, result.toString());
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
    linkController.dispose();
  }

  void _openRequestsDialog(BuildContext context, String matchId) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final requests = (controller.allRequestsForMatch(matchId) as List)
                .toList();
            final match = controller.matchById(matchId);
            final inviteLink = _inviteLinkForMatch(match);

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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (inviteLink.isNotEmpty)
                        IconButton(
                          tooltip: 'Share',
                          onPressed: () {
                            _shareInvite(
                              context,
                              'Join my padel game:\n$inviteLink',
                            );
                          },
                          icon: const Icon(Icons.share_outlined),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openInviteMoreDialog(context, matchId),
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text('Invite more players'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: inviteLink.isEmpty
                              ? null
                              : () {
                                  _shareInvite(
                                    context,
                                    'Join my padel game:\n$inviteLink',
                                  );
                                },
                          icon: const Icon(Icons.ios_share_outlined),
                          label: const Text('Share link'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Players / Requests',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
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
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.requesterName.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      status,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (status == 'pending' || status == 'onHold')
                                IconButton(
                                  onPressed: () async {
                                    final approved =
                                        await controller.approveJoinRequest(
                                              request.id.toString(),
                                            )
                                            as bool;
                                    if (!context.mounted) {
                                      return;
                                    }
                                    _showSnack(
                                      context,
                                      approved ? 'Approved.' : 'Game is full.',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.green,
                                  ),
                                ),
                              if (status == 'pending')
                                IconButton(
                                  onPressed: () async {
                                    await controller.holdJoinRequest(
                                      request.id.toString(),
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    _showSnack(context, 'Moved to hold.');
                                  },
                                  icon: const Icon(
                                    Icons.pause_circle_outline,
                                    color: Color(0xFF7A5C00),
                                  ),
                                ),
                              if (status == 'pending' ||
                                  status == 'onHold' ||
                                  status == 'full')
                                IconButton(
                                  onPressed: () async {
                                    await controller.rejectJoinRequest(
                                      request.id.toString(),
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    _showSnack(
                                      context,
                                      'Updated. Player sees game full.',
                                    );
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
                            final selected = selectedIds.contains(userId);
                            return CheckboxListTile(
                              value: selected,
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
