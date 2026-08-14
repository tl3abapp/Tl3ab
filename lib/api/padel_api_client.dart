import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const productionApiBaseUrl = 'https://tl3ab.onrender.com/api';

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.path});

  final String message;
  final int? statusCode;
  final String? path;

  @override
  String toString() => message;
}

class PadelApiClient {
  PadelApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = _resolveBaseUrl(baseUrl);

  final http.Client _client;
  final String baseUrl;
  String? _authToken;

  bool get hasAuthToken => _authToken != null && _authToken!.isNotEmpty;

  void setAuthToken(String? token) {
    final trimmed = token?.trim();
    _authToken = trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _authHeaders => {
    if (hasAuthToken) 'authorization': 'Bearer $_authToken',
  };

  Map<String, String> get _jsonHeaders => {
    'content-type': 'application/json',
    ..._authHeaders,
  };

  static String _resolveBaseUrl(String? inputBaseUrl) {
    final envBaseUrl = const String.fromEnvironment(
      'PADEL_API_URL',
      defaultValue: '',
    ).trim();
    final configured = (inputBaseUrl ?? envBaseUrl).trim();

    if (configured.isNotEmpty) {
      return configured.replaceAll(RegExp(r'/+$'), '');
    }

    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        return 'http://127.0.0.1:3000';
      }
      return '${Uri.base.origin}/api';
    }

    // Mobile debug builds launched from Xcode run on the device/simulator, so
    // 127.0.0.1 points at that device instead of the Mac backend. Use the
    // public API by default, and pass PADEL_API_URL only when local dev needs it.
    return productionApiBaseUrl;
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    return _getList('/users');
  }

  Future<List<Map<String, dynamic>>> fetchPosts() async {
    return _getList('/posts');
  }

  Future<Map<String, dynamic>> createPost({
    required String authorId,
    required String content,
  }) async {
    return _postJson('/posts', {'authorId': authorId, 'content': content});
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    return _postJson('/posts/$postId/like', {});
  }

  Future<Map<String, dynamic>> commentPost(String postId) async {
    return _postJson('/posts/$postId/comment', {});
  }

  Future<void> deletePost({
    required String postId,
    required String authorId,
  }) async {
    await _deleteJson('/posts/$postId', {'authorId': authorId});
  }

  Future<List<Map<String, dynamic>>> fetchMatches({String? userId}) async {
    final query = userId == null || userId.trim().isEmpty
        ? ''
        : '?userId=${Uri.encodeQueryComponent(userId.trim())}';
    return _getList('/matches$query');
  }

  Future<List<Map<String, dynamic>>> fetchFollowers(String userId) async {
    return _getList('/users/$userId/followers');
  }

  Future<List<Map<String, dynamic>>> fetchFollowing(String userId) async {
    return _getList('/users/$userId/following');
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    return _getList('/notifications/$userId');
  }

  Future<List<Map<String, dynamic>>> fetchChatThreads(String userId) async {
    return _getList('/chats/$userId');
  }

  Future<Map<String, dynamic>> ensureDirectThread({
    required String userId,
    required String targetUserId,
  }) async {
    return _postJson('/chats/direct', {
      'userId': userId,
      'targetUserId': targetUserId,
    });
  }

  Future<Map<String, dynamic>> ensureMatchThread({
    required String matchId,
    required String userId,
  }) async {
    return _postJson('/chats/match/$matchId', {'userId': userId});
  }

  Future<Map<String, dynamic>> sendChatMessage({
    required String threadId,
    required String userId,
    required String text,
  }) async {
    return _postJson('/chats/$threadId/messages', {
      'userId': userId,
      'text': text,
    });
  }

  Future<Map<String, dynamic>> markNotificationRead(
    String notificationId,
  ) async {
    return _postJson('/notifications/$notificationId/read', {});
  }

  Future<void> followUser({
    required String userId,
    required String targetId,
  }) async {
    await _postJson('/users/$userId/follow/$targetId', {});
  }

  Future<void> unfollowUser({
    required String userId,
    required String targetId,
  }) async {
    await _delete('/users/$userId/follow/$targetId');
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String handle,
    required String email,
    required String phoneNumber,
    required String birthDateIso,
    required String password,
    required String area,
    String? photoData,
    int skillLevel = 5,
  }) async {
    return _postJson('/users', {
      'name': name,
      'handle': handle,
      'email': email,
      'phoneNumber': phoneNumber,
      'birthDate': birthDateIso,
      'password': password,
      'area': area,
      'skillLevel': skillLevel,
      if (photoData != null && photoData.isNotEmpty) 'photoData': photoData,
    });
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    return _postJson('/users/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> updateUserPhoto({
    required String userId,
    required String? photoData,
  }) async {
    return _postJson('/users/$userId/photo', {'photoData': photoData});
  }

  Future<Map<String, dynamic>> deactivateUser({
    required String userId,
    int days = 40,
  }) async {
    return _postJson('/users/$userId/deactivate', {'days': days});
  }

  Future<Map<String, dynamic>> reactivateUser({required String userId}) async {
    return _postJson('/users/$userId/reactivate', {});
  }

  Future<void> deleteUser({required String userId}) async {
    await _delete('/users/$userId');
  }

  Future<Map<String, dynamic>> joinMatch({
    required String matchId,
    required String userId,
    String? inviteCode,
    String? side,
  }) async {
    return _postJson('/matches/$matchId/join', {
      'userId': userId,
      if (inviteCode != null && inviteCode.isNotEmpty) 'inviteCode': inviteCode,
      if (side != null && side.isNotEmpty) 'side': side,
    });
  }

  Future<void> leaveMatch({
    required String matchId,
    required String userId,
  }) async {
    await _postJson('/matches/$matchId/leave', {'userId': userId});
  }

  Future<Map<String, dynamic>> createMatch({
    required String hostId,
    required String title,
    required String area,
    required String courtName,
    required String startsAtIso,
    required bool isPrivate,
    required String targetScope,
    List<String> inviteUserIds = const [],
    int maxPlayers = 4,
    int skillMin = 1,
    int skillMax = 10,
    String? hostSide,
    String? courtPhotoData,
    List<String> timeOptions = const [],
  }) async {
    return _postJson('/matches', {
      'hostId': hostId,
      'title': title,
      'area': area,
      'courtName': courtName,
      if (courtPhotoData != null && courtPhotoData.isNotEmpty)
        'courtPhotoData': courtPhotoData,
      'startsAt': startsAtIso,
      'isPrivate': isPrivate,
      'targetScope': targetScope,
      'maxPlayers': maxPlayers,
      'skillMin': skillMin,
      'skillMax': skillMax,
      if (hostSide != null && hostSide.isNotEmpty) 'hostSide': hostSide,
      if (inviteUserIds.isNotEmpty) 'inviteUserIds': inviteUserIds,
      if (timeOptions.length > 1) 'timeOptions': timeOptions,
    });
  }

  Future<void> moderateJoinRequest({
    required String matchId,
    required String participantId,
    required String hostId,
    required String action,
  }) async {
    await _postJson('/matches/$matchId/requests/$participantId/$action', {
      'hostId': hostId,
    });
  }

  Future<Map<String, dynamic>> updateMatchPrivacy({
    required String matchId,
    required String hostId,
    required bool isPrivate,
    required String targetScope,
    List<String> inviteUserIds = const [],
  }) async {
    return _postJson('/matches/$matchId/privacy', {
      'hostId': hostId,
      'isPrivate': isPrivate,
      'targetScope': targetScope,
      if (inviteUserIds.isNotEmpty) 'inviteUserIds': inviteUserIds,
    });
  }

  Future<Map<String, dynamic>> updateMatchDetails({
    required String matchId,
    required String hostId,
    String? startsAtIso,
    String? courtName,
    String? courtPhotoData,
    List<String> timeOptions = const [],
  }) async {
    final body = <String, dynamic>{'hostId': hostId};
    if (startsAtIso != null && startsAtIso.isNotEmpty) {
      body['startsAt'] = startsAtIso;
    }
    if (courtName != null) {
      body['courtName'] = courtName;
    }
    if (courtPhotoData != null) {
      body['courtPhotoData'] = courtPhotoData;
    }
    if (startsAtIso != null && startsAtIso.isNotEmpty) {
      body['timeOptions'] = timeOptions;
    }
    return _postJson('/matches/$matchId/details', body);
  }

  Future<Map<String, dynamic>> voteMatchTimeOption({
    required String matchId,
    required String userId,
    required String optionId,
  }) async {
    return _postJson('/matches/$matchId/time-option', {
      'userId': userId,
      'optionId': optionId,
    });
  }

  Future<void> replaceMatchPlayer({
    required String matchId,
    required String hostId,
    required String removeUserId,
    required String inviteUserId,
    String? side,
  }) async {
    await _postJson('/matches/$matchId/replace-player', {
      'hostId': hostId,
      'removeUserId': removeUserId,
      'inviteUserId': inviteUserId,
      if (side != null && side.isNotEmpty) 'side': side,
    });
  }

  Future<void> deleteMatch({
    required String matchId,
    required String hostId,
  }) async {
    await _deleteJson('/matches/$matchId', {'hostId': hostId});
  }

  Future<int> invitePlayers({
    required String matchId,
    required String hostId,
    required List<String> targetUserIds,
  }) async {
    final response = await _postJson('/matches/$matchId/invite', {
      'hostId': hostId,
      'targetUserIds': targetUserIds,
    });
    return int.tryParse(response['invited']?.toString() ?? '') ?? 0;
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiError(path, response);
    }

    final raw = jsonDecode(response.body);
    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiError(path, response);
    }

    if (response.body.isEmpty) {
      return {};
    }

    final raw = jsonDecode(response.body);
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
  }

  Future<void> _delete(String path) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiError(path, response);
    }
  }

  Future<void> _deleteJson(String path, Map<String, dynamic> body) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$path'),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiError(path, response);
    }
  }

  ApiException _apiError(String path, http.Response response) {
    final details = _extractErrorDetails(response.body);
    final message = details.isEmpty
        ? 'API request failed ($path): ${response.statusCode}'
        : 'API request failed ($path): ${response.statusCode} - $details';
    return ApiException(
      message: message,
      statusCode: response.statusCode,
      path: path,
    );
  }

  String _extractErrorDetails(String body) {
    if (body.trim().isEmpty) {
      return '';
    }

    try {
      final raw = jsonDecode(body);
      if (raw is Map<String, dynamic>) {
        final message = raw['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        if (message is List) {
          final text = message
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .join(', ');
          if (text.isNotEmpty) {
            return text;
          }
        }
        final error = raw['error'];
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }
      }
    } catch (_) {
      // Fall back to plain text body.
    }

    return body.trim();
  }
}
