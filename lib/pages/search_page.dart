import 'package:flutter/material.dart';
import 'package:padel_connect/app_language.dart';
import 'package:padel_connect/theme/app_theme.dart';
import 'package:padel_connect/widgets/user_avatar.dart';
import 'package:padel_connect/widgets/user_private_profile_sheet.dart';

enum SearchTab { users, games, posts }

class SearchPage extends StatefulWidget {
  const SearchPage({required this.controller, super.key});

  final dynamic controller;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  SearchTab _tab = SearchTab.users;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.syncFromApi();
    });
  }

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
        final users = (widget.controller.allUsers as List)
            .where((user) => user.id.toString() != me?.id.toString())
            .where(
              (user) =>
                  _match(user.name.toString().toLowerCase(), query) ||
                  _match(user.handle.toString().toLowerCase(), query),
            )
            .toList();

        final games = (widget.controller.allMatches as List)
            .where(
              (match) =>
                  _match(match.title.toString().toLowerCase(), query) ||
                  _match(match.area.toString().toLowerCase(), query),
            )
            .toList();

        final posts = (widget.controller.allPosts as List)
            .where(
              (post) =>
                  _match(post.content.toString().toLowerCase(), query) ||
                  _match(post.author.toString().toLowerCase(), query),
            )
            .toList();

        final syncing = (widget.controller.syncing as bool?) ?? false;
        final syncError = widget.controller.syncError?.toString();
        final languageCode = widget.controller.generalSettings.languageCode
            .toString();
        String tr(String english, String arabic) =>
            appText(languageCode, english, arabic);

        return Scaffold(
          appBar: AppBar(
            title: Text(tr('Search', 'البحث')),
            actions: [
              IconButton(
                tooltip: tr('Refresh', 'تحديث'),
                onPressed: syncing
                    ? null
                    : () => widget.controller.syncFromApi(),
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
            onRefresh: () => widget.controller.syncFromApi(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (syncError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SyncBanner(
                      message: tr(
                        'Could not refresh live data. Make sure the API is running.',
                        'تعذر تحديث البيانات. تأكد أن الخدمة تعمل.',
                      ),
                      onRetry: () => widget.controller.syncFromApi(),
                      retryLabel: tr('Retry', 'إعادة المحاولة'),
                    ),
                  ),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: tr(
                      'Search users, games, posts',
                      'ابحث عن لاعبين، مباريات، منشورات',
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<SearchTab>(
                  selected: <SearchTab>{_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() => _tab = selection.first);
                  },
                  segments: [
                    ButtonSegment<SearchTab>(
                      value: SearchTab.users,
                      icon: const Icon(Icons.person_search_outlined),
                      label: Text(tr('Users', 'اللاعبون')),
                    ),
                    ButtonSegment<SearchTab>(
                      value: SearchTab.games,
                      icon: const Icon(Icons.sports_tennis_outlined),
                      label: Text(tr('Games', 'المباريات')),
                    ),
                    ButtonSegment<SearchTab>(
                      value: SearchTab.posts,
                      icon: const Icon(Icons.feed_outlined),
                      label: Text(tr('Posts', 'المنشورات')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_tab == SearchTab.users)
                  ..._buildUsers(users, languageCode)
                else if (_tab == SearchTab.games)
                  ..._buildGames(games, languageCode)
                else
                  ..._buildPosts(posts, languageCode),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildUsers(List users, String languageCode) {
    if (users.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            appText(languageCode, 'No users', 'لا يوجد لاعبون'),
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      ];
    }

    return users
        .map(
          (user) => Card(
            child: ListTile(
              onTap: () => showUserPrivateProfileSheet(
                context: context,
                controller: widget.controller,
                user: user,
              ),
              leading: UserAvatar(
                name: user.name.toString(),
                photoData: user.photoData?.toString(),
              ),
              title: Text(user.name.toString()),
              subtitle: Text(
                '@${user.handle}\n${widget.controller.privateRatingLabelForUser(user.id.toString())}',
              ),
              isThreeLine: true,
              trailing: TextButton(
                onPressed: () async {
                  final result = await widget.controller.toggleFollowUser(
                    user.id.toString(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(result.toString())),
                      );
                  }
                },
                child: Text(
                  (widget.controller.isFollowingUser(user.id.toString())
                          as bool)
                      ? appText(languageCode, 'Following', 'تتابعه')
                      : appText(languageCode, 'Follow', 'متابعة'),
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildGames(List games, String languageCode) {
    if (games.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            appText(languageCode, 'No games', 'لا توجد مباريات'),
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      ];
    }

    return games.map((match) {
      return Card(
        child: ListTile(
          leading: Icon(
            '${match.visibility}'.contains('privateGame')
                ? Icons.lock_outline
                : Icons.public,
          ),
          title: Text(match.title.toString()),
          subtitle: Text(
            [
              match.area.toString(),
              appIsArabic(languageCode)
                  ? '${match.joinedPlayers}/${match.maxPlayers} لاعبين'
                  : '${match.joinedPlayers}/${match.maxPlayers} players',
            ].join(' • '),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPosts(List posts, String languageCode) {
    if (posts.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            appText(languageCode, 'No posts', 'لا توجد منشورات'),
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      ];
    }

    return posts
        .map(
          (post) => Card(
            child: ListTile(
              leading: const Icon(Icons.feed_outlined),
              title: Text(post.author.toString()),
              subtitle: Text(
                post.content.toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
            ),
          ),
        )
        .toList();
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD6A3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFF9A6512)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A4B00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
