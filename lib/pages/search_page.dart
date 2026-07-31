import 'package:flutter/material.dart';
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Search'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
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
                      message:
                          'Could not refresh live data. Make sure the API is running.',
                      onRetry: () => widget.controller.syncFromApi(),
                    ),
                  ),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search users, games, posts',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<SearchTab>(
                  selected: <SearchTab>{_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() => _tab = selection.first);
                  },
                  segments: const [
                    ButtonSegment<SearchTab>(
                      value: SearchTab.users,
                      icon: Icon(Icons.person_search_outlined),
                      label: Text('Users'),
                    ),
                    ButtonSegment<SearchTab>(
                      value: SearchTab.games,
                      icon: Icon(Icons.sports_tennis_outlined),
                      label: Text('Games'),
                    ),
                    ButtonSegment<SearchTab>(
                      value: SearchTab.posts,
                      icon: Icon(Icons.feed_outlined),
                      label: Text('Posts'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_tab == SearchTab.users)
                  ..._buildUsers(users)
                else if (_tab == SearchTab.games)
                  ..._buildGames(games)
                else
                  ..._buildPosts(posts),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildUsers(List users) {
    if (users.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No users', style: TextStyle(color: AppColors.muted)),
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
                      ? 'Following'
                      : 'Follow',
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildGames(List games) {
    if (games.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No games', style: TextStyle(color: AppColors.muted)),
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
              '${match.joinedPlayers}/${match.maxPlayers} players',
            ].join(' • '),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPosts(List posts) {
    if (posts.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No posts', style: TextStyle(color: AppColors.muted)),
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
  const _SyncBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
