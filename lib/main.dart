import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:padel_connect/app_language.dart';
import 'package:padel_connect/api/padel_api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:padel_connect/pages/main_shell.dart';
import 'package:padel_connect/pages/splash_page.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padel_connect/padel_backend.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:padel_connect/theme/app_theme.dart';
import 'package:padel_connect/widgets/brand_logo.dart';
import 'package:padel_connect/widgets/user_avatar.dart';

void main() {
  runApp(const PadelConnectApp());
}

class PadelConnectApp extends StatefulWidget {
  const PadelConnectApp({super.key});

  @override
  State<PadelConnectApp> createState() => _PadelConnectAppState();
}

class _PadelConnectAppState extends State<PadelConnectApp> {
  final PadelAppController _controller = PadelAppController();

  @override
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PadelAppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final appTitle = brandTitleForLanguage(
            _controller.generalSettings.languageCode,
          );
          final languageCode = _controller.generalSettings.languageCode;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: appTitle,
            locale: appLocale(languageCode),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light(languageCode: languageCode),
            builder: (context, child) {
              return Directionality(
                textDirection: appDirection(languageCode),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: SplashPage(nextBuilder: (_) => const AppEntry()),
          );
        },
      ),
    );
  }
}

class PadelAppScope extends InheritedNotifier<PadelAppController> {
  const PadelAppScope({
    required PadelAppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static PadelAppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PadelAppScope>();
    if (scope == null || scope.notifier == null) {
      throw FlutterError('PadelAppScope is not available in this context.');
    }
    return scope.notifier!;
  }
}

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PadelAppScope.of(context);
    if (!controller.hasCurrentUser) {
      return const SignInScreen();
    }
    return MainShell(controller: controller);
  }
}

enum MatchVisibility { publicGame, privateGame }

enum SkillLevel { beginner, intermediate, advanced, mixed }

enum ActivityType { gameInvite, training, meetup, market }

enum JoinRequestStatus { pending, onHold, approved, rejected, full }

enum CircleRelationship { closeFriend, mutualFollow, followerOnly }

enum PlayerTag {
  favorite,
  competitive,
  friendly,
  reliable,
  backup,
  oftenAvailable,
}

enum InviteAudience { closeFriends, followBackOnly, custom }

enum GameTone { friendly, balanced, competitive }

enum CircuitSource { addedByMe, addedMe, mutual, allAppUsers }

enum SearchScope { users, games, posts }

enum MatchTargetScope { circle, friends, publicGame, selectedUsers }

enum InvitePermission { everyone, friendsOnly, circleOnly }

class PrivacySettings {
  const PrivacySettings({
    this.privateProfile = true,
    this.showEmailOnProfile = false,
    this.showPhoneOnProfile = false,
    this.showAreaOnProfile = true,
    this.allowDmFromEveryone = false,
    this.autoApproveCircleJoin = true,
    this.defaultInvitePermission = InvitePermission.friendsOnly,
  });

  final bool privateProfile;
  final bool showEmailOnProfile;
  final bool showPhoneOnProfile;
  final bool showAreaOnProfile;
  final bool allowDmFromEveryone;
  final bool autoApproveCircleJoin;
  final InvitePermission defaultInvitePermission;

  PrivacySettings copyWith({
    bool? privateProfile,
    bool? showEmailOnProfile,
    bool? showPhoneOnProfile,
    bool? showAreaOnProfile,
    bool? allowDmFromEveryone,
    bool? autoApproveCircleJoin,
    String? defaultInvitePermission,
  }) {
    return PrivacySettings(
      privateProfile: privateProfile ?? this.privateProfile,
      showEmailOnProfile: showEmailOnProfile ?? this.showEmailOnProfile,
      showPhoneOnProfile: showPhoneOnProfile ?? this.showPhoneOnProfile,
      showAreaOnProfile: showAreaOnProfile ?? this.showAreaOnProfile,
      allowDmFromEveryone: allowDmFromEveryone ?? this.allowDmFromEveryone,
      autoApproveCircleJoin:
          autoApproveCircleJoin ?? this.autoApproveCircleJoin,
      defaultInvitePermission:
          _invitePermissionFromKey(defaultInvitePermission) ??
          this.defaultInvitePermission,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privateProfile': privateProfile,
      'showEmailOnProfile': showEmailOnProfile,
      'showPhoneOnProfile': showPhoneOnProfile,
      'showAreaOnProfile': showAreaOnProfile,
      'allowDmFromEveryone': allowDmFromEveryone,
      'autoApproveCircleJoin': autoApproveCircleJoin,
      'defaultInvitePermission': _invitePermissionKey(defaultInvitePermission),
    };
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      privateProfile: json['privateProfile'] != false,
      showEmailOnProfile: json['showEmailOnProfile'] == true,
      showPhoneOnProfile: json['showPhoneOnProfile'] == true,
      showAreaOnProfile: json['showAreaOnProfile'] != false,
      allowDmFromEveryone: json['allowDmFromEveryone'] == true,
      autoApproveCircleJoin: json['autoApproveCircleJoin'] != false,
      defaultInvitePermission:
          _invitePermissionFromKey(
            json['defaultInvitePermission']?.toString(),
          ) ??
          InvitePermission.friendsOnly,
    );
  }
}

InvitePermission? _invitePermissionFromKey(String? key) {
  switch (key) {
    case 'everyone':
      return InvitePermission.everyone;
    case 'circleOnly':
      return InvitePermission.circleOnly;
    case 'friendsOnly':
      return InvitePermission.friendsOnly;
    default:
      return null;
  }
}

String _invitePermissionKey(InvitePermission value) {
  switch (value) {
    case InvitePermission.everyone:
      return 'everyone';
    case InvitePermission.friendsOnly:
      return 'friendsOnly';
    case InvitePermission.circleOnly:
      return 'circleOnly';
  }
}

class GeneralSettings {
  const GeneralSettings({
    this.pushInvites = true,
    this.pushChat = true,
    this.pushMatchUpdates = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.compactMode = false,
    this.languageCode = 'en',
  });

  final bool pushInvites;
  final bool pushChat;
  final bool pushMatchUpdates;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool compactMode;
  final String languageCode;

  GeneralSettings copyWith({
    bool? pushInvites,
    bool? pushChat,
    bool? pushMatchUpdates,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? compactMode,
    String? languageCode,
  }) {
    return GeneralSettings(
      pushInvites: pushInvites ?? this.pushInvites,
      pushChat: pushChat ?? this.pushChat,
      pushMatchUpdates: pushMatchUpdates ?? this.pushMatchUpdates,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      compactMode: compactMode ?? this.compactMode,
      languageCode: (languageCode == null || languageCode.isEmpty)
          ? this.languageCode
          : languageCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushInvites': pushInvites,
      'pushChat': pushChat,
      'pushMatchUpdates': pushMatchUpdates,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'compactMode': compactMode,
      'languageCode': languageCode,
    };
  }

  factory GeneralSettings.fromJson(Map<String, dynamic> json) {
    return GeneralSettings(
      pushInvites: json['pushInvites'] != false,
      pushChat: json['pushChat'] != false,
      pushMatchUpdates: json['pushMatchUpdates'] != false,
      soundEnabled: json['soundEnabled'] != false,
      vibrationEnabled: json['vibrationEnabled'] != false,
      compactMode: json['compactMode'] == true,
      languageCode: (json['languageCode'] ?? 'en').toString(),
    );
  }
}

class MatchTimeOption {
  const MatchTimeOption({
    required this.id,
    required this.startTime,
    this.voterIds = const [],
  });

  final String id;
  final DateTime startTime;
  final List<String> voterIds;

  int get voteCount => voterIds.length;

  MatchTimeOption copyWith({DateTime? startTime, List<String>? voterIds}) {
    return MatchTimeOption(
      id: id,
      startTime: startTime ?? this.startTime,
      voterIds: voterIds ?? this.voterIds,
    );
  }
}

class PadelMatch {
  PadelMatch({
    required this.id,
    required this.title,
    this.hostId = '',
    required this.hostName,
    this.hostPhotoData,
    required this.area,
    required this.courtName,
    this.courtPhotoData,
    required this.startTime,
    required this.distanceKm,
    required this.maxPlayers,
    required this.joinedPlayers,
    required this.skillLevel,
    required this.visibility,
    this.inviteCode,
    this.inviteLink,
    this.timeOptions = const [],
    this.participants = const [],
  });

  final String id;
  final String title;
  final String hostId;
  final String hostName;
  final String? hostPhotoData;
  final String area;
  final String courtName;
  final String? courtPhotoData;
  final DateTime startTime;
  final double distanceKm;
  final int maxPlayers;
  int joinedPlayers;
  final SkillLevel skillLevel;
  final MatchVisibility visibility;
  final String? inviteCode;
  final String? inviteLink;
  final List<MatchTimeOption> timeOptions;
  final List<MatchParticipantSummary> participants;

  bool get hasOpenSpot => joinedPlayers < maxPlayers;
  int get openSpots => maxPlayers - joinedPlayers;
  bool get isScheduledGame => timeOptions.length > 1;

  PadelMatch copyWith({
    String? title,
    String? hostId,
    String? hostName,
    String? hostPhotoData,
    String? area,
    String? courtName,
    String? courtPhotoData,
    DateTime? startTime,
    double? distanceKm,
    int? maxPlayers,
    int? joinedPlayers,
    SkillLevel? skillLevel,
    MatchVisibility? visibility,
    String? inviteCode,
    String? inviteLink,
    List<MatchTimeOption>? timeOptions,
    List<MatchParticipantSummary>? participants,
  }) {
    return PadelMatch(
      id: id,
      title: title ?? this.title,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostPhotoData: hostPhotoData ?? this.hostPhotoData,
      area: area ?? this.area,
      courtName: courtName ?? this.courtName,
      courtPhotoData: courtPhotoData ?? this.courtPhotoData,
      startTime: startTime ?? this.startTime,
      distanceKm: distanceKm ?? this.distanceKm,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      joinedPlayers: joinedPlayers ?? this.joinedPlayers,
      skillLevel: skillLevel ?? this.skillLevel,
      visibility: visibility ?? this.visibility,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteLink: inviteLink ?? this.inviteLink,
      timeOptions: timeOptions ?? this.timeOptions,
      participants: participants ?? this.participants,
    );
  }

  List<MatchParticipantSummary> get joinedParticipants => participants
      .where(
        (participant) =>
            participant.status == 'accepted' && participant.userId != hostId,
      )
      .toList(growable: false);

  List<MatchParticipantSummary> get acceptedParticipants => participants
      .where((participant) => participant.status == 'accepted')
      .toList(growable: false);

  List<MatchParticipantSummary> playersOnSide(String side) =>
      acceptedParticipants
          .where((participant) => participant.side == side)
          .toList(growable: false);

  bool hasSideSpot(String side) => playersOnSide(side).length < 2;

  String get joinedPlayerNames {
    final names = joinedParticipants.map((player) => player.name).toList();
    if (names.isEmpty) {
      return 'No players yet';
    }
    return names.join(', ');
  }

  String get sideSummary {
    String namesFor(String side) {
      final names = playersOnSide(side).map((player) => player.name).toList();
      return names.isEmpty ? '-' : names.join(', ');
    }

    return 'L: ${namesFor('left')} • R: ${namesFor('right')}';
  }
}

class MatchParticipantSummary {
  const MatchParticipantSummary({
    required this.id,
    required this.userId,
    required this.name,
    required this.handle,
    required this.status,
    this.photoData,
    this.side,
  });

  final String id;
  final String userId;
  final String name;
  final String handle;
  final String status;
  final String? photoData;
  final String? side;
}

class AppUserProfile {
  AppUserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.email,
    required this.phoneNumber,
    required this.birthDate,
    required this.area,
    this.photoData,
    this.accountStatus = 'active',
    this.deactivatedAt,
    this.deleteScheduledAt,
  });

  final String id;
  final String name;
  final String handle;
  final String email;
  final String phoneNumber;
  final DateTime birthDate;
  final String area;
  final String? photoData;
  final String accountStatus;
  final DateTime? deactivatedAt;
  final DateTime? deleteScheduledAt;

  bool get isDeactivated => accountStatus == 'deactivated';
}

class SocialUser {
  SocialUser({
    required this.id,
    required this.name,
    required this.handle,
    required this.area,
    this.skillLevel = 5,
    this.photoData,
  });

  final String id;
  final String name;
  final String handle;
  final String area;
  final int skillLevel;
  final String? photoData;
}

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.author,
    required this.area,
    required this.content,
    required this.createdAt,
    required this.activityType,
    this.authorId,
    this.authorPhotoData,
    this.likes = 0,
    this.comments = 0,
  });

  final String id;
  final String author;
  final String? authorId;
  final String? authorPhotoData;
  final String area;
  final String content;
  final DateTime createdAt;
  final ActivityType activityType;
  int likes;
  int comments;
}

class PlayerContact {
  PlayerContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.area,
    required this.personalRating,
    required this.publicRating,
    required this.relationship,
    required this.availableDays,
    this.notes = '',
    Set<PlayerTag>? tags,
  }) : tags = tags ?? {};

  final String id;
  final String name;
  final String phone;
  final String area;
  final int personalRating;
  final double publicRating;
  final CircleRelationship relationship;
  final List<String> availableDays;
  final String notes;
  final Set<PlayerTag> tags;

  bool get isFavorite => tags.contains(PlayerTag.favorite);
}

class ChatMessage {
  ChatMessage({
    required this.sender,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.senderId,
  });

  final String sender;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final String? senderId;
}

class ChatThread {
  ChatThread({
    required this.id,
    required this.title,
    required this.lastActivity,
    this.unreadCount = 0,
    this.type = 'direct',
    this.matchId,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  final String id;
  final String title;
  final String type;
  final String? matchId;
  DateTime lastActivity;
  int unreadCount;
  final List<ChatMessage> messages;

  String get preview => messages.isEmpty
      ? 'Start chatting with your padel group.'
      : messages.last.text;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.matchId,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? matchId;

  bool get isInviteRelated =>
      type == 'invitation' ||
      type == 'join_request' ||
      type == 'request_approved' ||
      type == 'request_rejected' ||
      type == 'request_hold' ||
      type == 'match_reminder';
}

class JoinRequest {
  JoinRequest({
    required this.id,
    required this.matchId,
    required this.requesterName,
    required this.requestedAt,
    this.requesterId,
    this.status = JoinRequestStatus.pending,
  });

  final String id;
  final String matchId;
  final String requesterName;
  final String? requesterId;
  final DateTime requestedAt;
  JoinRequestStatus status;
}

class CreatedGameResult {
  const CreatedGameResult({required this.match, required this.message});

  final PadelMatch match;
  final String message;
}

class MatchInvitation {
  MatchInvitation({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.sentAt,
  });

  final String id;
  final String matchId;
  final String playerId;
  final DateTime sentAt;
}

class MatchTargetRule {
  MatchTargetRule({required this.scope, Set<String>? targetUserIds})
    : targetUserIds = targetUserIds ?? <String>{};

  final MatchTargetScope scope;
  final Set<String> targetUserIds;

  bool get requiresApproval => scope == MatchTargetScope.publicGame;

  bool get instantJoin =>
      scope == MatchTargetScope.circle ||
      scope == MatchTargetScope.friends ||
      scope == MatchTargetScope.selectedUsers;
}

class PadelAppController extends ChangeNotifier {
  final Random _random = Random();
  final PadelBackendMock _backend = PadelBackendMock.seeded();
  final PadelApiClient _api = PadelApiClient();
  AppUserProfile? _currentUser;
  final List<SocialUser> _allUsers = [];
  final List<SocialUser> _followers = [];
  final List<SocialUser> _following = [];

  bool _syncing = false;
  String? _syncError;
  DateTime? _lastSyncAt;

  static const String _privacySettingsStorageKey = 'padel.settings.privacy.v1';
  static const String _generalSettingsStorageKey = 'padel.settings.general.v1';
  static const String _privateRatingsStorageKey =
      'padel.private_player_ratings.v1';
  static const String _readNotificationsStorageKey =
      'padel.read_notifications.v1';
  static const String _authTokenStorageKey = 'padel.auth_token.v1';
  static const String _localMatchesStoragePrefix = 'padel.local_matches.v1.';

  PrivacySettings _privacySettings = const PrivacySettings();
  GeneralSettings _generalSettings = const GeneralSettings();
  final Map<String, int> _privatePlayerRatings = {};

  static const String _userPhotoCachePrefix = 'padel.cache.photo.v1.';

  final List<AppNotification> _notifications = [];
  final Set<String> _localReminderIds = {};
  final Set<String> _readNotificationIds = {};
  Timer? _notificationPollTimer;

  PadelAppController() {
    _bootstrapMatchRules();
    unawaited(_initializeController());
  }

  Future<void> _initializeController() async {
    await _loadLocalSettings();
    if (_api.hasAuthToken) {
      await syncFromApi();
    }
  }

  Future<void> _rememberAuthToken(String? token) async {
    _api.setAuthToken(token);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_api.hasAuthToken) {
        await prefs.setString(_authTokenStorageKey, token!.trim());
      } else {
        await prefs.remove(_authTokenStorageKey);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    super.dispose();
  }

  final List<String> _areas = const [
    'Kuwait City',
    'Hawalli',
    'Salmiya',
    'Fintas',
    'Jabriya',
  ];

  String _selectedArea = 'Kuwait City';

  final List<PadelMatch> _matches = [];
  final List<CommunityPost> _posts = [];
  final List<ChatThread> _threads = [];
  final List<PlayerContact> _contacts = [];

  final List<PadelMatch> _myPrivateGames = [];
  final List<JoinRequest> _joinRequests = [];
  final List<MatchInvitation> _matchInvitations = [];
  final Map<String, MatchTargetRule> _matchRules = {};
  final Map<String, String> _matchHostIds = {};
  final Map<String, Set<String>> _acceptedPlayersByMatch = {};
  final Set<String> _localMatchIds = {};

  List<String> get areas => List.unmodifiable(_areas);
  String get selectedArea => _selectedArea;

  List<PadelMatch> get nearbyMatches {
    final filtered = _matches
        .where(_isActiveMatch)
        .where(_shouldShowOnHome)
        .toList();
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  }

  List<PadelMatch> get myHostedMatches {
    final items = _matches
        .where(_isActiveMatch)
        .where((match) => isHostOfMatch(match.id))
        .toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  List<CommunityPost> get feedPosts {
    final sameArea = _posts
        .where((post) => post.area == _selectedArea)
        .toList();
    final otherAreas = _posts
        .where((post) => post.area != _selectedArea)
        .toList();
    sameArea.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    otherAreas.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [...sameArea, ...otherAreas];
  }

  List<ChatThread> get threads {
    final sorted = _threads.toList();
    sorted.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return sorted;
  }

  List<PadelMatch> get myPrivateGames {
    final sorted = _myPrivateGames.where(_isActiveMatch).toList();
    sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted;
  }

  List<PadelMatch> get myMatchHistory {
    final me = _currentUser;
    if (me == null) {
      return const <PadelMatch>[];
    }

    final items = _matches.where(_isFinishedMatch).where((match) {
      if (isHostOfMatch(match.id)) {
        return true;
      }
      final acceptedPlayers =
          _acceptedPlayersByMatch[match.id] ?? const <String>{};
      if (acceptedPlayers.contains(me.id)) {
        return true;
      }
      return _joinRequests.any(
        (request) =>
            request.matchId == match.id && request.requesterId == me.id,
      );
    }).toList();
    items.sort((a, b) => b.startTime.compareTo(a.startTime));
    return items;
  }

  List<PlayerContact> get circleContacts {
    final sorted = _contacts.toList();
    sorted.sort((a, b) => b.personalRating.compareTo(a.personalRating));
    return sorted;
  }

  List<PlayerContact> get addedByMeContacts {
    return circleContacts
        .where((contact) => isAddedByMe(contact.id))
        .toList(growable: false);
  }

  List<PlayerContact> get addedMeContacts {
    return circleContacts
        .where((contact) => isAddedMe(contact.id))
        .toList(growable: false);
  }

  List<PlayerContact> get mutualContacts {
    return circleContacts
        .where((contact) => isMutual(contact.id))
        .toList(growable: false);
  }

  List<PlayerContact> contactsForCircuit(CircuitSource source) {
    switch (source) {
      case CircuitSource.addedByMe:
        return addedByMeContacts;
      case CircuitSource.addedMe:
        return addedMeContacts;
      case CircuitSource.mutual:
        return mutualContacts;
      case CircuitSource.allAppUsers:
        return circleContacts;
    }
  }

  List<MatchInvitation> invitationsForMatch(String matchId) {
    return _matchInvitations
        .where((entry) => entry.matchId == matchId)
        .toList(growable: false);
  }

  List<SocialUser> inviteCandidatesForMatch(String matchId) {
    final me = _currentUser;
    final match = matchById(matchId);
    if (me == null || match == null || !isHostOfMatch(matchId)) {
      return const <SocialUser>[];
    }

    final rule = _ruleForMatch(match);
    final unavailableIds = <String>{
      me.id,
      _matchHostIds[matchId] ?? '',
      ...rule.targetUserIds,
      ...(_acceptedPlayersByMatch[matchId] ?? const <String>{}),
      ..._joinRequests
          .where((entry) => entry.matchId == matchId)
          .map((entry) => entry.requesterId ?? ''),
      ..._matchInvitations
          .where((entry) => entry.matchId == matchId)
          .map((entry) => entry.playerId),
    }..remove('');

    final candidates = allUsers
        .where((entry) => !unavailableIds.contains(entry.id))
        .toList();
    candidates.sort((a, b) {
      final ratingCompare = (privateRatingForUser(b.id) ?? 0).compareTo(
        privateRatingForUser(a.id) ?? 0,
      );
      if (ratingCompare != 0) {
        return ratingCompare;
      }
      final friendCompare = (isMutual(b.id) ? 1 : 0).compareTo(
        isMutual(a.id) ? 1 : 0,
      );
      if (friendCompare != 0) {
        return friendCompare;
      }
      return a.name.compareTo(b.name);
    });
    return candidates;
  }

  PlayerContact? contactById(String id) {
    return _contacts.where((entry) => entry.id == id).firstOrNull;
  }

  PadelMatch? matchById(String id) {
    return _matches.where((entry) => entry.id == id).firstOrNull;
  }

  bool isAddedByMe(String accountId) {
    return _backend.isAddedByMe(accountId) || isFollowingUser(accountId);
  }

  bool isAddedMe(String accountId) {
    return _backend.isAddedMe(accountId) ||
        _followers.any((entry) => entry.id == accountId);
  }

  bool isMutual(String accountId) {
    return isAddedByMe(accountId) && isAddedMe(accountId);
  }

  int? privateRatingForUser(String userId) {
    final key = _privateRatingKey(userId);
    if (key == null) {
      return null;
    }
    return _privatePlayerRatings[key];
  }

  String privateRatingLabelForUser(String userId) {
    final rating = privateRatingForUser(userId);
    if (rating == null) {
      return 'Private rating: not set';
    }
    return 'Private rating: ${ratingLabelForValue(rating)} ($rating/10)';
  }

  Future<void> updatePrivateRatingForUser(String userId, int? rating) async {
    final key = _privateRatingKey(userId);
    if (key == null) {
      return;
    }

    if (rating == null) {
      _privatePlayerRatings.remove(key);
    } else {
      _privatePlayerRatings[key] = rating.clamp(1, 10).toInt();
    }
    await _persistPrivateRatings();
    notifyListeners();
  }

  int get nearbyPlayersCount =>
      nearbyMatches.fold<int>(0, (total, match) => total + match.joinedPlayers);

  bool get syncing => _syncing;
  String? get syncError => _syncError;
  DateTime? get lastSyncAt => _lastSyncAt;
  AppUserProfile? get currentUser => _currentUser;
  bool get hasCurrentUser => _currentUser != null;
  PrivacySettings get privacySettings => _privacySettings;
  GeneralSettings get generalSettings => _generalSettings;

  List<AppNotification> get notifications {
    final items = _notifications.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  int get unreadNotificationsCount =>
      _notifications.where((entry) => !entry.isRead).length;

  int get unreadInviteNotificationsCount => _notifications
      .where((entry) => !entry.isRead)
      .where((entry) => entry.isInviteRelated)
      .length;

  bool get isCurrentAccountDeactivated => _currentUser?.isDeactivated ?? false;

  DateTime? get currentAccountDeletionDate => _currentUser?.deleteScheduledAt;

  String get defaultTargetScopeKey {
    switch (_privacySettings.defaultInvitePermission) {
      case InvitePermission.everyone:
        return 'public';
      case InvitePermission.friendsOnly:
        return 'friends';
      case InvitePermission.circleOnly:
        return 'circle';
    }
  }

  List<SocialUser> get allUsers {
    final users = _allUsers.toList();
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }

  List<SocialUser> get followers {
    final users = _followers.toList();
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }

  List<SocialUser> get following {
    final users = _following.toList();
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }

  List<SocialUser> get friendUsers {
    final followerIds = _followers.map((entry) => entry.id).toSet();
    final users = _following
        .where((entry) => followerIds.contains(entry.id))
        .toList();
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }

  List<SocialUser> get circleUsers {
    final me = _currentUser;
    final users = _allUsers
        .where((entry) => me == null || entry.id != me.id)
        .where((entry) => isAddedByMe(entry.id))
        .toList();
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }

  List<SocialUser> get usersICanAddToCircle {
    final me = _currentUser;
    final users = _allUsers
        .where((entry) => me == null || entry.id != me.id)
        .toList();
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }

  MatchTargetScope targetScopeForMatch(String matchId) {
    final match = matchById(matchId);
    if (match == null) {
      return MatchTargetScope.publicGame;
    }
    return _ruleForMatch(match).scope;
  }

  String targetScopeLabelForMatch(String matchId) {
    switch (targetScopeForMatch(matchId)) {
      case MatchTargetScope.circle:
        return 'Circle';
      case MatchTargetScope.friends:
        return 'Friends';
      case MatchTargetScope.publicGame:
        return 'Public';
      case MatchTargetScope.selectedUsers:
        return 'Selected';
    }
  }

  bool isHostOfMatch(String matchId) {
    final me = _currentUser;
    if (me == null) {
      return false;
    }

    final hostId = _matchHostIds[matchId];
    if (hostId != null && hostId.isNotEmpty) {
      return hostId == me.id;
    }

    final match = matchById(matchId);
    if (match == null) {
      return false;
    }
    return match.hostName.trim().toLowerCase() == me.name.trim().toLowerCase();
  }

  bool isFriendHostedMatch(String matchId) {
    final me = _currentUser;
    if (me == null) {
      return false;
    }

    final hostId = _hostIdForMatch(matchId);
    return hostId != null && hostId != me.id && isMutual(hostId);
  }

  String? _hostIdForMatch(String matchId) {
    final storedHostId = _matchHostIds[matchId];
    if (storedHostId != null && storedHostId.isNotEmpty) {
      return storedHostId;
    }

    final match = matchById(matchId);
    if (match == null || match.hostId.isEmpty) {
      return null;
    }
    return match.hostId;
  }

  int pendingRequestsCountForMatch(String matchId) {
    return _joinRequests
        .where(
          (request) =>
              request.matchId == matchId &&
              (request.status == JoinRequestStatus.pending ||
                  request.status == JoinRequestStatus.onHold),
        )
        .length;
  }

  JoinRequestStatus? myRequestStatusForMatch(String matchId) {
    final me = _currentUser;
    if (me == null) {
      return null;
    }

    final requests = _joinRequests
        .where(
          (entry) => entry.matchId == matchId && entry.requesterId == me.id,
        )
        .toList();
    if (requests.isEmpty) {
      return null;
    }
    requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return requests.first.status;
  }

  String? myRequestStatusLabelForMatch(String matchId) {
    final status = myRequestStatusForMatch(matchId);
    if (status == null) {
      return null;
    }
    return joinRequestStatusLabel(status);
  }

  String joinActionLabelForMatch(String matchId) {
    final match = matchById(matchId);
    if (match == null) {
      return 'Join';
    }
    if (isJoinedMatch(matchId)) {
      return 'Leave';
    }
    final rule = _ruleForMatch(match);
    return _isInstantJoinForRule(rule) ? 'Join' : 'Request';
  }

  bool isJoinedMatch(String matchId) {
    final me = _currentUser;
    if (me == null || isHostOfMatch(matchId)) {
      return false;
    }

    if ((_acceptedPlayersByMatch[matchId] ?? const <String>{}).contains(
      me.id,
    )) {
      return true;
    }

    final status = myRequestStatusForMatch(matchId);
    return status == JoinRequestStatus.approved;
  }

  bool canChatInMatch(String matchId) {
    return isHostOfMatch(matchId) || isJoinedMatch(matchId);
  }

  List<PadelMatch> get allMatches {
    final items = _matches.where(_isActiveMatch).toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  List<CommunityPost> get allPosts {
    final items = _posts.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  bool isFollowingUser(String userId) {
    return _following.any((entry) => entry.id == userId);
  }

  Future<void> signInCurrentUser({
    required String email,
    required String password,
  }) async {
    final loggedIn = await _api.loginUser(
      email: email.trim().toLowerCase(),
      password: password,
    );
    await _rememberAuthToken(loggedIn['token']?.toString());

    var profile = _mapApiProfile(loggedIn);
    final cachedPhoto = await _readCachedUserPhoto(profile.id);
    var shouldBackfillCachedPhoto = false;
    if ((profile.photoData == null || profile.photoData!.isEmpty) &&
        cachedPhoto != null &&
        cachedPhoto.isNotEmpty) {
      profile = _copyUserProfile(profile, photoData: cachedPhoto);
      shouldBackfillCachedPhoto = true;
    }

    _currentUser = profile;
    if (shouldBackfillCachedPhoto) {
      try {
        final updated = await _api.updateUserPhoto(
          userId: profile.id,
          photoData: profile.photoData,
        );
        profile = _mapApiProfile(
          updated,
          fallbackBirthDate: profile.birthDate,
          fallbackName: profile.name,
          fallbackHandle: profile.handle,
          fallbackEmail: profile.email,
          fallbackPhone: profile.phoneNumber,
          fallbackArea: profile.area,
          fallbackPhotoData: profile.photoData,
          fallbackAccountStatus: profile.accountStatus,
          fallbackDeactivatedAt: profile.deactivatedAt,
          fallbackDeleteScheduledAt: profile.deleteScheduledAt,
        );
        _currentUser = profile;
      } catch (_) {}
    }
    await _cacheUserPhoto(profile.id, profile.photoData);
    await _loadLocalHostedMatchesForCurrentUser();

    _startNotificationPolling();
    await refreshNotifications();
    await syncFromApi();
    notifyListeners();
  }

  Future<void> registerCurrentUser({
    required String name,
    required String handle,
    required String email,
    required String phoneNumber,
    required DateTime birthDate,
    required String password,
    required String area,
    String? photoData,
  }) async {
    final created = await _api.createUser(
      name: name.trim(),
      handle: handle.trim(),
      email: email.trim().toLowerCase(),
      phoneNumber: phoneNumber.trim(),
      birthDateIso: birthDate.toIso8601String(),
      password: password,
      area: area,
      photoData: photoData,
    );
    await _rememberAuthToken(created['token']?.toString());

    final profile = _mapApiProfile(
      created,
      fallbackBirthDate: birthDate,
      fallbackName: name,
      fallbackHandle: handle,
      fallbackEmail: email,
      fallbackPhone: phoneNumber,
      fallbackArea: area,
      fallbackPhotoData: photoData,
    );

    _currentUser = profile;
    await _cacheUserPhoto(profile.id, profile.photoData);
    await _loadLocalHostedMatchesForCurrentUser();

    _startNotificationPolling();
    await refreshNotifications();
    await syncFromApi();
    notifyListeners();
  }

  Future<String> updateCurrentUserPhoto(Uint8List bytes) async {
    final me = _currentUser;
    if (me == null) {
      return 'Create your account first.';
    }

    final encoded = base64Encode(bytes);

    try {
      final updated = await _api.updateUserPhoto(
        userId: me.id,
        photoData: encoded,
      );
      _currentUser = _mapApiProfile(
        updated,
        fallbackBirthDate: me.birthDate,
        fallbackName: me.name,
        fallbackHandle: me.handle,
        fallbackEmail: me.email,
        fallbackPhone: me.phoneNumber,
        fallbackArea: me.area,
        fallbackPhotoData: encoded,
        fallbackAccountStatus: me.accountStatus,
        fallbackDeactivatedAt: me.deactivatedAt,
        fallbackDeleteScheduledAt: me.deleteScheduledAt,
      );
      await _cacheUserPhoto(me.id, _currentUser?.photoData);
      await syncFromApi();
      notifyListeners();
      return 'Profile photo updated.';
    } catch (_) {
      _currentUser = _copyUserProfile(me, photoData: encoded);
      await _cacheUserPhoto(me.id, encoded);
      notifyListeners();
      return 'Photo updated locally.';
    }
  }

  Future<String> removeCurrentUserPhoto() async {
    final me = _currentUser;
    if (me == null) {
      return 'Create your account first.';
    }

    try {
      final updated = await _api.updateUserPhoto(
        userId: me.id,
        photoData: null,
      );
      _currentUser = _mapApiProfile(
        updated,
        fallbackBirthDate: me.birthDate,
        fallbackName: me.name,
        fallbackHandle: me.handle,
        fallbackEmail: me.email,
        fallbackPhone: me.phoneNumber,
        fallbackArea: me.area,
        fallbackPhotoData: null,
        fallbackAccountStatus: me.accountStatus,
        fallbackDeactivatedAt: me.deactivatedAt,
        fallbackDeleteScheduledAt: me.deleteScheduledAt,
      );
      await _cacheUserPhoto(me.id, null);
      await syncFromApi();
      notifyListeners();
      return 'Profile photo removed.';
    } catch (_) {
      _currentUser = _copyUserProfile(me, photoData: null);
      await _cacheUserPhoto(me.id, null);
      notifyListeners();
      return 'Photo removed locally.';
    }
  }

  void updatePrivacySettings(PrivacySettings settings) {
    _privacySettings = settings;
    unawaited(_persistLocalSettings());
    notifyListeners();
  }

  void updateGeneralSettings(GeneralSettings settings) {
    _generalSettings = settings;
    unawaited(_persistLocalSettings());
    notifyListeners();
  }

  void resetAppSettings() {
    _privacySettings = const PrivacySettings();
    _generalSettings = const GeneralSettings();
    unawaited(_persistLocalSettings());
    notifyListeners();
  }

  bool get circleInstantJoinEnabled => _privacySettings.autoApproveCircleJoin;

  Future<String> deactivateCurrentAccount({int days = 40}) async {
    final me = _currentUser;
    if (me == null) {
      return 'No account found.';
    }

    final safeDays = days.clamp(1, 90);
    try {
      final response = await _api.deactivateUser(userId: me.id, days: safeDays);
      _currentUser = _mapApiProfile(
        response,
        fallbackBirthDate: me.birthDate,
        fallbackName: me.name,
        fallbackHandle: me.handle,
        fallbackEmail: me.email,
        fallbackPhone: me.phoneNumber,
        fallbackArea: me.area,
        fallbackPhotoData: me.photoData,
        fallbackAccountStatus: me.accountStatus,
        fallbackDeactivatedAt: me.deactivatedAt,
        fallbackDeleteScheduledAt: me.deleteScheduledAt,
      );
      final scheduled = _currentUser?.deleteScheduledAt;
      notifyListeners();
      if (scheduled == null) {
        return 'Account deactivated.';
      }
      return 'Account deactivated until ${scheduled.day}/${scheduled.month}/${scheduled.year}.';
    } catch (_) {
      return 'Could not deactivate account.';
    }
  }

  Future<String> reactivateCurrentAccount() async {
    final me = _currentUser;
    if (me == null) {
      return 'No account found.';
    }

    try {
      final response = await _api.reactivateUser(userId: me.id);
      _currentUser = _mapApiProfile(
        response,
        fallbackBirthDate: me.birthDate,
        fallbackName: me.name,
        fallbackHandle: me.handle,
        fallbackEmail: me.email,
        fallbackPhone: me.phoneNumber,
        fallbackArea: me.area,
        fallbackPhotoData: me.photoData,
        fallbackAccountStatus: me.accountStatus,
        fallbackDeactivatedAt: me.deactivatedAt,
        fallbackDeleteScheduledAt: me.deleteScheduledAt,
      );
      notifyListeners();
      return 'Account reactivated.';
    } catch (_) {
      return 'Could not reactivate account.';
    }
  }

  Future<String> deleteCurrentAccount() async {
    final me = _currentUser;
    if (me == null) {
      return 'No account found.';
    }

    try {
      await _api.deleteUser(userId: me.id);
      await _cacheUserPhoto(me.id, null);
      signOut();
      return 'Account deleted permanently.';
    } catch (_) {
      return 'Could not delete account.';
    }
  }

  void signOut() {
    unawaited(_rememberAuthToken(null));
    _currentUser = null;
    _followers.clear();
    _following.clear();
    _joinRequests.clear();
    _threads.clear();
    _notifications.clear();
    _notificationPollTimer?.cancel();
    _notificationPollTimer = null;
    notifyListeners();
  }

  Future<String> toggleFollowUser(String targetUserId) async {
    final me = _currentUser;
    if (me == null) {
      return 'Create your account first.';
    }
    if (targetUserId == me.id) {
      return 'This is your account.';
    }

    final target = _allUsers
        .where((entry) => entry.id == targetUserId)
        .firstOrNull;
    final isFollowing = isFollowingUser(targetUserId);

    try {
      if (isFollowing) {
        await _api.unfollowUser(userId: me.id, targetId: targetUserId);
      } else {
        await _api.followUser(userId: me.id, targetId: targetUserId);
      }
      await syncFromApi();
      return isFollowing
          ? 'Unfollowed @${target?.handle ?? 'user'}.'
          : 'Following @${target?.handle ?? 'user'}.';
    } catch (_) {
      return 'Could not update follow.';
    }
  }

  Future<void> syncFromApi() async {
    if (_syncing) {
      return;
    }

    _syncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final users = await _api.fetchUsers();
      final userNameById = <String, String>{};
      final userAreaById = <String, String>{};
      final userPhotoById = <String, String>{};
      final mappedUsers = <SocialUser>[];
      for (final user in users) {
        final id = user['id']?.toString();
        if (id == null || id.isEmpty) {
          continue;
        }
        mappedUsers.add(_mapApiUser(user));
        userNameById[id] = (user['name'] ?? user['handle'] ?? 'Player')
            .toString();
        userAreaById[id] = (user['area'] ?? _selectedArea).toString();
        final photoData = user['photoData']?.toString();
        if (photoData != null && photoData.isNotEmpty) {
          userPhotoById[id] = photoData;
        }
      }
      _allUsers
        ..clear()
        ..addAll(mappedUsers);

      final posts = await _api.fetchPosts();
      final matches = await _api.fetchMatches(userId: _currentUser?.id);

      if (posts.isNotEmpty) {
        _posts
          ..clear()
          ..addAll(
            posts.map(
              (entry) =>
                  _mapApiPost(entry, userNameById, userAreaById, userPhotoById),
            ),
          );
      }

      if (matches.isNotEmpty) {
        final localMatches = _matches
            .where((entry) => _localMatchIds.contains(entry.id))
            .toList(growable: false);
        final localRules = <String, MatchTargetRule>{
          for (final match in localMatches)
            if (_matchRules[match.id] != null) match.id: _matchRules[match.id]!,
        };
        final localHostIds = <String, String>{
          for (final match in localMatches)
            if ((_matchHostIds[match.id] ?? '').isNotEmpty)
              match.id: _matchHostIds[match.id]!,
        };
        final localAccepted = <String, Set<String>>{
          for (final match in localMatches)
            if (_acceptedPlayersByMatch[match.id] != null)
              match.id: {..._acceptedPlayersByMatch[match.id]!},
        };
        final localInvitations = _matchInvitations
            .where((entry) => _localMatchIds.contains(entry.matchId))
            .toList(growable: false);
        final mappedMatches = matches
            .map((entry) => _mapApiMatch(entry, userNameById, userPhotoById))
            .toList(growable: false);
        final serverMatchIds = mappedMatches.map((entry) => entry.id).toSet();
        final localOnlyMatches = localMatches
            .where((entry) => !serverMatchIds.contains(entry.id))
            .toList(growable: false);
        _matches
          ..clear()
          ..addAll(mappedMatches)
          ..addAll(localOnlyMatches);
        _syncParticipantsFromApiMatches(matches, userNameById);
        for (final match in localOnlyMatches) {
          final rule = localRules[match.id];
          final hostId = localHostIds[match.id];
          final accepted = localAccepted[match.id];
          if (rule != null) {
            _matchRules[match.id] = rule;
          }
          if (hostId != null) {
            _matchHostIds[match.id] = hostId;
          }
          if (accepted != null) {
            _acceptedPlayersByMatch[match.id] = accepted;
          }
        }
        _matchInvitations
          ..removeWhere((entry) => _localMatchIds.contains(entry.matchId))
          ..addAll(
            localInvitations.where(
              (entry) =>
                  localOnlyMatches.any((match) => match.id == entry.matchId),
            ),
          );
      }

      if (_currentUser != null) {
        final followers = await _api.fetchFollowers(_currentUser!.id);
        final following = await _api.fetchFollowing(_currentUser!.id);
        final notifications = await _api.fetchNotifications(_currentUser!.id);
        final chatThreads = await _api.fetchChatThreads(_currentUser!.id);
        _followers
          ..clear()
          ..addAll(followers.map(_mapApiUser));
        _following
          ..clear()
          ..addAll(following.map(_mapApiUser));
        _notifications
          ..clear()
          ..addAll(notifications.map(_mapApiNotification));
        _threads
          ..clear()
          ..addAll(chatThreads.map(_mapApiChatThread));
      }

      _ensureMatchRulesForExistingMatches();
      _ensureGameThreadsForCurrentUser();
      _refreshMatchReminders(playSound: false);
      await _persistLocalHostedMatchesForCurrentUser();

      _lastSyncAt = DateTime.now();
      _syncError = null;
    } catch (_) {
      _syncError = 'Offline';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  void addPrivateContact({
    required String name,
    required String phone,
    required String area,
    required int personalRating,
    required double publicRating,
    required CircleRelationship relationship,
    required Set<PlayerTag> tags,
    String notes = '',
  }) {
    final contactId = 'u${DateTime.now().microsecondsSinceEpoch}';
    _contacts.insert(
      0,
      PlayerContact(
        id: contactId,
        name: name.trim(),
        phone: phone.trim(),
        area: area.trim(),
        personalRating: personalRating.clamp(1, 10),
        publicRating: publicRating.clamp(1, 10).toDouble(),
        relationship: relationship,
        availableDays: const ['Sun', 'Mon'],
        tags: tags,
        notes: notes.trim(),
      ),
    );

    switch (relationship) {
      case CircleRelationship.closeFriend:
        _backend.addByMe(contactId);
        break;
      case CircleRelationship.mutualFollow:
        _backend.addByMe(contactId);
        _backend.addIncoming(contactId);
        break;
      case CircleRelationship.followerOnly:
        _backend.addIncoming(contactId);
        break;
    }

    notifyListeners();
  }

  Future<String> addAccountToMyList(String accountId) async {
    final me = _currentUser;
    final target = _allUsers
        .where((entry) => entry.id == accountId)
        .firstOrNull;

    if (me != null && target != null) {
      if (accountId == me.id) {
        return 'This is your account.';
      }
      try {
        await _api.followUser(userId: me.id, targetId: accountId);
        await syncFromApi();
        return 'Added @${target.handle}.';
      } catch (_) {
        return 'Could not add @${target.handle}.';
      }
    }

    _backend.addByMe(accountId);
    notifyListeners();
    return 'Added to your local list.';
  }

  Future<String> removeAccountFromMyList(String accountId) async {
    final me = _currentUser;
    final target = _allUsers
        .where((entry) => entry.id == accountId)
        .firstOrNull;

    if (me != null && target != null) {
      try {
        await _api.unfollowUser(userId: me.id, targetId: accountId);
        await syncFromApi();
        return 'Removed @${target.handle}.';
      } catch (_) {
        return 'Could not remove @${target.handle}.';
      }
    }

    _backend.removeByMe(accountId);
    notifyListeners();
    return 'Removed from your local list.';
  }

  void setSelectedArea(String area) {
    if (_areas.contains(area) && _selectedArea != area) {
      _selectedArea = area;
      notifyListeners();
    }
  }

  MatchTargetScope parseTargetScopeKey(String key) {
    switch (key) {
      case 'circle':
        return MatchTargetScope.circle;
      case 'friends':
        return MatchTargetScope.friends;
      case 'selected':
        return MatchTargetScope.selectedUsers;
      default:
        return MatchTargetScope.publicGame;
    }
  }

  List<SocialUser> usersForTargetScope(String key) {
    final scope = parseTargetScopeKey(key);
    switch (scope) {
      case MatchTargetScope.circle:
        return circleUsers;
      case MatchTargetScope.friends:
        return friendUsers;
      case MatchTargetScope.publicGame:
        return const <SocialUser>[];
      case MatchTargetScope.selectedUsers:
        return usersICanAddToCircle;
    }
  }

  String targetScopeApiKey(MatchTargetScope scope) {
    switch (scope) {
      case MatchTargetScope.circle:
        return 'circle';
      case MatchTargetScope.friends:
        return 'friends';
      case MatchTargetScope.publicGame:
        return 'public';
      case MatchTargetScope.selectedUsers:
        return 'selected';
    }
  }

  Future<CreatedGameResult> createTargetedGame({
    required String title,
    required String area,
    required DateTime startTime,
    List<DateTime> timeOptions = const [],
    required MatchTargetScope scope,
    List<String> selectedUserIds = const [],
    SkillLevel skillLevel = SkillLevel.intermediate,
    String hostSide = 'left',
    String? courtPhotoData,
  }) async {
    final me = _currentUser;
    final targetIds = _targetIdsForScope(scope, selectedUserIds).toSet();
    final isPublic = scope == MatchTargetScope.publicGame;

    if (me != null) {
      try {
        final created = await _api.createMatch(
          hostId: me.id,
          title: title.trim(),
          area: area.trim(),
          courtName: 'Pending Court',
          startsAtIso: startTime.toIso8601String(),
          isPrivate: !isPublic,
          targetScope: targetScopeApiKey(scope),
          inviteUserIds: targetIds.toList(growable: false),
          skillMin: _skillRangeForLevel(skillLevel).$1,
          skillMax: _skillRangeForLevel(skillLevel).$2,
          hostSide: hostSide,
          courtPhotoData: courtPhotoData,
          timeOptions: _timeOptionsToIso(startTime, timeOptions),
        );

        await syncFromApi();
        final matchId = created['id']?.toString();
        final match = matchId == null ? null : matchById(matchId);
        if (match != null) {
          _localMatchIds.add(match.id);
          _ensureGameThread(match);
          await _persistLocalHostedMatchesForCurrentUser();
          return CreatedGameResult(
            match: match,
            message: targetIds.isEmpty
                ? 'Game created.'
                : 'Game created and ${targetIds.length} players invited.',
          );
        }
      } catch (_) {
        // Fall through to the local optimistic game so the host never loses work.
      }
    }

    final matchId = 'm${DateTime.now().microsecondsSinceEpoch}';
    final inviteCode = _buildInviteCode();

    final match = PadelMatch(
      id: matchId,
      title: title.trim(),
      hostId: me?.id ?? '',
      hostName: me?.name ?? 'You',
      hostPhotoData: me?.photoData,
      area: area.trim(),
      courtName: 'Pending Court',
      courtPhotoData: courtPhotoData,
      startTime: startTime,
      timeOptions: _buildLocalTimeOptions(startTime, timeOptions),
      distanceKm: 0.0,
      maxPlayers: 4,
      joinedPlayers: 1,
      skillLevel: skillLevel,
      visibility: isPublic
          ? MatchVisibility.publicGame
          : MatchVisibility.privateGame,
      inviteCode: isPublic ? null : inviteCode,
      inviteLink: isPublic
          ? null
          : _buildInviteLink(matchId: matchId, inviteCode: inviteCode),
      participants: [
        if (me != null)
          MatchParticipantSummary(
            id: '${matchId}_${me.id}_host',
            userId: me.id,
            name: me.name,
            handle: me.handle,
            status: 'accepted',
            photoData: me.photoData,
            side: hostSide,
          ),
      ],
    );

    _matches.insert(0, match);
    _myPrivateGames.insert(0, match);
    _matchRules[match.id] = MatchTargetRule(
      scope: scope,
      targetUserIds: targetIds,
    );
    _matchHostIds[match.id] = me?.id ?? '';
    _acceptedPlayersByMatch[match.id] = {if (me != null) me.id};
    _ensureGameThread(match);
    _localMatchIds.add(match.id);

    final now = DateTime.now();
    _matchInvitations.addAll(
      targetIds.map(
        (userId) => MatchInvitation(
          id: 'i${now.microsecondsSinceEpoch}_$userId',
          matchId: match.id,
          playerId: userId,
          sentAt: now,
        ),
      ),
    );

    _posts.insert(
      0,
      CommunityPost(
        id: 'p${DateTime.now().microsecondsSinceEpoch}',
        author: me?.name ?? 'You',
        area: area.trim(),
        content:
            '${match.visibility == MatchVisibility.publicGame ? 'Public game' : 'Game'} created. Tap to ${_isInstantJoinForRule(_matchRules[match.id]!) ? 'join' : 'request'}.',
        createdAt: now,
        activityType: ActivityType.gameInvite,
      ),
    );

    await _persistLocalHostedMatchesForCurrentUser();
    notifyListeners();
    return CreatedGameResult(
      match: match,
      message: targetIds.isEmpty
          ? 'Game created locally.'
          : 'Game created locally for ${targetIds.length} players.',
    );
  }

  Future<String> joinMatchFromFeed(
    String matchId, {
    String? preferredSide,
  }) async {
    final me = _currentUser;
    if (me == null) {
      return 'Create your account first.';
    }

    final match = _matches.where((game) => game.id == matchId).firstOrNull;
    if (match == null) {
      return 'Could not find this game.';
    }

    if (isJoinedMatch(matchId)) {
      return leaveMatch(matchId);
    }

    if (isHostOfMatch(matchId)) {
      return 'You are the host.';
    }

    if (!match.hasOpenSpot) {
      _markRequestsAsFullIfMatchFull(match.id);
      notifyListeners();
      return 'Game is full.';
    }

    final rule = _ruleForMatch(match);
    if (!_isEligibleForMatch(userId: me.id, rule: rule)) {
      return 'Not available for your account.';
    }

    final side = _availableSideForMatch(match, preferredSide);
    if (side == null) {
      return 'Both sides are full.';
    }

    try {
      final response = await _api.joinMatch(
        matchId: matchId,
        userId: me.id,
        side: side,
      );
      final status = _statusFromApi(response['status']?.toString());
      await syncFromApi();

      switch (status) {
        case JoinRequestStatus.approved:
          _ensureGameThread(match);
          return 'Joined ${match.title}.';
        case JoinRequestStatus.pending:
          return 'Request sent. Waiting for host.';
        case JoinRequestStatus.full:
          return 'Game is full.';
        case JoinRequestStatus.onHold:
          return 'Your request is on hold.';
        case JoinRequestStatus.rejected:
          return 'Request was rejected.';
      }
    } catch (_) {
      // Keep the local path below for offline/manual games.
    }

    final acceptedIds = _acceptedPlayersByMatch.putIfAbsent(
      match.id,
      () => <String>{},
    );
    if (acceptedIds.contains(me.id)) {
      return 'Already joined.';
    }

    final existing = _joinRequests
        .where(
          (entry) =>
              entry.matchId == match.id &&
              entry.requesterId == me.id &&
              entry.status != JoinRequestStatus.rejected,
        )
        .toList();
    existing.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    if (existing.isNotEmpty) {
      return _joinStatusMessage(existing.first.status);
    }

    if (_isInstantJoinForRule(rule)) {
      acceptedIds.add(me.id);
      match.joinedPlayers += 1;
      _joinRequests.insert(
        0,
        JoinRequest(
          id: 'r${DateTime.now().microsecondsSinceEpoch}',
          matchId: match.id,
          requesterName: me.name,
          requesterId: me.id,
          requestedAt: DateTime.now(),
          status: JoinRequestStatus.approved,
        ),
      );
      match.participants.add(
        MatchParticipantSummary(
          id: '${match.id}_${me.id}_accepted',
          userId: me.id,
          name: me.name,
          handle: me.handle,
          status: 'accepted',
          photoData: me.photoData,
          side: side,
        ),
      );
      _markRequestsAsFullIfMatchFull(match.id);
      _ensureGameThread(match);
      notifyListeners();
      return 'Joined ${match.title}.';
    }

    _joinRequests.insert(
      0,
      JoinRequest(
        id: 'r${DateTime.now().microsecondsSinceEpoch}',
        matchId: match.id,
        requesterName: me.name,
        requesterId: me.id,
        requestedAt: DateTime.now(),
        status: JoinRequestStatus.pending,
      ),
    );
    notifyListeners();
    return 'Request sent. Waiting for host.';
  }

  String? _availableSideForMatch(PadelMatch match, String? preferredSide) {
    final cleanSide = preferredSide == 'right' ? 'right' : 'left';
    if (match.hasSideSpot(cleanSide)) {
      return cleanSide;
    }
    final otherSide = cleanSide == 'left' ? 'right' : 'left';
    if (match.hasSideSpot(otherSide)) {
      return otherSide;
    }
    return null;
  }

  Future<String> leaveMatch(String matchId) async {
    final me = _currentUser;
    if (me == null) {
      return 'Create your account first.';
    }
    if (isHostOfMatch(matchId)) {
      return 'Host cannot leave. Edit or delete the game instead.';
    }

    final match = matchById(matchId);
    if (match == null) {
      return 'Could not find this game.';
    }

    try {
      await _api.leaveMatch(matchId: matchId, userId: me.id);
      await syncFromApi();
      _threads.removeWhere((thread) => thread.id == gameThreadId(matchId));
      notifyListeners();
      return 'Left ${match.title}.';
    } catch (_) {
      (_acceptedPlayersByMatch[matchId] ?? <String>{}).remove(me.id);
      _joinRequests.removeWhere(
        (request) => request.matchId == matchId && request.requesterId == me.id,
      );
      if (match.joinedPlayers > 0) {
        match.joinedPlayers -= 1;
      }
      _threads.removeWhere((thread) => thread.id == gameThreadId(matchId));
      notifyListeners();
      return 'Left ${match.title}.';
    }
  }

  Future<String> joinPublicMatch(
    String matchId, {
    String? preferredSide,
  }) async {
    if (_currentUser == null) {
      return 'Create your account first.';
    }

    if (isJoinedMatch(matchId)) {
      return leaveMatch(matchId);
    }

    final match = _matches.where((game) => game.id == matchId).firstOrNull;
    if (match == null || match.visibility != MatchVisibility.publicGame) {
      return 'Could not find this game.';
    }
    if (!match.hasOpenSpot) {
      return 'Game is already full.';
    }
    final side = _availableSideForMatch(match, preferredSide);
    if (side == null) {
      return 'Both sides are full.';
    }

    try {
      final response = await _api.joinMatch(
        matchId: matchId,
        userId: _currentUser!.id,
        side: side,
      );
      final status = response['status']?.toString().toLowerCase() ?? 'pending';
      await syncFromApi();

      if (status == 'accepted') {
        _ensureGameThread(match);
        return 'Joined ${match.title}.';
      }
      if (status == 'pending') {
        return 'Join request sent.';
      }
      if (status == 'full') {
        return 'Game is full.';
      }
      return 'Request submitted.';
    } catch (_) {
      final me = _currentUser!;
      final duplicate = _joinRequests.any(
        (request) =>
            request.matchId == matchId &&
            request.requesterId == me.id &&
            request.status != JoinRequestStatus.rejected,
      );
      if (duplicate) {
        return 'Join request already sent.';
      }

      _joinRequests.insert(
        0,
        JoinRequest(
          id: 'r${DateTime.now().microsecondsSinceEpoch}',
          matchId: match.id,
          requesterName: me.name,
          requesterId: me.id,
          requestedAt: DateTime.now(),
          status: JoinRequestStatus.pending,
        ),
      );
      notifyListeners();
      return 'Join request sent.';
    }
  }

  List<JoinRequest> pendingRequestsForMatch(String matchId) {
    final pending = _joinRequests
        .where(
          (request) =>
              request.matchId == matchId &&
              (request.status == JoinRequestStatus.pending ||
                  request.status == JoinRequestStatus.onHold),
        )
        .toList();
    pending.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return pending;
  }

  List<JoinRequest> allRequestsForMatch(String matchId) {
    final all = _joinRequests
        .where((request) => request.matchId == matchId)
        .toList();
    all.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return all;
  }

  List<JoinRequest> requestsByPlayerName(String playerName) {
    final normalized = playerName.trim().toLowerCase();
    if (normalized.isEmpty) {
      return [];
    }
    final items = _joinRequests
        .where((request) => request.requesterName.toLowerCase() == normalized)
        .toList();
    items.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return items;
  }

  Future<String> requestPrivateJoinByLink({
    required String inviteLink,
    String? preferredSide,
  }) async {
    final rawLink = inviteLink.trim();
    final player = _currentUser;

    if (rawLink.isEmpty) {
      return 'Paste an invite link first.';
    }
    if (player == null) {
      return 'Create your account first.';
    }

    final uri = Uri.tryParse(rawLink);
    if (uri == null || !uri.hasScheme) {
      return 'Invalid invite link format.';
    }

    final matchId = uri.queryParameters['m'];
    final inviteCode = uri.queryParameters['code'];
    if (matchId == null || inviteCode == null) {
      return 'Invite link is missing game details.';
    }

    final isDuplicate = _joinRequests.any(
      (request) =>
          request.matchId == matchId &&
          request.requesterId == player.id &&
          (request.status == JoinRequestStatus.pending ||
              request.status == JoinRequestStatus.onHold ||
              request.status == JoinRequestStatus.full),
    );
    if (isDuplicate) {
      return 'You already sent a join request for this game.';
    }

    try {
      final response = await _api.joinMatch(
        matchId: matchId,
        userId: player.id,
        inviteCode: inviteCode,
        side: preferredSide,
      );
      final status = _statusFromApi(response['status']?.toString());

      _joinRequests.insert(
        0,
        JoinRequest(
          id: 'r${DateTime.now().microsecondsSinceEpoch}',
          matchId: matchId,
          requesterName: player.name,
          requesterId: player.id,
          requestedAt: DateTime.now(),
          status: status,
        ),
      );

      if (status == JoinRequestStatus.approved) {
        final match = _matches
            .where((entry) => entry.id == matchId)
            .firstOrNull;
        if (match != null && match.hasOpenSpot) {
          _acceptedPlayersByMatch
              .putIfAbsent(match.id, () => <String>{})
              .add(player.id);
          match.joinedPlayers += 1;
          _markRequestsAsFullIfMatchFull(match.id);
        }
      }

      notifyListeners();
      await syncFromApi();

      switch (status) {
        case JoinRequestStatus.approved:
          return 'Joined game successfully.';
        case JoinRequestStatus.pending:
          return 'Join request sent to host.';
        case JoinRequestStatus.full:
          return 'Game is full.';
        case JoinRequestStatus.onHold:
          return 'Your request is on hold.';
        case JoinRequestStatus.rejected:
          return 'Request was rejected.';
      }
    } catch (_) {
      return 'Invite link is not valid.';
    }
  }

  Future<bool> approveJoinRequest(String requestId) async {
    final request = _joinRequests
        .where((entry) => entry.id == requestId)
        .firstOrNull;
    if (request == null ||
        (request.status != JoinRequestStatus.pending &&
            request.status != JoinRequestStatus.onHold)) {
      return false;
    }

    final match = _matches
        .where((entry) => entry.id == request.matchId)
        .firstOrNull;
    if (match == null) {
      return false;
    }
    if (!match.hasOpenSpot) {
      request.status = JoinRequestStatus.full;
      notifyListeners();
      return false;
    }

    final me = _currentUser;
    if (me != null && isHostOfMatch(match.id)) {
      try {
        await _api.moderateJoinRequest(
          matchId: match.id,
          participantId: request.id,
          hostId: me.id,
          action: 'approve',
        );
        await syncFromApi();
        return true;
      } catch (_) {
        // Keep the local path below for offline/manual games.
      }
    }

    request.status = JoinRequestStatus.approved;
    final requesterId = request.requesterId;
    if (requesterId != null && requesterId.isNotEmpty) {
      _acceptedPlayersByMatch
          .putIfAbsent(match.id, () => <String>{})
          .add(requesterId);
    }
    match.joinedPlayers += 1;
    _markRequestsAsFullIfMatchFull(match.id);
    await _persistLocalHostedMatchesForCurrentUser();
    notifyListeners();
    return true;
  }

  Future<void> holdJoinRequest(String requestId) async {
    final request = _joinRequests
        .where((entry) => entry.id == requestId)
        .firstOrNull;
    if (request == null || request.status != JoinRequestStatus.pending) {
      return;
    }
    final me = _currentUser;
    if (me != null) {
      try {
        await _api.moderateJoinRequest(
          matchId: request.matchId,
          participantId: request.id,
          hostId: me.id,
          action: 'hold',
        );
        await syncFromApi();
        return;
      } catch (_) {
        // Keep the local path below for offline/manual games.
      }
    }
    request.status = JoinRequestStatus.onHold;
    await _persistLocalHostedMatchesForCurrentUser();
    notifyListeners();
  }

  Future<void> rejectJoinRequest(String requestId) async {
    final request = _joinRequests
        .where((entry) => entry.id == requestId)
        .firstOrNull;
    if (request == null ||
        (request.status != JoinRequestStatus.pending &&
            request.status != JoinRequestStatus.onHold &&
            request.status != JoinRequestStatus.full)) {
      return;
    }
    final match = _matches
        .where((entry) => entry.id == request.matchId)
        .firstOrNull;
    if (match == null) {
      return;
    }

    final me = _currentUser;
    if (me != null && isHostOfMatch(match.id)) {
      try {
        await _api.moderateJoinRequest(
          matchId: match.id,
          participantId: request.id,
          hostId: me.id,
          action: 'reject',
        );
        await syncFromApi();
        return;
      } catch (_) {
        // Keep the local path below for offline/manual games.
      }
    }

    final rule = _ruleForMatch(match);
    final requiresApproval = !_isInstantJoinForRule(rule);
    request.status = requiresApproval
        ? JoinRequestStatus.full
        : JoinRequestStatus.rejected;
    await _persistLocalHostedMatchesForCurrentUser();
    notifyListeners();
  }

  Future<String> createPost(String content) async {
    final text = content.trim();
    if (text.isEmpty) {
      return 'Write something first.';
    }

    final me = _currentUser;
    if (me != null) {
      try {
        await _api.createPost(authorId: me.id, content: text);
        await syncFromApi();
        return 'Post shared.';
      } catch (_) {
        // Keep a local post if the API is offline.
      }
    }

    _posts.insert(
      0,
      CommunityPost(
        id: 'p${DateTime.now().microsecondsSinceEpoch}',
        author: me?.name ?? 'You',
        authorId: me?.id,
        authorPhotoData: me?.photoData,
        area: me?.area ?? _selectedArea,
        content: text,
        createdAt: DateTime.now(),
        activityType: ActivityType.meetup,
      ),
    );
    notifyListeners();
    return 'Post shared locally.';
  }

  Future<void> likePost(String postId) async {
    final post = _posts.where((entry) => entry.id == postId).firstOrNull;
    if (post == null) {
      return;
    }
    post.likes += 1;
    notifyListeners();

    try {
      await _api.likePost(postId);
      await syncFromApi();
    } catch (_) {}
  }

  Future<String> commentOnPost(String postId, String text) async {
    final post = _posts.where((entry) => entry.id == postId).firstOrNull;
    final comment = text.trim();
    if (post == null) {
      return 'Post is not available anymore.';
    }
    if (comment.isEmpty) {
      return 'Write a comment first.';
    }

    post.comments += 1;
    notifyListeners();
    try {
      await _api.commentPost(postId);
      await syncFromApi();
    } catch (_) {}
    return 'Comment added.';
  }

  bool canDeletePost(String postId) {
    final me = _currentUser;
    if (me == null) {
      return false;
    }
    final post = _posts.where((entry) => entry.id == postId).firstOrNull;
    return post?.authorId == me.id;
  }

  Future<String> deletePost(String postId) async {
    final me = _currentUser;
    final post = _posts.where((entry) => entry.id == postId).firstOrNull;
    if (me == null || post == null || post.authorId != me.id) {
      return 'Only the author can delete this post.';
    }

    try {
      await _api.deletePost(postId: postId, authorId: me.id);
      await syncFromApi();
      return 'Post deleted.';
    } catch (_) {
      _posts.removeWhere((entry) => entry.id == postId);
      notifyListeners();
      return 'Post deleted locally.';
    }
  }

  ChatThread? getThreadById(String threadId) {
    return _threads.where((thread) => thread.id == threadId).firstOrNull;
  }

  String gameThreadId(String matchId) => 'match:$matchId';

  Future<String> openOrCreateGameThread(String matchId) async {
    final match = matchById(matchId);
    if (match == null) {
      return gameThreadId(matchId);
    }
    final me = _currentUser;
    if (me != null) {
      try {
        final payload = await _api.ensureMatchThread(
          matchId: matchId,
          userId: me.id,
        );
        final thread = _upsertApiChatThread(payload);
        notifyListeners();
        return thread.id;
      } catch (_) {}
    }
    return _ensureGameThread(match).id;
  }

  Future<String> openOrCreateDirectThread(String userId, String name) async {
    final me = _currentUser;
    if (me == null || userId.isEmpty) {
      return '';
    }

    try {
      final payload = await _api.ensureDirectThread(
        userId: me.id,
        targetUserId: userId,
      );
      final thread = _upsertApiChatThread(payload);
      notifyListeners();
      return thread.id;
    } catch (_) {}

    final ids = [me.id, userId]..sort();
    final threadId = 'direct:${ids.join(':')}';
    final existing = getThreadById(threadId);
    if (existing != null) {
      existing.lastActivity = DateTime.now();
      notifyListeners();
      return existing.id;
    }

    final thread = ChatThread(
      id: threadId,
      title: name.trim().isEmpty ? 'Direct chat' : name.trim(),
      lastActivity: DateTime.now(),
      messages: [
        ChatMessage(
          sender: 'System',
          text: 'Direct chat started.',
          sentAt: DateTime.now(),
          isMine: false,
        ),
      ],
    );
    _threads.insert(0, thread);
    notifyListeners();
    return thread.id;
  }

  ChatThread _upsertApiChatThread(Map<String, dynamic> payload) {
    final thread = _mapApiChatThread(payload);
    final existingIndex = _threads.indexWhere((entry) => entry.id == thread.id);
    if (existingIndex == -1) {
      _threads.insert(0, thread);
    } else {
      _threads[existingIndex] = thread;
    }
    return thread;
  }

  ChatThread _ensureGameThread(PadelMatch match) {
    final threadId = gameThreadId(match.id);
    final existing = getThreadById(threadId);
    if (existing != null) {
      existing.lastActivity = existing.lastActivity.isAfter(match.startTime)
          ? existing.lastActivity
          : match.startTime;
      return existing;
    }

    final thread = ChatThread(
      id: threadId,
      title: match.title,
      lastActivity: DateTime.now(),
      messages: [
        ChatMessage(
          sender: 'System',
          text: 'Game chat for ${match.title}.',
          sentAt: DateTime.now(),
          isMine: false,
        ),
      ],
    );
    _threads.insert(0, thread);
    return thread;
  }

  void _ensureGameThreadsForCurrentUser() {
    for (final match in _matches.where(_isActiveMatch)) {
      if (canChatInMatch(match.id)) {
        _ensureGameThread(match);
      }
    }
  }

  void markThreadRead(String threadId) {
    final thread = getThreadById(threadId);
    if (thread == null || thread.unreadCount == 0) {
      return;
    }
    thread.unreadCount = 0;
    notifyListeners();
  }

  void sendMessage(String threadId, String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return;
    }

    final thread = getThreadById(threadId);
    if (thread == null) {
      return;
    }

    thread.messages.add(
      ChatMessage(
        sender: 'You',
        senderId: _currentUser?.id,
        text: cleanText,
        sentAt: DateTime.now(),
        isMine: true,
      ),
    );
    thread.lastActivity = DateTime.now();
    thread.unreadCount = 0;
    notifyListeners();

    final me = _currentUser;
    if (me != null && !thread.id.startsWith('match:')) {
      unawaited(
        _api
            .sendChatMessage(
              threadId: thread.id,
              userId: me.id,
              text: cleanText,
            )
            .then((_) => syncFromApi())
            .catchError((_) {}),
      );
    }
  }

  List<PlayerContact> suggestPrivateInviteTargets({
    required InviteAudience audience,
    required GameTone tone,
    required int minPersonalRating,
    required int maxPersonalRating,
    Set<PlayerTag> requiredTags = const {},
    List<String> customRecipientIds = const [],
  }) {
    return _selectAudienceContacts(
      audience: audience,
      tone: tone,
      minPersonalRating: minPersonalRating,
      maxPersonalRating: maxPersonalRating,
      requiredTags: requiredTags,
      customRecipientIds: customRecipientIds,
    );
  }

  PadelMatch createPrivateGame({
    required String title,
    required String area,
    required SkillLevel skill,
    required DateTime startTime,
    required InviteAudience inviteAudience,
    required GameTone tone,
    required int minPersonalRating,
    required int maxPersonalRating,
    Set<PlayerTag> requiredTags = const {},
    List<String> customRecipientIds = const [],
    String? courtPhotoData,
  }) {
    final matchId = 'm${DateTime.now().microsecondsSinceEpoch}';
    final inviteCode = _buildInviteCode();
    final me = _currentUser;
    final match = PadelMatch(
      id: matchId,
      title: title.trim(),
      hostId: me?.id ?? '',
      hostName: me?.name ?? 'You',
      hostPhotoData: me?.photoData,
      area: area,
      courtName: 'Pending Court',
      courtPhotoData: courtPhotoData,
      startTime: startTime,
      distanceKm: 0.0,
      maxPlayers: 4,
      joinedPlayers: 1,
      skillLevel: skill,
      visibility: MatchVisibility.privateGame,
      inviteCode: inviteCode,
      inviteLink: _buildInviteLink(matchId: matchId, inviteCode: inviteCode),
      participants: [
        if (me != null)
          MatchParticipantSummary(
            id: '${matchId}_${me.id}_host',
            userId: me.id,
            name: me.name,
            handle: me.handle,
            status: 'accepted',
            photoData: me.photoData,
            side: 'left',
          ),
      ],
    );

    final recipients = _selectAudienceContacts(
      audience: inviteAudience,
      tone: tone,
      minPersonalRating: minPersonalRating,
      maxPersonalRating: maxPersonalRating,
      requiredTags: requiredTags,
      customRecipientIds: customRecipientIds,
    );

    _myPrivateGames.insert(0, match);
    _matches.insert(0, match);
    _matchHostIds[match.id] = me?.id ?? '';
    _acceptedPlayersByMatch[match.id] = {if (me != null) me.id};
    _matchRules[match.id] = MatchTargetRule(
      scope: _scopeFromInviteAudience(inviteAudience),
      targetUserIds: recipients.map((entry) => entry.id).toSet(),
    );
    _ensureGameThread(match);
    _matchInvitations.addAll(
      recipients.map(
        (player) => MatchInvitation(
          id: 'i${DateTime.now().microsecondsSinceEpoch}_${player.id}',
          matchId: match.id,
          playerId: player.id,
          sentAt: DateTime.now(),
        ),
      ),
    );
    _posts.insert(
      0,
      CommunityPost(
        id: 'p${DateTime.now().microsecondsSinceEpoch + 1}',
        author: me?.name ?? 'You',
        area: area,
        content:
            'Private match created for ${audienceLabel(inviteAudience)}. Invited ${recipients.length} players.',
        createdAt: DateTime.now(),
        activityType: ActivityType.gameInvite,
      ),
    );
    notifyListeners();
    return match;
  }

  Future<CreatedGameResult> createPrivateGameQuick({
    required String title,
    required String area,
    required DateTime startTime,
  }) {
    return createTargetedGame(
      title: title,
      area: area,
      startTime: startTime,
      scope: MatchTargetScope.circle,
    );
  }

  MatchTargetScope _scopeFromInviteAudience(InviteAudience audience) {
    switch (audience) {
      case InviteAudience.closeFriends:
        return MatchTargetScope.circle;
      case InviteAudience.followBackOnly:
        return MatchTargetScope.friends;
      case InviteAudience.custom:
        return MatchTargetScope.selectedUsers;
    }
  }

  List<String> _targetIdsForScope(
    MatchTargetScope scope,
    List<String> selectedUserIds,
  ) {
    List<String> selectedInsideScope(List<SocialUser> users) {
      final scopeIds = users.map((entry) => entry.id).toList(growable: false);
      final selected = selectedUserIds.toSet();
      if (selected.isEmpty) {
        return scopeIds;
      }
      return scopeIds.where(selected.contains).toList(growable: false);
    }

    switch (scope) {
      case MatchTargetScope.circle:
        return selectedInsideScope(circleUsers);
      case MatchTargetScope.friends:
        return selectedInsideScope(friendUsers);
      case MatchTargetScope.publicGame:
        return const <String>[];
      case MatchTargetScope.selectedUsers:
        return selectedUserIds.toSet().toList(growable: false);
    }
  }

  List<PlayerContact> _selectAudienceContacts({
    required InviteAudience audience,
    required GameTone tone,
    required int minPersonalRating,
    required int maxPersonalRating,
    required Set<PlayerTag> requiredTags,
    required List<String> customRecipientIds,
  }) {
    Iterable<PlayerContact> candidates = _contacts;

    switch (audience) {
      case InviteAudience.closeFriends:
        candidates = candidates.where(
          (player) => _backend.isAddedByMe(player.id),
        );
        break;
      case InviteAudience.followBackOnly:
        candidates = candidates.where((player) => _backend.isMutual(player.id));
        break;
      case InviteAudience.custom:
        final customSet = customRecipientIds.toSet();
        candidates = candidates.where(
          (player) => customSet.contains(player.id),
        );
        break;
    }

    candidates = candidates.where(
      (player) =>
          player.personalRating >= minPersonalRating &&
          player.personalRating <= maxPersonalRating,
    );

    if (requiredTags.isNotEmpty) {
      candidates = candidates.where(
        (player) => requiredTags.every(player.tags.contains),
      );
    }

    switch (tone) {
      case GameTone.friendly:
        candidates = candidates.where(
          (player) =>
              player.tags.contains(PlayerTag.friendly) ||
              player.personalRating <= 7,
        );
        break;
      case GameTone.balanced:
        break;
      case GameTone.competitive:
        candidates = candidates.where(
          (player) =>
              player.tags.contains(PlayerTag.competitive) ||
              player.personalRating >= 7,
        );
        break;
    }

    final sorted = candidates.toList();
    sorted.sort((a, b) {
      final favoritePriority = (b.isFavorite ? 1 : 0).compareTo(
        a.isFavorite ? 1 : 0,
      );
      if (favoritePriority != 0) {
        return favoritePriority;
      }
      return b.personalRating.compareTo(a.personalRating);
    });
    return sorted.take(8).toList();
  }

  void _bootstrapMatchRules() {
    _ensureMatchRulesForExistingMatches();
  }

  void _ensureMatchRulesForExistingMatches() {
    final activeIds = _matches.map((entry) => entry.id).toSet();

    _matchRules.removeWhere((matchId, _) => !activeIds.contains(matchId));
    _matchHostIds.removeWhere((matchId, _) => !activeIds.contains(matchId));
    _acceptedPlayersByMatch.removeWhere(
      (matchId, _) => !activeIds.contains(matchId),
    );

    for (final match in _matches) {
      _matchRules.putIfAbsent(
        match.id,
        () => MatchTargetRule(
          scope: match.visibility == MatchVisibility.publicGame
              ? MatchTargetScope.publicGame
              : MatchTargetScope.friends,
        ),
      );
      _acceptedPlayersByMatch.putIfAbsent(match.id, () => <String>{});
    }
  }

  MatchTargetRule _ruleForMatch(PadelMatch match) {
    return _matchRules[match.id] ??
        MatchTargetRule(
          scope: match.visibility == MatchVisibility.publicGame
              ? MatchTargetScope.publicGame
              : MatchTargetScope.friends,
        );
  }

  void _replaceLocalMatch(PadelMatch updated) {
    final matchIndex = _matches.indexWhere((entry) => entry.id == updated.id);
    if (matchIndex == -1) {
      _matches.insert(0, updated);
    } else {
      _matches[matchIndex] = updated;
    }

    final privateIndex = _myPrivateGames.indexWhere(
      (entry) => entry.id == updated.id,
    );
    if (updated.visibility == MatchVisibility.privateGame) {
      if (privateIndex == -1) {
        _myPrivateGames.insert(0, updated);
      } else {
        _myPrivateGames[privateIndex] = updated;
      }
    } else if (privateIndex != -1) {
      _myPrivateGames.removeAt(privateIndex);
    }
  }

  bool _isInstantJoinForRule(MatchTargetRule rule) {
    return rule.scope != MatchTargetScope.publicGame;
  }

  bool _isEligibleForMatch({
    required String userId,
    required MatchTargetRule rule,
  }) {
    if (rule.scope == MatchTargetScope.publicGame) {
      return true;
    }
    if (rule.targetUserIds.isEmpty) {
      return false;
    }
    return rule.targetUserIds.contains(userId);
  }

  bool _canCurrentUserSeeMatch(PadelMatch match) {
    if (match.visibility == MatchVisibility.publicGame) {
      return true;
    }
    final me = _currentUser;
    if (me == null) {
      return false;
    }
    if (isHostOfMatch(match.id)) {
      return true;
    }
    if (_joinRequests.any(
      (request) => request.matchId == match.id && request.requesterId == me.id,
    )) {
      return true;
    }
    return _isEligibleForMatch(userId: me.id, rule: _ruleForMatch(match));
  }

  bool _shouldShowOnHome(PadelMatch match) {
    if (_isFinishedMatch(match)) {
      return false;
    }
    if (isHostOfMatch(match.id)) {
      return false;
    }
    if (!_canCurrentUserSeeMatch(match)) {
      return false;
    }
    if (match.area == _selectedArea) {
      return true;
    }

    final me = _currentUser;
    if (me == null) {
      return false;
    }

    final rule = _ruleForMatch(match);
    return rule.scope != MatchTargetScope.publicGame &&
        _isEligibleForMatch(userId: me.id, rule: rule);
  }

  bool _isActiveMatch(PadelMatch match) => !_isFinishedMatch(match);

  bool _isFinishedMatch(PadelMatch match) {
    const estimatedMatchDuration = Duration(hours: 2);
    return match.startTime.add(estimatedMatchDuration).isBefore(DateTime.now());
  }

  String _joinStatusMessage(JoinRequestStatus status) {
    switch (status) {
      case JoinRequestStatus.pending:
        return 'Request already pending.';
      case JoinRequestStatus.onHold:
        return 'Request is on hold.';
      case JoinRequestStatus.approved:
        return 'Already joined.';
      case JoinRequestStatus.rejected:
        return 'Request rejected.';
      case JoinRequestStatus.full:
        return 'Game is full.';
    }
  }

  void _markRequestsAsFullIfMatchFull(String matchId) {
    final match = _matches.where((entry) => entry.id == matchId).firstOrNull;
    if (match == null || match.hasOpenSpot) {
      return;
    }

    for (final request in _joinRequests) {
      if (request.matchId == matchId &&
          (request.status == JoinRequestStatus.pending ||
              request.status == JoinRequestStatus.onHold)) {
        request.status = JoinRequestStatus.full;
      }
    }
  }

  Future<void> refreshNotifications({bool notify = true}) async {
    final me = _currentUser;
    if (me == null) {
      _notifications.clear();
      if (notify) {
        notifyListeners();
      }
      return;
    }

    try {
      final previousUnreadIds = _notifications
          .where((entry) => !entry.isRead)
          .map((entry) => entry.id)
          .toSet();
      final payload = await _api.fetchNotifications(me.id);
      _notifications
        ..clear()
        ..addAll(payload.map(_mapApiNotification));
      _readNotificationIds.addAll(
        _notifications.where((entry) => entry.isRead).map((entry) => entry.id),
      );
      _refreshMatchReminders(playSound: false);
      final hasNewUnread = _notifications.any(
        (entry) => !entry.isRead && !previousUnreadIds.contains(entry.id),
      );
      if (hasNewUnread) {
        unawaited(SystemSound.play(SystemSoundType.alert));
        unawaited(syncFromApi());
      }
      if (notify) {
        notifyListeners();
      }
    } catch (_) {
      if (notify) {
        notifyListeners();
      }
    }
  }

  void _refreshMatchReminders({required bool playSound}) {
    final me = _currentUser;
    if (me == null) {
      return;
    }

    final now = DateTime.now();
    var addedReminder = false;
    for (final match in _matches) {
      final playerIds = _acceptedPlayersByMatch[match.id] ?? const <String>{};
      final shouldRemind = isHostOfMatch(match.id) || playerIds.contains(me.id);
      if (!shouldRemind) {
        continue;
      }

      final minutesUntil = match.startTime.difference(now).inMinutes;
      if (minutesUntil < 0 || minutesUntil > 60) {
        continue;
      }

      final bucket = minutesUntil <= 10 ? 'soon' : 'hour';
      final reminderId = 'local_reminder_${match.id}_$bucket';
      if (_localReminderIds.contains(reminderId) ||
          _notifications.any((entry) => entry.id == reminderId)) {
        continue;
      }

      _localReminderIds.add(reminderId);
      _notifications.insert(
        0,
        AppNotification(
          id: reminderId,
          userId: me.id,
          type: 'match_reminder',
          title: bucket == 'soon' ? 'Match starts soon' : 'Match reminder',
          body: bucket == 'soon'
              ? '${match.title} starts in about $minutesUntil minutes.'
              : '${match.title} starts at ${_timeLabel(match.startTime)}.',
          createdAt: now,
          isRead: _readNotificationIds.contains(reminderId),
          matchId: match.id,
        ),
      );
      addedReminder = true;
    }

    if (addedReminder && playSound) {
      unawaited(SystemSound.play(SystemSoundType.alert));
    }
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> markNotificationRead(String notificationId) async {
    _readNotificationIds.add(notificationId);
    unawaited(_persistReadNotificationIds());
    try {
      await _api.markNotificationRead(notificationId);
    } catch (_) {}

    final index = _notifications.indexWhere(
      (entry) => entry.id == notificationId,
    );
    if (index < 0) {
      return;
    }

    final current = _notifications[index];
    _notifications[index] = AppNotification(
      id: current.id,
      userId: current.userId,
      type: current.type,
      title: current.title,
      body: current.body,
      createdAt: current.createdAt,
      isRead: true,
      matchId: current.matchId,
    );
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    final unread = _notifications
        .where((entry) => !entry.isRead)
        .map((entry) => entry.id)
        .toList(growable: false);
    if (unread.isEmpty) {
      return;
    }

    _readNotificationIds.addAll(unread);
    for (var index = 0; index < _notifications.length; index += 1) {
      final current = _notifications[index];
      if (current.isRead) {
        continue;
      }
      _notifications[index] = AppNotification(
        id: current.id,
        userId: current.userId,
        type: current.type,
        title: current.title,
        body: current.body,
        createdAt: current.createdAt,
        isRead: true,
        matchId: current.matchId,
      );
    }
    notifyListeners();
    await _persistReadNotificationIds();

    await Future.wait(
      unread.map((id) async {
        try {
          await _api.markNotificationRead(id);
        } catch (_) {}
      }),
    );
  }

  PadelMatch? matchFromNotification(AppNotification notification) {
    final matchId = notification.matchId;
    if (matchId == null || matchId.isEmpty) {
      return null;
    }
    return matchById(matchId);
  }

  Future<String> invitePlayersToHostedMatch(
    String matchId,
    List<String> userIds,
  ) async {
    final me = _currentUser;
    final match = matchById(matchId);
    final uniqueIds = userIds.toSet().toList(growable: false);
    if (me == null || match == null || !isHostOfMatch(matchId)) {
      return 'Only the host can invite players.';
    }
    if (uniqueIds.isEmpty) {
      return 'Choose at least one player.';
    }

    try {
      final invited = await _api.invitePlayers(
        matchId: matchId,
        hostId: me.id,
        targetUserIds: uniqueIds,
      );
      await syncFromApi();
      return invited == 0
          ? 'No new players to invite.'
          : 'Invited $invited player${invited == 1 ? '' : 's'}.';
    } catch (_) {
      final now = DateTime.now();
      final rule = _matchRules.putIfAbsent(
        matchId,
        () => MatchTargetRule(scope: MatchTargetScope.selectedUsers),
      );
      rule.targetUserIds.addAll(uniqueIds);
      _matchInvitations.addAll(
        uniqueIds.map(
          (userId) => MatchInvitation(
            id: 'i${now.microsecondsSinceEpoch}_$userId',
            matchId: matchId,
            playerId: userId,
            sentAt: now,
          ),
        ),
      );
      _localMatchIds.add(matchId);
      await _persistLocalHostedMatchesForCurrentUser();
      notifyListeners();
      return 'Invites added locally.';
    }
  }

  Future<String> updateHostedMatchDetails(
    String matchId, {
    DateTime? startTime,
    List<DateTime> timeOptions = const [],
    String? courtName,
    String? courtPhotoData,
  }) async {
    final me = _currentUser;
    final match = matchById(matchId);
    if (me == null || match == null || !isHostOfMatch(matchId)) {
      return 'Only the host can update this game.';
    }
    if (startTime == null && courtName == null && courtPhotoData == null) {
      return 'Nothing to update.';
    }

    try {
      await _api.updateMatchDetails(
        matchId: matchId,
        hostId: me.id,
        startsAtIso: startTime?.toIso8601String(),
        courtName: courtName,
        courtPhotoData: courtPhotoData,
        timeOptions: startTime == null
            ? const []
            : _timeOptionsToIso(startTime, timeOptions),
      );
      await syncFromApi();
      return startTime == null
          ? 'Game updated.'
          : 'Game time updated and joined players were notified.';
    } catch (_) {
      final updated = match.copyWith(
        startTime: startTime,
        timeOptions: startTime == null
            ? match.timeOptions
            : _buildLocalTimeOptions(startTime, timeOptions),
        courtName: courtName == null || courtName.trim().isEmpty
            ? match.courtName
            : courtName.trim(),
        courtPhotoData: courtPhotoData ?? match.courtPhotoData,
      );
      _replaceLocalMatch(updated);
      _localMatchIds.add(matchId);
      await _persistLocalHostedMatchesForCurrentUser();
      notifyListeners();
      return startTime == null
          ? 'Game updated locally.'
          : 'Game time updated locally.';
    }
  }

  Future<String> voteForMatchTimeOption(String matchId, String optionId) async {
    final me = _currentUser;
    final match = matchById(matchId);
    if (me == null || match == null || match.timeOptions.length <= 1) {
      return 'Could not choose this time.';
    }

    try {
      await _api.voteMatchTimeOption(
        matchId: matchId,
        userId: me.id,
        optionId: optionId,
      );
      await syncFromApi();
      return 'Time choice saved.';
    } catch (_) {
      final options = match.timeOptions
          .map((option) {
            final votes = option.voterIds.where((id) => id != me.id).toList();
            if (option.id == optionId) {
              votes.add(me.id);
            }
            return option.copyWith(voterIds: votes);
          })
          .toList(growable: false);
      final selected = options
          .where((option) => option.id == optionId)
          .firstOrNull;
      _replaceLocalMatch(
        match.copyWith(startTime: selected?.startTime, timeOptions: options),
      );
      notifyListeners();
      return 'Time choice saved locally.';
    }
  }

  Future<String> replaceJoinedPlayerWithInvite(
    String matchId, {
    required String removeUserId,
    required String inviteUserId,
    String? side,
  }) async {
    final me = _currentUser;
    final match = matchById(matchId);
    if (me == null || match == null || !isHostOfMatch(matchId)) {
      return 'Only the host can replace players.';
    }
    if (removeUserId == inviteUserId) {
      return 'Choose a different player.';
    }

    final removedPlayer = match.acceptedParticipants
        .where(
          (participant) =>
              participant.userId == removeUserId && participant.userId != me.id,
        )
        .firstOrNull;
    if (removedPlayer == null) {
      return 'Choose a joined player to replace.';
    }

    final inviteUser = _allUsers
        .where((entry) => entry.id == inviteUserId)
        .firstOrNull;
    if (inviteUser == null) {
      return 'Choose a player to invite.';
    }

    try {
      await _api.replaceMatchPlayer(
        matchId: matchId,
        hostId: me.id,
        removeUserId: removeUserId,
        inviteUserId: inviteUserId,
        side: side,
      );
      await syncFromApi();
      return '${removedPlayer.name} replaced. ${inviteUser.name} was invited.';
    } catch (_) {
      final participants = match.participants.map((participant) {
        if (participant.userId != removeUserId) {
          return participant;
        }
        return MatchParticipantSummary(
          id: participant.id,
          userId: participant.userId,
          name: participant.name,
          handle: participant.handle,
          status: 'left',
          photoData: participant.photoData,
        );
      }).toList();
      participants.removeWhere(
        (participant) => participant.userId == inviteUserId,
      );
      participants.add(
        MatchParticipantSummary(
          id: 'i${DateTime.now().microsecondsSinceEpoch}_$inviteUserId',
          userId: inviteUser.id,
          name: inviteUser.name,
          handle: inviteUser.handle,
          status: 'invited',
          photoData: inviteUser.photoData,
          side: side,
        ),
      );

      final updated = match.copyWith(
        joinedPlayers: (match.joinedPlayers - 1)
            .clamp(1, match.maxPlayers)
            .toInt(),
        participants: participants,
      );
      _replaceLocalMatch(updated);
      _acceptedPlayersByMatch[matchId]?.remove(removeUserId);
      _matchRules
          .putIfAbsent(
            matchId,
            () => MatchTargetRule(scope: MatchTargetScope.selectedUsers),
          )
          .targetUserIds
          .add(inviteUserId);
      _matchInvitations.add(
        MatchInvitation(
          id: 'i${DateTime.now().microsecondsSinceEpoch}_$inviteUserId',
          matchId: matchId,
          playerId: inviteUserId,
          sentAt: DateTime.now(),
        ),
      );
      _localMatchIds.add(matchId);
      await _persistLocalHostedMatchesForCurrentUser();
      notifyListeners();
      return '${removedPlayer.name} replaced locally. ${inviteUser.name} was invited.';
    }
  }

  Future<String> deleteHostedMatch(String matchId) async {
    final me = _currentUser;
    final match = matchById(matchId);
    if (me == null || match == null || !isHostOfMatch(matchId)) {
      return 'Only the host can delete this game.';
    }

    try {
      await _api.deleteMatch(matchId: matchId, hostId: me.id);
      await syncFromApi();
      return 'Game deleted.';
    } catch (_) {
      _matches.removeWhere((entry) => entry.id == matchId);
      _myPrivateGames.removeWhere((entry) => entry.id == matchId);
      _joinRequests.removeWhere((entry) => entry.matchId == matchId);
      _matchRules.remove(matchId);
      _matchHostIds.remove(matchId);
      _acceptedPlayersByMatch.remove(matchId);
      _localMatchIds.remove(matchId);
      await _persistLocalHostedMatchesForCurrentUser();
      notifyListeners();
      return 'Game deleted locally.';
    }
  }

  Future<String> makeHostedMatchPrivate(String matchId) async {
    final me = _currentUser;
    final match = matchById(matchId);
    if (me == null || match == null || !isHostOfMatch(matchId)) {
      return 'Only the host can update this game.';
    }

    final friendIds = friendUsers.map((entry) => entry.id).toList();
    final scope = friendIds.isEmpty
        ? MatchTargetScope.selectedUsers
        : MatchTargetScope.friends;

    try {
      await _api.updateMatchPrivacy(
        matchId: matchId,
        hostId: me.id,
        isPrivate: true,
        targetScope: targetScopeApiKey(scope),
        inviteUserIds: friendIds,
      );
      await syncFromApi();
      return friendIds.isEmpty
          ? 'Game is private.'
          : 'Game is private and friends were invited.';
    } catch (_) {
      _matchRules[matchId] = MatchTargetRule(
        scope: scope,
        targetUserIds: friendIds.toSet(),
      );
      _localMatchIds.add(matchId);
      await _persistLocalHostedMatchesForCurrentUser();
      notifyListeners();
      return 'Game privacy updated locally.';
    }
  }

  void _startNotificationPolling() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(refreshNotifications());
    });
  }

  AppUserProfile _copyUserProfile(AppUserProfile source, {String? photoData}) {
    return AppUserProfile(
      id: source.id,
      name: source.name,
      handle: source.handle,
      email: source.email,
      phoneNumber: source.phoneNumber,
      birthDate: source.birthDate,
      area: source.area,
      photoData: photoData,
      accountStatus: source.accountStatus,
      deactivatedAt: source.deactivatedAt,
      deleteScheduledAt: source.deleteScheduledAt,
    );
  }

  Future<void> _cacheUserPhoto(String userId, String? photoData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _photoCacheKey(userId);
      if (photoData == null || photoData.isEmpty) {
        await prefs.remove(key);
        return;
      }
      await prefs.setString(key, photoData);
    } catch (_) {}
  }

  Future<String?> _readCachedUserPhoto(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_photoCacheKey(userId));
      if (cached == null || cached.isEmpty) {
        return null;
      }
      return cached;
    } catch (_) {
      return null;
    }
  }

  String _photoCacheKey(String userId) => '$_userPhotoCachePrefix$userId';

  String? _localMatchesStorageKeyForCurrentUser() {
    final userId = _currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return '$_localMatchesStoragePrefix$userId';
  }

  Future<void> _loadLocalHostedMatchesForCurrentUser() async {
    final key = _localMatchesStorageKeyForCurrentUser();
    final me = _currentUser;
    if (key == null || me == null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      final data = Map<String, dynamic>.from(decoded);
      final rawMatches = data['matches'];
      if (rawMatches is! List) {
        return;
      }

      final loadedIds = <String>{};
      for (final rawMatch in rawMatches.whereType<Map>()) {
        final match = _matchFromLocalJson(Map<String, dynamic>.from(rawMatch));
        if (match == null) {
          continue;
        }
        loadedIds.add(match.id);
        _localMatchIds.add(match.id);
        _matches.removeWhere((entry) => entry.id == match.id);
        _matches.add(match);
        if (match.visibility == MatchVisibility.privateGame) {
          _myPrivateGames.removeWhere((entry) => entry.id == match.id);
          _myPrivateGames.add(match);
        }
      }

      final rawRules = data['rules'];
      if (rawRules is Map) {
        for (final entry in rawRules.entries) {
          final matchId = entry.key.toString();
          if (!loadedIds.contains(matchId) || entry.value is! Map) {
            continue;
          }
          _matchRules[matchId] = _ruleFromLocalJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }

      final rawHostIds = data['hostIds'];
      if (rawHostIds is Map) {
        for (final entry in rawHostIds.entries) {
          final matchId = entry.key.toString();
          if (loadedIds.contains(matchId)) {
            _matchHostIds[matchId] = entry.value?.toString() ?? me.id;
          }
        }
      }

      final rawAccepted = data['accepted'];
      if (rawAccepted is Map) {
        for (final entry in rawAccepted.entries) {
          final matchId = entry.key.toString();
          final rawIds = entry.value;
          if (!loadedIds.contains(matchId) || rawIds is! List) {
            continue;
          }
          _acceptedPlayersByMatch[matchId] = rawIds
              .map((id) => id.toString())
              .where((id) => id.isNotEmpty)
              .toSet();
        }
      }

      _matchInvitations.removeWhere(
        (entry) => loadedIds.contains(entry.matchId),
      );
      final rawInvitations = data['invitations'];
      if (rawInvitations is List) {
        _matchInvitations.addAll(
          rawInvitations
              .whereType<Map>()
              .map(
                (entry) =>
                    _invitationFromLocalJson(Map<String, dynamic>.from(entry)),
              )
              .whereType<MatchInvitation>()
              .where((entry) => loadedIds.contains(entry.matchId)),
        );
      }

      _ensureMatchRulesForExistingMatches();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistLocalHostedMatchesForCurrentUser() async {
    final key = _localMatchesStorageKeyForCurrentUser();
    if (key == null) {
      return;
    }

    final hostedMatches = _matches
        .where((entry) => isHostOfMatch(entry.id))
        .toList(growable: false);
    _localMatchIds
      ..clear()
      ..addAll(hostedMatches.map((entry) => entry.id));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode({
          'matches': hostedMatches.map(_matchToLocalJson).toList(),
          'rules': {
            for (final match in hostedMatches)
              match.id: _ruleToLocalJson(_ruleForMatch(match)),
          },
          'hostIds': {
            for (final match in hostedMatches)
              match.id: _matchHostIds[match.id] ?? _currentUser?.id ?? '',
          },
          'accepted': {
            for (final match in hostedMatches)
              match.id: (_acceptedPlayersByMatch[match.id] ?? const <String>{})
                  .toList(),
          },
          'invitations': _matchInvitations
              .where((entry) => _localMatchIds.contains(entry.matchId))
              .map(_invitationToLocalJson)
              .toList(),
        }),
      );
    } catch (_) {}
  }

  Map<String, dynamic> _matchToLocalJson(PadelMatch match) {
    return {
      'id': match.id,
      'title': match.title,
      'hostId': match.hostId,
      'hostName': match.hostName,
      'hostPhotoData': match.hostPhotoData,
      'area': match.area,
      'courtName': match.courtName,
      'courtPhotoData': match.courtPhotoData,
      'startTime': match.startTime.toIso8601String(),
      'distanceKm': match.distanceKm,
      'maxPlayers': match.maxPlayers,
      'joinedPlayers': match.joinedPlayers,
      'skillLevel': match.skillLevel.name,
      'visibility': match.visibility.name,
      'inviteCode': match.inviteCode,
      'inviteLink': match.inviteLink,
      'timeOptions': match.timeOptions
          .map(
            (option) => {
              'id': option.id,
              'startTime': option.startTime.toIso8601String(),
              'voterIds': option.voterIds,
            },
          )
          .toList(),
      'participants': match.participants
          .map(
            (participant) => {
              'id': participant.id,
              'userId': participant.userId,
              'userName': participant.name,
              'userHandle': participant.handle,
              'userPhotoData': participant.photoData,
              'status': participant.status,
              'side': participant.side,
            },
          )
          .toList(),
    };
  }

  PadelMatch? _matchFromLocalJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      return null;
    }

    final rawStart = json['startTime']?.toString();
    final currentUserPhotoById = <String, String>{
      if (_currentUser?.photoData?.isNotEmpty == true)
        _currentUser!.id: _currentUser!.photoData!,
    };
    return PadelMatch(
      id: id,
      title: (json['title'] ?? 'Match').toString(),
      hostId: (json['hostId'] ?? _currentUser?.id ?? '').toString(),
      hostName: (json['hostName'] ?? _currentUser?.name ?? 'Host').toString(),
      hostPhotoData:
          json['hostPhotoData']?.toString() ?? _currentUser?.photoData,
      area: (json['area'] ?? _selectedArea).toString(),
      courtName: (json['courtName'] ?? 'Pending Court').toString(),
      courtPhotoData: json['courtPhotoData']?.toString(),
      startTime:
          DateTime.tryParse(rawStart ?? '')?.toLocal() ??
          DateTime.now().add(const Duration(hours: 2)),
      distanceKm: double.tryParse(json['distanceKm']?.toString() ?? '') ?? 0,
      maxPlayers: _asInt(json['maxPlayers'], 4),
      joinedPlayers: _asInt(json['joinedPlayers'], 1),
      skillLevel:
          SkillLevel.values
              .where((entry) => entry.name == json['skillLevel']?.toString())
              .firstOrNull ??
          SkillLevel.intermediate,
      visibility:
          MatchVisibility.values
              .where((entry) => entry.name == json['visibility']?.toString())
              .firstOrNull ??
          MatchVisibility.privateGame,
      inviteCode: json['inviteCode']?.toString(),
      inviteLink: json['inviteLink']?.toString(),
      timeOptions: _timeOptionsFromEntry(json),
      participants: _participantSummariesFromEntry(
        json,
        {if (_currentUser != null) _currentUser!.id: _currentUser!.name},
        hostId: (json['hostId'] ?? _currentUser?.id ?? '').toString(),
        userPhotoById: currentUserPhotoById,
      ),
    );
  }

  Map<String, dynamic> _ruleToLocalJson(MatchTargetRule rule) {
    return {
      'scope': rule.scope.name,
      'targetUserIds': rule.targetUserIds.toList(),
    };
  }

  MatchTargetRule _ruleFromLocalJson(Map<String, dynamic> json) {
    final scope =
        MatchTargetScope.values
            .where((entry) => entry.name == json['scope']?.toString())
            .firstOrNull ??
        MatchTargetScope.friends;
    final rawTargets = json['targetUserIds'];
    return MatchTargetRule(
      scope: scope,
      targetUserIds: rawTargets is List
          ? rawTargets
                .map((entry) => entry.toString())
                .where((entry) => entry.isNotEmpty)
                .toSet()
          : <String>{},
    );
  }

  Map<String, dynamic> _invitationToLocalJson(MatchInvitation invitation) {
    return {
      'id': invitation.id,
      'matchId': invitation.matchId,
      'playerId': invitation.playerId,
      'sentAt': invitation.sentAt.toIso8601String(),
    };
  }

  MatchInvitation? _invitationFromLocalJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final matchId = json['matchId']?.toString();
    final playerId = json['playerId']?.toString();
    if (id == null ||
        id.isEmpty ||
        matchId == null ||
        matchId.isEmpty ||
        playerId == null ||
        playerId.isEmpty) {
      return null;
    }
    return MatchInvitation(
      id: id,
      matchId: matchId,
      playerId: playerId,
      sentAt:
          DateTime.tryParse(json['sentAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _api.setAuthToken(prefs.getString(_authTokenStorageKey));

      final rawPrivacy = prefs.getString(_privacySettingsStorageKey);
      if (rawPrivacy != null && rawPrivacy.isNotEmpty) {
        final decoded = jsonDecode(rawPrivacy);
        if (decoded is Map) {
          _privacySettings = PrivacySettings.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }

      final rawGeneral = prefs.getString(_generalSettingsStorageKey);
      if (rawGeneral != null && rawGeneral.isNotEmpty) {
        final decoded = jsonDecode(rawGeneral);
        if (decoded is Map) {
          _generalSettings = GeneralSettings.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }

      final rawRatings = prefs.getString(_privateRatingsStorageKey);
      if (rawRatings != null && rawRatings.isNotEmpty) {
        final decoded = jsonDecode(rawRatings);
        if (decoded is Map) {
          _privatePlayerRatings
            ..clear()
            ..addAll(
              Map<String, dynamic>.from(decoded).map(
                (key, value) =>
                    MapEntry(key, int.tryParse(value.toString()) ?? 5),
              ),
            );
        }
      }

      final rawReadNotifications = prefs.getString(
        _readNotificationsStorageKey,
      );
      if (rawReadNotifications != null && rawReadNotifications.isNotEmpty) {
        final decoded = jsonDecode(rawReadNotifications);
        if (decoded is List) {
          _readNotificationIds
            ..clear()
            ..addAll(decoded.map((entry) => entry.toString()));
        }
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> _persistLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _privacySettingsStorageKey,
        jsonEncode(_privacySettings.toJson()),
      );
      await prefs.setString(
        _generalSettingsStorageKey,
        jsonEncode(_generalSettings.toJson()),
      );
    } catch (_) {}
  }

  Future<void> _persistPrivateRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _privateRatingsStorageKey,
        jsonEncode(_privatePlayerRatings),
      );
    } catch (_) {}
  }

  Future<void> _persistReadNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _readNotificationsStorageKey,
        jsonEncode(_readNotificationIds.toList(growable: false)),
      );
    } catch (_) {}
  }

  String? _privateRatingKey(String targetUserId) {
    final me = _currentUser;
    if (me == null || targetUserId.isEmpty || targetUserId == me.id) {
      return null;
    }
    return '${me.id}:$targetUserId';
  }

  String _buildInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  SocialUser _mapApiUser(Map<String, dynamic> entry) {
    return SocialUser(
      id: entry['id']?.toString() ?? '',
      name: (entry['name'] ?? 'Player').toString(),
      handle: (entry['handle'] ?? 'player').toString(),
      area: (entry['area'] ?? _selectedArea).toString(),
      skillLevel: _asInt(entry['skillLevel'], 5).clamp(1, 10),
      photoData: entry['photoData']?.toString(),
    );
  }

  AppUserProfile _mapApiProfile(
    Map<String, dynamic> entry, {
    DateTime? fallbackBirthDate,
    String? fallbackName,
    String? fallbackHandle,
    String? fallbackEmail,
    String? fallbackPhone,
    String? fallbackArea,
    String? fallbackPhotoData,
    String? fallbackAccountStatus,
    DateTime? fallbackDeactivatedAt,
    DateTime? fallbackDeleteScheduledAt,
  }) {
    final id = entry['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Invalid user response');
    }

    final rawBirthDate = entry['birthDate']?.toString();
    final birthDate = rawBirthDate == null
        ? (fallbackBirthDate ?? DateTime(2000, 1, 1))
        : DateTime.tryParse(rawBirthDate) ??
              fallbackBirthDate ??
              DateTime(2000, 1, 1);

    final rawDeactivatedAt = entry['deactivatedAt']?.toString();
    final deactivatedAt = rawDeactivatedAt == null
        ? fallbackDeactivatedAt
        : DateTime.tryParse(rawDeactivatedAt)?.toLocal() ??
              fallbackDeactivatedAt;

    final rawDeleteScheduledAt = entry['deleteScheduledAt']?.toString();
    final deleteScheduledAt = rawDeleteScheduledAt == null
        ? fallbackDeleteScheduledAt
        : DateTime.tryParse(rawDeleteScheduledAt)?.toLocal() ??
              fallbackDeleteScheduledAt;

    return AppUserProfile(
      id: id,
      name: (entry['name'] ?? fallbackName ?? 'Player').toString(),
      handle: (entry['handle'] ?? fallbackHandle ?? 'player').toString(),
      email: (entry['email'] ?? fallbackEmail ?? '').toString(),
      phoneNumber: (entry['phoneNumber'] ?? fallbackPhone ?? '').toString(),
      birthDate: birthDate,
      area: (entry['area'] ?? fallbackArea ?? _selectedArea).toString(),
      photoData: entry['photoData']?.toString() ?? fallbackPhotoData,
      accountStatus:
          (entry['accountStatus'] ?? fallbackAccountStatus ?? 'active')
              .toString(),
      deactivatedAt: deactivatedAt,
      deleteScheduledAt: deleteScheduledAt,
    );
  }

  PadelMatch _mapApiMatch(
    Map<String, dynamic> entry,
    Map<String, String> userNameById,
    Map<String, String> userPhotoById,
  ) {
    final skillMin = _asInt(entry['skillMin'], 1);
    final skillMax = _asInt(entry['skillMax'], 10);
    final rawStartsAt = entry['startsAt']?.toString();
    final parsedStartsAt = rawStartsAt == null
        ? null
        : DateTime.tryParse(rawStartsAt)?.toLocal();
    final hostId = entry['hostId']?.toString() ?? '';
    final id =
        entry['id']?.toString() ??
        'match_${DateTime.now().millisecondsSinceEpoch}';
    _matchHostIds[id] = hostId;
    final targetScope = parseTargetScopeKey(
      (entry['targetScope'] ??
              (entry['isPrivate'] == true ? 'friends' : 'public'))
          .toString(),
    );
    final invitedIds = _participantIdsFromEntry(entry).toSet()
      ..removeWhere((id) => id == hostId);
    _matchRules[id] = MatchTargetRule(
      scope: targetScope,
      targetUserIds: invitedIds,
    );

    return PadelMatch(
      id: id,
      title: (entry['title'] ?? 'Match').toString(),
      hostId: hostId,
      hostName: (entry['hostName'] ?? userNameById[hostId] ?? 'Host')
          .toString(),
      hostPhotoData:
          entry['hostPhotoData']?.toString() ?? userPhotoById[hostId],
      area: (entry['area'] ?? _selectedArea).toString(),
      courtName: (entry['courtName'] ?? 'Court').toString(),
      courtPhotoData: entry['courtPhotoData']?.toString(),
      startTime: parsedStartsAt ?? DateTime.now().add(const Duration(hours: 2)),
      distanceKm: (_random.nextDouble() * 4) + 0.5,
      maxPlayers: _asInt(entry['maxPlayers'], 4),
      joinedPlayers: _asInt(entry['joinedPlayers'], 1),
      skillLevel: _skillLevelFromRange(skillMin, skillMax),
      visibility: entry['isPrivate'] == true
          ? MatchVisibility.privateGame
          : MatchVisibility.publicGame,
      inviteCode: entry['inviteCode']?.toString(),
      inviteLink: entry['inviteLink']?.toString(),
      timeOptions: _timeOptionsFromEntry(entry),
      participants: _participantSummariesFromEntry(
        entry,
        userNameById,
        hostId: hostId,
        userPhotoById: userPhotoById,
      ),
    );
  }

  List<String> _timeOptionsToIso(DateTime startTime, List<DateTime> options) {
    final times = <DateTime>[startTime, ...options];
    final isoTimes = <String>[];
    for (final time in times) {
      final iso = time.toIso8601String();
      if (!isoTimes.contains(iso)) {
        isoTimes.add(iso);
      }
    }
    return isoTimes;
  }

  List<MatchTimeOption> _buildLocalTimeOptions(
    DateTime startTime,
    List<DateTime> options,
  ) {
    final isoTimes = _timeOptionsToIso(startTime, options);
    if (isoTimes.length <= 1) {
      return const [];
    }
    return [
      for (var i = 0; i < isoTimes.length; i++)
        MatchTimeOption(
          id: 'time_${i + 1}_${DateTime.now().microsecondsSinceEpoch}',
          startTime: DateTime.parse(isoTimes[i]),
          voterIds: i == 0 && _currentUser != null
              ? [_currentUser!.id]
              : const [],
        ),
    ];
  }

  List<MatchTimeOption> _timeOptionsFromEntry(Map<String, dynamic> entry) {
    final rawOptions = entry['timeOptions'];
    if (rawOptions is! List) {
      return const [];
    }

    final options = <MatchTimeOption>[];
    for (var i = 0; i < rawOptions.length; i++) {
      final raw = rawOptions[i];
      if (raw is! Map) {
        continue;
      }
      final rawStart = (raw['startsAt'] ?? raw['startTime'])?.toString();
      final startTime = DateTime.tryParse(rawStart ?? '')?.toLocal();
      if (startTime == null) {
        continue;
      }
      final rawVoters = raw['voterIds'];
      options.add(
        MatchTimeOption(
          id: (raw['id'] ?? 'time_${i + 1}').toString(),
          startTime: startTime,
          voterIds: rawVoters is List
              ? rawVoters.map((entry) => entry.toString()).toList()
              : const [],
        ),
      );
    }
    return options;
  }

  List<MatchParticipantSummary> _participantSummariesFromEntry(
    Map<String, dynamic> entry,
    Map<String, String> userNameById, {
    required String hostId,
    Map<String, String> userPhotoById = const <String, String>{},
  }) {
    final rawParticipants = entry['participants'];
    if (rawParticipants is! List) {
      return const <MatchParticipantSummary>[];
    }

    return rawParticipants
        .whereType<Map>()
        .map((rawParticipant) {
          final participant = Map<String, dynamic>.from(rawParticipant);
          final userId = participant['userId']?.toString() ?? '';
          final status = (participant['status'] ?? '').toString().toLowerCase();
          final rawPhotoData =
              participant['userPhotoData'] ??
              participant['photoData'] ??
              userPhotoById[userId];
          final side = participant['side']?.toString();
          return MatchParticipantSummary(
            id:
                participant['id']?.toString() ??
                '${entry['id'] ?? 'match'}_${userId}_$status',
            userId: userId,
            name: (participant['userName'] ?? userNameById[userId] ?? 'Player')
                .toString(),
            handle: (participant['userHandle'] ?? 'player').toString(),
            photoData: rawPhotoData?.toString(),
            side: side == 'right' ? 'right' : (side == 'left' ? 'left' : null),
            status: status.isEmpty
                ? (userId == hostId ? 'accepted' : 'invited')
                : status,
          );
        })
        .toList(growable: false);
  }

  void _syncParticipantsFromApiMatches(
    List<Map<String, dynamic>> matches,
    Map<String, String> userNameById,
  ) {
    _joinRequests.clear();
    _acceptedPlayersByMatch.clear();

    for (final match in matches) {
      final matchId = match['id']?.toString();
      final hostId = match['hostId']?.toString();
      final rawParticipants = match['participants'];
      if (matchId == null || rawParticipants is! List) {
        continue;
      }

      final acceptedIds = <String>{};
      for (final rawParticipant in rawParticipants.whereType<Map>()) {
        final participant = Map<String, dynamic>.from(rawParticipant);
        final userId = participant['userId']?.toString();
        if (userId == null || userId.isEmpty) {
          continue;
        }

        final rawStatus = participant['status']?.toString().toLowerCase();
        final status = _statusFromApi(rawStatus);
        if (status == JoinRequestStatus.approved) {
          acceptedIds.add(userId);
        }

        if (userId == hostId || rawStatus == 'invited') {
          continue;
        }

        final rawCreatedAt = participant['createdAt']?.toString();
        final requestedAt = rawCreatedAt == null
            ? DateTime.now()
            : DateTime.tryParse(rawCreatedAt)?.toLocal() ?? DateTime.now();

        _joinRequests.add(
          JoinRequest(
            id:
                participant['id']?.toString() ??
                'r${matchId}_${userId}_${status.name}',
            matchId: matchId,
            requesterName:
                (participant['userName'] ?? userNameById[userId] ?? 'Player')
                    .toString(),
            requesterId: userId,
            requestedAt: requestedAt,
            status: status,
          ),
        );
      }

      _acceptedPlayersByMatch[matchId] = acceptedIds;
    }
  }

  Set<String> _participantIdsFromEntry(Map<String, dynamic> entry) {
    final rawParticipants = entry['participants'];
    if (rawParticipants is! List) {
      return const <String>{};
    }

    return rawParticipants
        .whereType<Map>()
        .map((participant) => participant['userId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  CommunityPost _mapApiPost(
    Map<String, dynamic> entry,
    Map<String, String> userNameById,
    Map<String, String> userAreaById,
    Map<String, String> userPhotoById,
  ) {
    final authorId = entry['authorId']?.toString() ?? '';
    final rawCreatedAt = entry['createdAt']?.toString();
    final createdAt = rawCreatedAt == null
        ? DateTime.now()
        : DateTime.tryParse(rawCreatedAt)?.toLocal() ?? DateTime.now();
    final content = (entry['content'] ?? '').toString();

    return CommunityPost(
      id:
          entry['id']?.toString() ??
          'post_${DateTime.now().millisecondsSinceEpoch}',
      author: userNameById[authorId] ?? 'Player',
      authorId: authorId,
      authorPhotoData: userPhotoById[authorId],
      area: userAreaById[authorId] ?? _selectedArea,
      content: content,
      createdAt: createdAt,
      activityType: _activityFromContent(content),
      likes: _asInt(entry['likes'], 0),
      comments: _asInt(entry['comments'], 0),
    );
  }

  AppNotification _mapApiNotification(Map<String, dynamic> entry) {
    final id =
        entry['id']?.toString() ?? 'n_${DateTime.now().millisecondsSinceEpoch}';
    final rawCreatedAt = entry['createdAt']?.toString();
    final createdAt = rawCreatedAt == null
        ? DateTime.now()
        : DateTime.tryParse(rawCreatedAt)?.toLocal() ?? DateTime.now();
    final isRead = entry['isRead'] == true || _readNotificationIds.contains(id);

    return AppNotification(
      id: id,
      userId: entry['userId']?.toString() ?? '',
      type: (entry['type'] ?? '').toString(),
      title: (entry['title'] ?? 'Notification').toString(),
      body: (entry['body'] ?? '').toString(),
      createdAt: createdAt,
      isRead: isRead,
      matchId: entry['matchId']?.toString(),
    );
  }

  ChatThread _mapApiChatThread(Map<String, dynamic> entry) {
    final id = entry['id']?.toString() ?? '';
    final rawUpdatedAt =
        entry['updatedAt']?.toString() ?? entry['createdAt']?.toString();
    final lastActivity =
        DateTime.tryParse(rawUpdatedAt ?? '')?.toLocal() ?? DateTime.now();
    final rawMessages = entry['messages'];
    final messages = rawMessages is List
        ? rawMessages.whereType<Map>().map((rawMessage) {
            final message = Map<String, dynamic>.from(rawMessage);
            final senderId = message['userId']?.toString();
            final rawCreatedAt = message['createdAt']?.toString();
            return ChatMessage(
              sender: (message['senderName'] ?? 'Player').toString(),
              senderId: senderId,
              text: (message['text'] ?? '').toString(),
              sentAt:
                  DateTime.tryParse(rawCreatedAt ?? '')?.toLocal() ??
                  DateTime.now(),
              isMine: senderId != null && senderId == _currentUser?.id,
            );
          }).toList()
        : <ChatMessage>[];

    return ChatThread(
      id: id,
      title: (entry['title'] ?? 'Chat').toString(),
      type: (entry['type'] ?? 'direct').toString(),
      matchId: entry['matchId']?.toString(),
      lastActivity: lastActivity,
      unreadCount: _asInt(entry['unreadCount'], 0),
      messages: messages,
    );
  }

  SkillLevel _skillLevelFromRange(int min, int max) {
    final avg = ((min + max) / 2).round();
    if (avg <= 3) {
      return SkillLevel.beginner;
    }
    if (avg <= 6) {
      return SkillLevel.intermediate;
    }
    if (avg <= 8) {
      return SkillLevel.advanced;
    }
    return SkillLevel.mixed;
  }

  (int, int) _skillRangeForLevel(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return (1, 4);
      case SkillLevel.intermediate:
        return (4, 7);
      case SkillLevel.advanced:
        return (7, 10);
      case SkillLevel.mixed:
        return (1, 10);
    }
  }

  ActivityType _activityFromContent(String content) {
    final value = content.toLowerCase();
    if (value.contains('train')) {
      return ActivityType.training;
    }
    if (value.contains('sell') || value.contains('market')) {
      return ActivityType.market;
    }
    if (value.contains('invite')) {
      return ActivityType.gameInvite;
    }
    return ActivityType.meetup;
  }

  int _asInt(Object? value, int fallback) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  JoinRequestStatus _statusFromApi(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'approved':
      case 'accepted':
        return JoinRequestStatus.approved;
      case 'on_hold':
      case 'hold':
        return JoinRequestStatus.onHold;
      case 'rejected':
        return JoinRequestStatus.rejected;
      case 'full':
        return JoinRequestStatus.full;
      default:
        return JoinRequestStatus.pending;
    }
  }

  String _buildInviteLink({
    required String matchId,
    required String inviteCode,
  }) {
    return Uri.https('padelconnect.app', '/join', {
      'm': matchId,
      'code': inviteCode,
    }).toString();
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn(PadelAppController controller) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final languageCode = controller.generalSettings.languageCode;

    if (email.isEmpty || password.isEmpty) {
      _showSnack(
        appText(
          languageCode,
          'Enter email and password.',
          'أدخل البريد وكلمة المرور.',
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await controller.signInCurrentUser(email: email, password: password);
      if (!mounted) {
        return;
      }
      _showSnack(appText(languageCode, 'Signed in.', 'تم تسجيل الدخول.'));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack(
        appText(
          languageCode,
          'Invalid sign in data.',
          'بيانات تسجيل الدخول غير صحيحة.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = PadelAppScope.of(context);
    final languageCode = controller.generalSettings.languageCode;
    String tr(String english, String arabic) =>
        appText(languageCode, english, arabic);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.login),
            const SizedBox(width: 8),
            Text(tr('Sign In', 'تسجيل الدخول')),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(pagePadding(context)),
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.sports_tennis, size: 56, color: Color(0xFF0A6C4D)),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: tr(
                  'Email, username, or phone',
                  'البريد أو اسم المستخدم أو الهاتف',
                ),
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: tr('Password', 'كلمة المرور'),
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : () => _signIn(controller),
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  _loading
                      ? tr('Signing in...', 'جاري تسجيل الدخول...')
                      : tr('Sign In', 'تسجيل الدخول'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateAccountScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(tr('Create Account', 'إنشاء حساب')),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _photoBytes;
  bool _saving = false;
  String? _area;
  int _birthDay = 1;
  int _birthMonth = 1;
  int _birthYear = DateTime.now().year - 21;

  @override
  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 960,
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() => _photoBytes = bytes);
  }

  Future<void> _create(PadelAppController controller) async {
    final name = _nameController.text.trim();
    final handle = _handleController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final area = _area ?? controller.selectedArea;
    final languageCode = controller.generalSettings.languageCode;

    if (name.length < 2 ||
        handle.length < 2 ||
        phone.isEmpty ||
        email.isEmpty ||
        password.length < 6) {
      _showSnack(
        appText(
          languageCode,
          'Fill all fields first.',
          'املأ كل البيانات أولاً.',
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await controller.registerCurrentUser(
        name: name,
        handle: handle,
        email: email,
        phoneNumber: phone,
        birthDate: DateTime(_birthYear, _birthMonth, _birthDay),
        password: password,
        area: area,
        photoData: _photoBytes == null ? null : base64Encode(_photoBytes!),
      );
      if (!mounted) {
        return;
      }
      _showSnack(
        appText(
          languageCode,
          'Account created. Signed in.',
          'تم إنشاء الحساب وتسجيل الدخول.',
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(_friendlyCreateError(error, languageCode));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyCreateError(Object error, String languageCode) {
    final raw = error.toString();
    final message = raw.replaceFirst("Exception: ", "").trim();

    if (message.contains("Failed host lookup") ||
        message.contains("Connection refused") ||
        message.contains("SocketException")) {
      return kReleaseMode
          ? appText(
              languageCode,
              "Cannot reach service. Please try again shortly.",
              "تعذر الوصول للخدمة. حاول مرة ثانية بعد قليل.",
            )
          : "Cannot reach API. Start backend on http://127.0.0.1:3000";
    }

    if (message.contains("Missing production API URL")) {
      return appText(
        languageCode,
        "Production API URL is missing. Rebuild with PADEL_API_URL.",
        "رابط خدمة الإنتاج غير موجود. أعد البناء مع PADEL_API_URL.",
      );
    }

    if (message.contains("/users") && message.contains("404")) {
      return appText(
        languageCode,
        "API route not found. Check base URL and backend routes.",
        "مسار الخدمة غير موجود. تحقق من رابط الخدمة.",
      );
    }

    if (message.isEmpty) {
      return appText(
        languageCode,
        "Could not create account. Check data and API.",
        "تعذر إنشاء الحساب. تحقق من البيانات والخدمة.",
      );
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    final controller = PadelAppScope.of(context);
    final languageCode = controller.generalSettings.languageCode;
    String tr(String english, String arabic) =>
        appText(languageCode, english, arabic);
    _area ??= controller.selectedArea;
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(60, (index) => currentYear - 12 - index);
    final maxDay = DateUtils.getDaysInMonth(_birthYear, _birthMonth);
    if (_birthDay > maxDay) {
      _birthDay = maxDay;
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('Create User', 'إنشاء مستخدم'))),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(pagePadding(context)),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xFFE5E6DD),
                    backgroundImage: _photoBytes == null
                        ? null
                        : MemoryImage(_photoBytes!),
                    child: _photoBytes == null
                        ? const Icon(Icons.person, size: 34)
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: IconButton.filled(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: tr('Name', 'الاسم'),
                prefixIcon: const Icon(Icons.badge_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _handleController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: tr('Username', 'اسم المستخدم'),
                prefixIcon: const Icon(Icons.alternate_email),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: tr('Phone', 'الهاتف'),
                prefixIcon: const Icon(Icons.phone_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: tr('Email', 'البريد'),
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: tr('Password', 'كلمة المرور'),
                hintText: tr('Min 6 characters', '٦ أحرف على الأقل'),
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _area,
              decoration: InputDecoration(
                labelText: tr('Area', 'المنطقة'),
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
              ),
              items: controller.areas
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _area = value),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final fields = [
                  _birthDayField(maxDay),
                  _birthMonthField(),
                  _birthYearField(years),
                ];

                if (constraints.maxWidth < 390) {
                  return Column(
                    children: [
                      fields[0],
                      const SizedBox(height: 10),
                      fields[1],
                      const SizedBox(height: 10),
                      fields[2],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: fields[0]),
                    const SizedBox(width: 8),
                    Expanded(child: fields[1]),
                    const SizedBox(width: 8),
                    Expanded(child: fields[2]),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : () => _create(controller),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _saving
                      ? tr('Creating...', 'جاري الإنشاء...')
                      : tr('Create Account', 'إنشاء حساب'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.login),
              label: Text(tr('Back to Sign In', 'الرجوع لتسجيل الدخول')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _birthDayField(int maxDay) {
    final languageCode = PadelAppScope.of(context).generalSettings.languageCode;
    return DropdownButtonFormField<int>(
      initialValue: _birthDay,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: appText(languageCode, 'Day', 'اليوم'),
        border: const OutlineInputBorder(),
      ),
      items: List<int>.generate(maxDay, (index) => index + 1)
          .map((day) => DropdownMenuItem<int>(value: day, child: Text('$day')))
          .toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _birthDay = value);
      },
    );
  }

  Widget _birthMonthField() {
    final languageCode = PadelAppScope.of(context).generalSettings.languageCode;
    return DropdownButtonFormField<int>(
      initialValue: _birthMonth,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: appText(languageCode, 'Month', 'الشهر'),
        border: const OutlineInputBorder(),
      ),
      items: List<int>.generate(12, (index) => index + 1)
          .map(
            (month) =>
                DropdownMenuItem<int>(value: month, child: Text('$month')),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _birthMonth = value);
      },
    );
  }

  Widget _birthYearField(List<int> years) {
    final languageCode = PadelAppScope.of(context).generalSettings.languageCode;
    return DropdownButtonFormField<int>(
      initialValue: _birthYear,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: appText(languageCode, 'Year', 'السنة'),
        border: const OutlineInputBorder(),
      ),
      items: years
          .map(
            (year) => DropdownMenuItem<int>(value: year, child: Text('$year')),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _birthYear = value);
      },
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.controller, super.key});

  final PadelAppController controller;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchScope _scope = SearchScope.users;

  @override
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _match(String source, String query) {
    if (query.isEmpty) {
      return true;
    }
    return source.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final query = _searchController.text.trim().toLowerCase();
        final me = widget.controller.currentUser;
        final users = widget.controller.allUsers
            .where((user) => user.id != me?.id)
            .where(
              (user) =>
                  _match(user.name.toLowerCase(), query) ||
                  _match(user.handle.toLowerCase(), query) ||
                  _match(user.area.toLowerCase(), query),
            )
            .toList();
        final games = widget.controller.allMatches
            .where(
              (match) =>
                  _match(match.title.toLowerCase(), query) ||
                  _match(match.area.toLowerCase(), query) ||
                  _match(match.hostName.toLowerCase(), query),
            )
            .toList();
        final posts = widget.controller.allPosts
            .where(
              (post) =>
                  _match(post.content.toLowerCase(), query) ||
                  _match(post.author.toLowerCase(), query) ||
                  _match(post.area.toLowerCase(), query),
            )
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.search),
                SizedBox(width: 8),
                Text('Search'),
              ],
            ),
          ),
          body: ListView(
            padding: EdgeInsets.all(pagePadding(context)),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.manage_search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<SearchScope>(
                selected: <SearchScope>{_scope},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() => _scope = selection.first);
                },
                segments: const [
                  ButtonSegment<SearchScope>(
                    value: SearchScope.users,
                    icon: Icon(Icons.person_search_outlined),
                    label: Text('Users'),
                  ),
                  ButtonSegment<SearchScope>(
                    value: SearchScope.games,
                    icon: Icon(Icons.sports_tennis_outlined),
                    label: Text('Games'),
                  ),
                  ButtonSegment<SearchScope>(
                    value: SearchScope.posts,
                    icon: Icon(Icons.feed_outlined),
                    label: Text('Posts'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_scope == SearchScope.users) ...[
                if (users.isEmpty)
                  const _EmptyState(
                    title: 'No users',
                    subtitle: 'Try another search.',
                  )
                else
                  ...users.map(
                    (user) => Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user.name.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(user.name),
                        subtitle: Text('@${user.handle} • ${user.area}'),
                        trailing: TextButton.icon(
                          onPressed: () async {
                            final message = await widget.controller
                                .toggleFollowUser(user.id);
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(message)));
                          },
                          icon: Icon(
                            widget.controller.isFollowingUser(user.id)
                                ? Icons.person_remove_alt_1
                                : Icons.person_add_alt_1,
                            size: 18,
                          ),
                          label: Text(
                            widget.controller.isFollowingUser(user.id)
                                ? 'Unfollow'
                                : 'Follow',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              if (_scope == SearchScope.games) ...[
                if (games.isEmpty)
                  const _EmptyState(
                    title: 'No games',
                    subtitle: 'Try another search.',
                  )
                else
                  ...games.map(
                    (match) => Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: ListTile(
                        leading: Icon(
                          match.visibility == MatchVisibility.privateGame
                              ? Icons.lock_outline
                              : Icons.public,
                        ),
                        title: Text(match.title),
                        subtitle: Text(
                          '${match.area} • ${formatDate(match.startTime)} • ${match.joinedPlayers}/${match.maxPlayers}',
                        ),
                      ),
                    ),
                  ),
              ],
              if (_scope == SearchScope.posts) ...[
                if (posts.isEmpty)
                  const _EmptyState(
                    title: 'No posts',
                    subtitle: 'Try another search.',
                  )
                else
                  ...posts.map(
                    (post) => Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: ListTile(
                        leading: const Icon(Icons.feed),
                        title: Text(post.author),
                        subtitle: Text(
                          '${post.content}\n${post.area} • ${timeAgo(post.createdAt)}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({required this.controller, super.key});

  final PadelAppController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Row(
                children: [
                  Icon(Icons.group),
                  SizedBox(width: 8),
                  Text('Friends'),
                ],
              ),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Friends'),
                  Tab(text: 'Followers'),
                  Tab(text: 'Following'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _SocialUsersList(
                  controller: controller,
                  users: controller.friendUsers,
                  emptyTitle: 'No friends yet',
                  emptySubtitle: 'Follow users and get follow-back.',
                ),
                _SocialUsersList(
                  controller: controller,
                  users: controller.followers,
                  emptyTitle: 'No followers',
                  emptySubtitle: 'No one is following you yet.',
                ),
                _SocialUsersList(
                  controller: controller,
                  users: controller.following,
                  emptyTitle: 'No following',
                  emptySubtitle: 'Follow users from search.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SocialUsersList extends StatelessWidget {
  const _SocialUsersList({
    required this.controller,
    required this.users,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final PadelAppController controller;
  final List<SocialUser> users;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(pagePadding(context)),
        child: _EmptyState(title: emptyTitle, subtitle: emptySubtitle),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(pagePadding(context)),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: UserAvatar(name: user.name, photoData: user.photoData),
            title: Text(user.name),
            subtitle: Text('@${user.handle} • ${user.area}'),
            trailing: TextButton(
              onPressed: () async {
                final message = await controller.toggleFollowUser(user.id);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(message)));
              },
              child: Text(
                controller.isFollowingUser(user.id) ? 'Following' : 'Follow',
              ),
            ),
          ),
        );
      },
    );
  }
}

class CircleScreen extends StatelessWidget {
  const CircleScreen({required this.controller, super.key});

  final PadelAppController controller;

  @override
  Widget build(BuildContext context) {
    final circle = controller.circleContacts;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.people_outline),
            SizedBox(width: 8),
            Text('My Circle'),
          ],
        ),
      ),
      body: circle.isEmpty
          ? Padding(
              padding: EdgeInsets.all(pagePadding(context)),
              child: const _EmptyState(
                title: 'No circle yet',
                subtitle: 'Add players in Private tab.',
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(pagePadding(context)),
              itemCount: circle.length,
              itemBuilder: (context, index) {
                final user = circle[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user.name),
                    subtitle: Text(
                      '${user.area} • P${user.personalRating}/10 • G${user.publicRating.toStringAsFixed(1)}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const List<String> _titles = ['Play', 'Feed', 'Chat', 'Private'];
  static const List<IconData> _titleIcons = [
    Icons.sports_tennis,
    Icons.groups,
    Icons.chat_bubble,
    Icons.lock,
  ];

  void _openProfile(PadelAppController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProfileSheet(controller: controller),
    );
  }

  void _openSettings(PadelAppController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SettingsSheet(controller: controller),
    );
  }

  void _openSearch(PadelAppController controller) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = PadelAppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_titleIcons[_currentIndex], size: 22),
            const SizedBox(width: 8),
            Text(
              _titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => _openSearch(controller),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: controller.syncing ? 'Syncing' : 'Sync',
            onPressed: controller.syncing ? null : controller.syncFromApi,
            icon: controller.syncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => _openProfile(controller),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _openSettings(controller),
            icon: const Icon(Icons.tune),
          ),
          PopupMenuButton<String>(
            tooltip: 'Change area',
            icon: const Icon(Icons.location_on_outlined),
            onSelected: controller.setSelectedArea,
            itemBuilder: (context) {
              return controller.areas
                  .map(
                    (area) => PopupMenuItem<String>(
                      value: area,
                      child: Row(
                        children: [
                          Icon(
                            area == controller.selectedArea
                                ? Icons.check_circle
                                : Icons.location_on,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(area),
                        ],
                      ),
                    ),
                  )
                  .toList();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DiscoverTab(),
          CommunityTab(),
          ChatsTab(),
          PrivateGamesTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_tennis_outlined),
            selectedIcon: Icon(Icons.sports_tennis),
            label: 'Play',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock),
            label: 'Private',
          ),
        ],
      ),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({required this.controller});

  final PadelAppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    ImageProvider<Object>? profileImage;
    final photoData = user?.photoData;
    if (photoData != null && photoData.isNotEmpty) {
      try {
        profileImage = MemoryImage(base64Decode(photoData));
      } catch (_) {
        profileImage = null;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(pagePadding(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 34,
              backgroundImage: profileImage,
              child: profileImage == null
                  ? const Icon(Icons.person, size: 32)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              user?.name ?? 'My Profile',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _IconMetric(
                icon: Icons.people,
                value: '${controller.circleContacts.length}',
                label: 'Circle',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CircleScreen(controller: controller),
                    ),
                  );
                },
              ),
              _IconMetric(
                icon: Icons.group,
                value: '${controller.friendUsers.length}',
                label: 'Friends',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FriendsScreen(controller: controller),
                    ),
                  );
                },
              ),
              _IconMetric(
                icon: Icons.person_add_alt_1,
                value: '${controller.following.length}',
                label: 'Following',
              ),
              _IconMetric(
                icon: Icons.lock_clock,
                value: '${controller.myPrivateGames.length}',
                label: 'Private',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(user?.area ?? controller.selectedArea),
            subtitle: const Text('Area'),
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Friends'),
            subtitle: Text(
              '${controller.friendUsers.length} friends • ${controller.followers.length} followers • ${controller.following.length} following',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FriendsScreen(controller: controller),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('My Circle'),
            subtitle: Text('${controller.circleContacts.length} players'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CircleScreen(controller: controller),
                ),
              );
            },
          ),
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: Text('@${user.handle}'),
              subtitle: const Text('Username'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(user.phoneNumber),
              subtitle: const Text('Phone'),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(user.email),
              subtitle: const Text('Email'),
            ),
            ListTile(
              leading: const Icon(Icons.cake_outlined),
              title: Text(
                '${user.birthDate.day}/${user.birthDate.month}/${user.birthDate.year}',
              ),
              subtitle: const Text('Birthday'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.controller});

  final PadelAppController controller;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _compactView = true;
  bool _notify = true;
  bool _darkCourt = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(pagePadding(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: _compactView,
            onChanged: (value) => setState(() => _compactView = value),
            secondary: const Icon(Icons.phone_iphone),
            title: const Text('Compact'),
          ),
          SwitchListTile.adaptive(
            value: _notify,
            onChanged: (value) => setState(() => _notify = value),
            secondary: const Icon(Icons.notifications_none),
            title: const Text('Notifications'),
          ),
          SwitchListTile.adaptive(
            value: _darkCourt,
            onChanged: (value) => setState(() => _darkCourt = value),
            secondary: const Icon(Icons.palette_outlined),
            title: const Text('Dark Court'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8A2B16),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                widget.controller.signOut();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconMetric extends StatelessWidget {
  const _IconMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 96),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(
              '$value $label',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  SkillLevel? _filter;

  @override
  Widget build(BuildContext context) {
    final controller = PadelAppScope.of(context);
    final filteredMatches = controller.nearbyMatches
        .where((match) => _filter == null || match.skillLevel == _filter)
        .toList();

    return ListView(
      padding: EdgeInsets.all(pagePadding(context)),
      children: [
        _StatsBanner(playersCount: controller.nearbyPlayersCount),
        const SizedBox(height: 16),
        Text(
          'Games',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All levels'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            ...SkillLevel.values.map(
              (level) => ChoiceChip(
                label: Text(skillLabel(level)),
                selected: _filter == level,
                onSelected: (_) => setState(() => _filter = level),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filteredMatches.isEmpty)
          const _EmptyState(
            title: 'No matches for this filter.',
            subtitle:
                'Try another skill level or switch area from the top-right menu.',
          ),
        ...filteredMatches.map(
          (match) => _MatchCard(
            match: match,
            onJoin: () async {
              final message = await controller.joinPublicMatch(match.id);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            },
          ),
        ),
      ],
    );
  }
}

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  final TextEditingController _postController = TextEditingController();

  @override
  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PadelAppScope.of(context);

    return ListView(
      padding: EdgeInsets.all(pagePadding(context)),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _postController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Post about games, training, or social meetup...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () {
                      controller.createPost(_postController.text);
                      _postController.clear();
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...controller.feedPosts.map(
          (post) => Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(post.author.substring(0, 1).toUpperCase()),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.author,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${post.area} • ${timeAgo(post.createdAt)}',
                              style: const TextStyle(
                                color: Color(0xFF63635D),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(activityLabel(post.activityType)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(post.content),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => controller.likePost(post.id),
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: Text('${post.likes}'),
                      ),
                      TextButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.mode_comment_outlined, size: 18),
                        label: Text('${post.comments}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PadelAppScope.of(context);
    final threads = controller.threads;

    if (threads.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: _EmptyState(
          title: 'No chats yet',
          subtitle: 'Join a game or create a private match to start chatting.',
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(pagePadding(context)),
      itemCount: threads.length,
      separatorBuilder: (_, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final thread = threads[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.group)),
            title: Text(thread.title),
            subtitle: Text(
              thread.preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  shortTime(thread.lastActivity),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF63635D),
                  ),
                ),
                const SizedBox(height: 4),
                if (thread.unreadCount > 0)
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFF0A6C4D),
                    child: Text(
                      '${thread.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
            onTap: () {
              controller.markThreadRead(thread.id);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatThreadScreen(threadId: thread.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({required this.threadId, super.key});

  final String threadId;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PadelAppScope.of(context);
    final thread = controller.getThreadById(widget.threadId);
    if (thread == null) {
      return const Scaffold(
        body: Center(child: Text('Chat thread not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(thread.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: thread.messages.length,
              itemBuilder: (context, index) {
                final message = thread.messages[index];
                return Align(
                  alignment: message.isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: message.isMine
                          ? const Color(0xFF0A6C4D)
                          : const Color(0xFFE5E6DD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!message.isMine)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.sender,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Text(
                          message.text,
                          style: TextStyle(
                            color: message.isMine
                                ? Colors.white
                                : const Color(0xFF1F1F1C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shortTime(message.sentAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: message.isMine
                                ? Colors.white.withValues(alpha: 0.8)
                                : const Color(0xFF63635D),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Write a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      controller.sendMessage(
                        widget.threadId,
                        _messageController.text,
                      );
                      _messageController.clear();
                    },
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivateGamesTab extends StatefulWidget {
  const PrivateGamesTab({super.key});

  @override
  State<PrivateGamesTab> createState() => _PrivateGamesTabState();
}

class _PrivateGamesTabState extends State<PrivateGamesTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _joinLinkController = TextEditingController();
  final TextEditingController _newPlayerNameController =
      TextEditingController();
  final TextEditingController _newPlayerPhoneController =
      TextEditingController();
  final TextEditingController _newPlayerNotesController =
      TextEditingController();
  String? _area;
  String? _newPlayerArea;
  SkillLevel _skill = SkillLevel.intermediate;
  InviteAudience _inviteAudience = InviteAudience.closeFriends;
  GameTone _gameTone = GameTone.balanced;
  CircuitSource _circuitSource = CircuitSource.addedByMe;
  final Set<PlayerTag> _requiredTags = {};
  final Set<String> _customRecipientIds = {};
  final Set<PlayerTag> _newPlayerTags = {};
  DateTime _date = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  RangeValues _ratingRange = const RangeValues(6, 10);
  int _newPersonalRating = 6;
  double _newPublicRating = 6;
  CircleRelationship _newRelationship = CircleRelationship.closeFriend;

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  @override
  void dispose() {
    _titleController.dispose();
    _joinLinkController.dispose();
    _newPlayerNameController.dispose();
    _newPlayerPhoneController.dispose();
    _newPlayerNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PadelAppScope.of(context);
    _area ??= controller.selectedArea;
    _newPlayerArea ??= controller.selectedArea;

    final suggestedRecipients = controller.suggestPrivateInviteTargets(
      audience: _inviteAudience,
      tone: _gameTone,
      minPersonalRating: _ratingRange.start.round(),
      maxPersonalRating: _ratingRange.end.round(),
      requiredTags: _requiredTags,
      customRecipientIds: _customRecipientIds.toList(),
    );
    final circuitPool = controller.contactsForCircuit(_circuitSource);
    final requesterName = controller.currentUser?.name ?? '';
    final myRequests = requesterName.isEmpty
        ? const <JoinRequest>[]
        : controller.requestsByPlayerName(requesterName);

    return ListView(
      padding: EdgeInsets.all(pagePadding(context)),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Private Match',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Private circle only'),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Match title',
                    hintText: 'Family Game Night',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _area,
                  decoration: const InputDecoration(
                    labelText: 'Area',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.areas
                      .map(
                        (area) => DropdownMenuItem<String>(
                          value: area,
                          child: Text(area),
                        ),
                      )
                      .toList(),
                  onChanged: (area) {
                    setState(() {
                      _area = area;
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<SkillLevel>(
                  initialValue: _skill,
                  decoration: const InputDecoration(
                    labelText: 'Skill level',
                    border: OutlineInputBorder(),
                  ),
                  items: SkillLevel.values
                      .map(
                        (level) => DropdownMenuItem<SkillLevel>(
                          value: level,
                          child: Text(skillLabel(level)),
                        ),
                      )
                      .toList(),
                  onChanged: (skill) {
                    if (skill != null) {
                      setState(() {
                        _skill = skill;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<InviteAudience>(
                  initialValue: _inviteAudience,
                  decoration: const InputDecoration(
                    labelText: 'Send invites to',
                    border: OutlineInputBorder(),
                  ),
                  items: InviteAudience.values
                      .map(
                        (audience) => DropdownMenuItem<InviteAudience>(
                          value: audience,
                          child: Text(audienceLabel(audience)),
                        ),
                      )
                      .toList(),
                  onChanged: (audience) {
                    if (audience == null) {
                      return;
                    }
                    setState(() {
                      _inviteAudience = audience;
                      if (_inviteAudience != InviteAudience.custom) {
                        _customRecipientIds.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<GameTone>(
                  initialValue: _gameTone,
                  decoration: const InputDecoration(
                    labelText: 'Game style',
                    border: OutlineInputBorder(),
                  ),
                  items: GameTone.values
                      .map(
                        (tone) => DropdownMenuItem<GameTone>(
                          value: tone,
                          child: Text(gameToneLabel(tone)),
                        ),
                      )
                      .toList(),
                  onChanged: (tone) {
                    if (tone != null) {
                      setState(() {
                        _gameTone = tone;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Your personal rating range (${_ratingRange.start.round()}-${_ratingRange.end.round()})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                RangeSlider(
                  values: _ratingRange,
                  divisions: 9,
                  min: 1,
                  max: 10,
                  labels: RangeLabels(
                    _ratingRange.start.round().toString(),
                    _ratingRange.end.round().toString(),
                  ),
                  onChanged: (values) {
                    setState(() {
                      _ratingRange = values;
                    });
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'Required tags',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PlayerTag.values.map((tag) {
                    final selected = _requiredTags.contains(tag);
                    return FilterChip(
                      selected: selected,
                      label: Text(playerTagLabel(tag)),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _requiredTags.add(tag);
                          } else {
                            _requiredTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_inviteAudience == InviteAudience.custom) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Circuit source',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CircuitSource.values.map((source) {
                      return ChoiceChip(
                        selected: _circuitSource == source,
                        label: Text(circuitSourceLabel(source)),
                        onSelected: (_) {
                          setState(() {
                            final nextPoolIds = controller
                                .contactsForCircuit(source)
                                .map((player) => player.id)
                                .toSet();
                            _circuitSource = source;
                            _customRecipientIds.removeWhere(
                              (id) => !nextPoolIds.contains(id),
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Custom recipients',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'From: ${circuitSourceLabel(_circuitSource)} (${circuitPool.length})',
                    style: const TextStyle(
                      color: Color(0xFF63635D),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: circuitPool.map((player) {
                      final selected = _customRecipientIds.contains(player.id);
                      return FilterChip(
                        selected: selected,
                        label: Text(
                          '${player.name} (${player.personalRating})',
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _customRecipientIds.add(player.id);
                            } else {
                              _customRecipientIds.remove(player.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                if (suggestedRecipients.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested players (${suggestedRecipients.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: suggestedRecipients
                            .map(
                              (player) => Chip(
                                label: Text(
                                  '${player.name} ${player.personalRating}/10',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  )
                else
                  const Text(
                    'No match',
                    style: TextStyle(color: Color(0xFF63635D)),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 180),
                            ),
                            initialDate: _date,
                          );
                          if (selected != null) {
                            setState(() => _date = selected);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          '${_date.day}/${_date.month}/${_date.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showTimePicker(
                            context: context,
                            initialTime: _time,
                          );
                          if (selected != null) {
                            setState(() => _time = selected);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(_time.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final area = _area;
                      if (title.isEmpty || area == null) {
                        _showSnack(context, 'Please fill title and area.');
                        return;
                      }
                      if (_inviteAudience == InviteAudience.custom &&
                          _customRecipientIds.isEmpty) {
                        _showSnack(
                          context,
                          'Select at least one custom recipient.',
                        );
                        return;
                      }

                      final start = DateTime(
                        _date.year,
                        _date.month,
                        _date.day,
                        _time.hour,
                        _time.minute,
                      );
                      final match = controller.createPrivateGame(
                        title: title,
                        area: area,
                        skill: _skill,
                        startTime: start,
                        inviteAudience: _inviteAudience,
                        tone: _gameTone,
                        minPersonalRating: _ratingRange.start.round(),
                        maxPersonalRating: _ratingRange.end.round(),
                        requiredTags: _requiredTags,
                        customRecipientIds: _customRecipientIds.toList(),
                      );
                      final invitedNames = controller
                          .invitationsForMatch(match.id)
                          .map(
                            (invite) =>
                                controller.contactById(invite.playerId)?.name,
                          )
                          .whereType<String>()
                          .toList();
                      _titleController.clear();

                      showDialog<void>(
                        context: context,
                        builder: (context) {
                          final inviteLink = match.inviteLink;
                          return AlertDialog(
                            title: const Text('Private Match Created'),
                            content: Text(
                              'Invite code: ${match.inviteCode}\n\nInvite link:\n${inviteLink ?? '-'}\n\n'
                              'Audience: ${audienceLabel(_inviteAudience)}\n'
                              'Invited: ${invitedNames.isEmpty ? 'No one matched filters yet' : invitedNames.join(', ')}',
                            ),
                            actions: [
                              if (inviteLink != null)
                                TextButton(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: inviteLink),
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text('Invite link copied.'),
                                        ),
                                      );
                                  },
                                  child: const Text('Copy Link'),
                                ),
                              if (inviteLink != null)
                                TextButton(
                                  onPressed: () async {
                                    await Share.share(
                                      'Join my private padel game:\n$inviteLink',
                                    );
                                  },
                                  child: const Text('Share'),
                                ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.lock),
                    label: const Text('Generate Invite Code'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join by Link',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _joinLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Invite link',
                    hintText: 'https://padelconnect.app/join?m=...&code=...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(controller.currentUser?.name ?? 'No account'),
                  subtitle: const Text(
                    'Request will be sent from this profile',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final message = await controller.requestPrivateJoinByLink(
                        inviteLink: _joinLinkController.text,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      if (message.contains('sent') ||
                          message.contains('Joined')) {
                        _joinLinkController.clear();
                      }
                      _showSnack(context, message);
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send Join Request'),
                  ),
                ),
                if (myRequests.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Your latest requests',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...myRequests.take(4).map((request) {
                    final match = controller.matchById(request.matchId);
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              match?.title ?? 'Private game',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(joinRequestStatusLabel(request.status)),
                            side: BorderSide(
                              color: joinRequestStatusColor(request.status),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Circle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set your own private rating + public rating for each player.',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPlayerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Player name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPlayerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone / contact',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _newPlayerArea,
                  decoration: const InputDecoration(
                    labelText: 'Area',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.areas
                      .map(
                        (area) => DropdownMenuItem<String>(
                          value: area,
                          child: Text(area),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _newPlayerArea = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<CircleRelationship>(
                  initialValue: _newRelationship,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                  ),
                  items: CircleRelationship.values
                      .map(
                        (relationship) => DropdownMenuItem<CircleRelationship>(
                          value: relationship,
                          child: Text(relationshipLabel(relationship)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _newRelationship = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Your rating (${_newPersonalRating.toStringAsFixed(0)}/10)',
                ),
                Slider(
                  value: _newPersonalRating.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _newPersonalRating.toString(),
                  onChanged: (value) {
                    setState(() {
                      _newPersonalRating = value.round();
                    });
                  },
                ),
                Text(
                  'Public rating (${_newPublicRating.toStringAsFixed(1)}/10)',
                ),
                Slider(
                  value: _newPublicRating,
                  min: 1,
                  max: 10,
                  divisions: 18,
                  label: _newPublicRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _newPublicRating = value;
                    });
                  },
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PlayerTag.values.map((tag) {
                    final selected = _newPlayerTags.contains(tag);
                    return FilterChip(
                      selected: selected,
                      label: Text(playerTagLabel(tag)),
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _newPlayerTags.add(tag);
                          } else {
                            _newPlayerTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPlayerNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Private notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final name = _newPlayerNameController.text.trim();
                      final phone = _newPlayerPhoneController.text.trim();
                      final area = _newPlayerArea;
                      if (name.isEmpty || phone.isEmpty || area == null) {
                        _showSnack(
                          context,
                          'Name, contact, and area are required.',
                        );
                        return;
                      }
                      controller.addPrivateContact(
                        name: name,
                        phone: phone,
                        area: area,
                        personalRating: _newPersonalRating,
                        publicRating: _newPublicRating,
                        relationship: _newRelationship,
                        tags: _newPlayerTags,
                        notes: _newPlayerNotesController.text,
                      );
                      _newPlayerNameController.clear();
                      _newPlayerPhoneController.clear();
                      _newPlayerNotesController.clear();
                      setState(() {
                        _newPlayerTags.clear();
                        _newPersonalRating = 6;
                        _newPublicRating = 6;
                        _newRelationship = CircleRelationship.closeFriend;
                      });
                      _showSnack(
                        context,
                        'Player added to your private circle.',
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add To Circle'),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        'Added by me: ${controller.addedByMeContacts.length}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Added me: ${controller.addedMeContacts.length}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Follow-back: ${controller.mutualContacts.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...controller.circleContacts.take(6).map((player) {
                  final addedByMe = controller.isAddedByMe(player.id);
                  final addedMe = controller.isAddedMe(player.id);
                  final mutual = controller.isMutual(player.id);

                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                player.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (mutual)
                              const Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text('Follow-back'),
                              )
                            else if (addedByMe)
                              const Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text('Added'),
                              )
                            else if (addedMe)
                              const Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text('Added me'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your rating ${player.personalRating}/10 • Public ${player.publicRating.toStringAsFixed(1)}/10',
                        ),
                        Text(
                          '${player.area} • ${player.phone}',
                          style: const TextStyle(
                            color: Color(0xFF63635D),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: player.tags
                              .map(
                                (tag) => Chip(label: Text(playerTagLabel(tag))),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 6),
                        if (!addedByMe)
                          FilledButton.tonalIcon(
                            onPressed: () {
                              controller.addAccountToMyList(player.id);
                              _showSnack(
                                context,
                                addedMe
                                    ? '${player.name} added back.'
                                    : '${player.name} added to your list.',
                              );
                            },
                            icon: const Icon(Icons.person_add_alt_1),
                            label: Text(addedMe ? 'Add Back' : 'Add'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              controller.removeAccountFromMyList(player.id);
                              _showSnack(
                                context,
                                '${player.name} removed from your list.',
                              );
                            },
                            icon: const Icon(Icons.person_remove_alt_1),
                            label: const Text('Remove'),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your Private Games',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (controller.myPrivateGames.isEmpty)
          const _EmptyState(
            title: 'No private games yet.',
            subtitle: 'Create one to start inviting your friends.',
          ),
        ...controller.myPrivateGames.map((match) {
          final pendingRequests = controller.pendingRequestsForMatch(match.id);
          final allRequests = controller.allRequestsForMatch(match.id);
          final inviteLink = match.inviteLink;
          final invitations = controller.invitationsForMatch(match.id);
          final invitedNames = invitations
              .map((invite) => controller.contactById(invite.playerId)?.name)
              .whereType<String>()
              .toList();

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${formatDate(match.startTime)} • ${match.area}'),
                  Text('Players: ${match.joinedPlayers}/${match.maxPlayers}'),
                  if (invitations.isNotEmpty)
                    Text(
                      'Invited (${invitations.length}): ${invitedNames.join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF63635D),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EFE8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Code: ${match.inviteCode ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (inviteLink != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0EA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Link: $inviteLink',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () async {
                          final code = match.inviteCode;
                          if (code == null) {
                            return;
                          }
                          await Clipboard.setData(ClipboardData(text: code));
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('Invite code copied.'),
                              ),
                            );
                        },
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy invite code',
                      ),
                      if (inviteLink != null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: inviteLink),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Invite link copied.'),
                                ),
                              );
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('Copy Link'),
                        ),
                      if (inviteLink != null)
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            await Share.share(
                              'Join my private padel game:\n$inviteLink',
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share Link'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Join Requests',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (allRequests.isEmpty)
                    const Text(
                      'No requests yet.',
                      style: TextStyle(color: Color(0xFF63635D)),
                    ),
                  if (pendingRequests.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Active queue: ${pendingRequests.length}',
                        style: const TextStyle(
                          color: Color(0xFF63635D),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ...allRequests.map(
                    (request) => Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.requesterName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Requested ${timeAgo(request.requestedAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF63635D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(joinRequestStatusLabel(request.status)),
                            side: BorderSide(
                              color: joinRequestStatusColor(request.status),
                            ),
                          ),
                          if (request.status == JoinRequestStatus.pending ||
                              request.status == JoinRequestStatus.onHold)
                            IconButton(
                              tooltip: 'Approve',
                              onPressed: () async {
                                final approved = await controller
                                    .approveJoinRequest(request.id);
                                final message = approved
                                    ? '${request.requesterName} approved.'
                                    : 'Game is full. Status moved to "Game full".';
                                if (!context.mounted) {
                                  return;
                                }
                                _showSnack(context, message);
                              },
                              icon: const Icon(
                                Icons.check_circle,
                                color: Color(0xFF0A6C4D),
                              ),
                            ),
                          if (request.status == JoinRequestStatus.pending)
                            IconButton(
                              tooltip: 'Hold',
                              onPressed: () async {
                                await controller.holdJoinRequest(request.id);
                                if (!context.mounted) {
                                  return;
                                }
                                _showSnack(
                                  context,
                                  '${request.requesterName} moved to hold.',
                                );
                              },
                              icon: const Icon(
                                Icons.pause_circle,
                                color: Color(0xFF6B5DAB),
                              ),
                            ),
                          if (request.status == JoinRequestStatus.pending ||
                              request.status == JoinRequestStatus.onHold ||
                              request.status == JoinRequestStatus.full)
                            IconButton(
                              tooltip: 'Reject',
                              onPressed: () async {
                                await controller.rejectJoinRequest(request.id);
                                if (!context.mounted) {
                                  return;
                                }
                                _showSnack(
                                  context,
                                  '${request.requesterName} request rejected.',
                                );
                              },
                              icon: const Icon(
                                Icons.cancel,
                                color: Color(0xFF8A2B16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatsBanner extends StatelessWidget {
  const _StatsBanner({required this.playersCount});

  final int playersCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(pagePadding(context)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A6C4D), Color(0xFF126D9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_tennis, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Nearby',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Quick play',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$playersCount active players in your selected area',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onJoin});

  final PadelMatch match;
  final Future<void> Function() onJoin;

  @override
  Widget build(BuildContext context) {
    final isPublic = match.visibility == MatchVisibility.publicGame;

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPublic ? Icons.public : Icons.lock_outline,
                  size: 18,
                  color: isPublic
                      ? const Color(0xFF0A6C4D)
                      : const Color(0xFF9A6512),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    match.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${match.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Color(0xFF63635D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${match.courtName} • ${match.area}'),
            Text('${formatDate(match.startTime)} • Host: ${match.hostName}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(skillLabel(match.skillLevel))),
                Chip(
                  label: Text(
                    '${match.joinedPlayers}/${match.maxPlayers} players',
                  ),
                ),
                Chip(label: Text(isPublic ? 'Public game' : 'Private game')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (isPublic)
                  FilledButton(
                    onPressed: match.hasOpenSpot ? onJoin : null,
                    child: Text(match.hasOpenSpot ? 'Join Game' : 'Game Full'),
                  )
                else
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Invite-only game. Contact host in chat.',
                            ),
                          ),
                        );
                    },
                    child: const Text('Request Invite'),
                  ),
                const SizedBox(width: 10),
                if (match.visibility == MatchVisibility.privateGame &&
                    match.inviteCode != null)
                  Text(
                    'Code: ${match.inviteCode}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )
                else
                  Text('${match.openSpots} spots left'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

double pagePadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 360) {
    return 10;
  }
  if (width < 420) {
    return 12;
  }
  return 16;
}

String skillLabel(SkillLevel level) {
  switch (level) {
    case SkillLevel.beginner:
      return 'Beginner';
    case SkillLevel.intermediate:
      return 'Intermediate';
    case SkillLevel.advanced:
      return 'Advanced';
    case SkillLevel.mixed:
      return 'Mixed';
  }
}

String ratingLabelForValue(int rating) {
  if (rating <= 3) {
    return 'Beginner';
  }
  if (rating <= 6) {
    return 'Intermediate';
  }
  return 'Pro';
}

String activityLabel(ActivityType type) {
  switch (type) {
    case ActivityType.gameInvite:
      return 'Invite';
    case ActivityType.training:
      return 'Training';
    case ActivityType.meetup:
      return 'Meetup';
    case ActivityType.market:
      return 'Market';
  }
}

String audienceLabel(InviteAudience audience) {
  switch (audience) {
    case InviteAudience.closeFriends:
      return 'Friends';
    case InviteAudience.followBackOnly:
      return 'Follow-back only';
    case InviteAudience.custom:
      return 'Custom list';
  }
}

String circuitSourceLabel(CircuitSource source) {
  switch (source) {
    case CircuitSource.addedByMe:
      return 'Added by me';
    case CircuitSource.addedMe:
      return 'Added me';
    case CircuitSource.mutual:
      return 'Follow-back';
    case CircuitSource.allAppUsers:
      return 'All app users';
  }
}

String gameToneLabel(GameTone tone) {
  switch (tone) {
    case GameTone.friendly:
      return 'Friendly';
    case GameTone.balanced:
      return 'Balanced';
    case GameTone.competitive:
      return 'Competitive';
  }
}

String relationshipLabel(CircleRelationship relationship) {
  switch (relationship) {
    case CircleRelationship.closeFriend:
      return 'Close Friend';
    case CircleRelationship.mutualFollow:
      return 'Follow-back';
    case CircleRelationship.followerOnly:
      return 'Follower only';
  }
}

String playerTagLabel(PlayerTag tag) {
  switch (tag) {
    case PlayerTag.favorite:
      return 'Favorite';
    case PlayerTag.competitive:
      return 'Competitive';
    case PlayerTag.friendly:
      return 'Friendly';
    case PlayerTag.reliable:
      return 'Reliable';
    case PlayerTag.backup:
      return 'Backup';
    case PlayerTag.oftenAvailable:
      return 'Often available';
  }
}

String joinRequestStatusLabel(JoinRequestStatus status) {
  switch (status) {
    case JoinRequestStatus.pending:
      return 'Pending';
    case JoinRequestStatus.onHold:
      return 'On hold';
    case JoinRequestStatus.approved:
      return 'Approved';
    case JoinRequestStatus.rejected:
      return 'Rejected';
    case JoinRequestStatus.full:
      return 'Game full';
  }
}

Color joinRequestStatusColor(JoinRequestStatus status) {
  switch (status) {
    case JoinRequestStatus.pending:
      return const Color(0xFF9A6512);
    case JoinRequestStatus.onHold:
      return const Color(0xFF6B5DAB);
    case JoinRequestStatus.approved:
      return const Color(0xFF0A6C4D);
    case JoinRequestStatus.rejected:
      return const Color(0xFF8A2B16);
    case JoinRequestStatus.full:
      return const Color(0xFF63635D);
  }
}

String formatDate(DateTime value) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final dateOnly = DateTime(value.year, value.month, value.day);
  final todayOnly = DateTime(now.year, now.month, now.day);
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  if (dateOnly == todayOnly) {
    return 'Today at $hour:$minute';
  }
  if (dateOnly == tomorrow) {
    return 'Tomorrow at $hour:$minute';
  }

  return '${value.day}/${value.month}/${value.year} at $hour:$minute';
}

String shortTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String timeAgo(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  return '${difference.inDays}d ago';
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
