import 'package:flutter/material.dart';
import 'package:padel_connect/theme/app_theme.dart';
import 'package:padel_connect/widgets/user_avatar.dart';
import 'package:padel_connect/widgets/user_private_profile_sheet.dart';

class CirclePage extends StatefulWidget {
  const CirclePage({required this.controller, super.key});

  final dynamic controller;

  @override
  State<CirclePage> createState() => _CirclePageState();
}

class _CirclePageState extends State<CirclePage> {
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final query = _searchController.text.trim().toLowerCase();
        final circleUsers = (widget.controller.circleUsers as List).toList();
        final candidates = (widget.controller.usersICanAddToCircle as List)
            .where((user) {
              final name = user.name.toString().toLowerCase();
              final handle = user.handle.toString().toLowerCase();
              return query.isEmpty ||
                  name.contains(query) ||
                  handle.contains(query);
            })
            .toList();
        final syncing = (widget.controller.syncing as bool?) ?? false;
        final syncError = widget.controller.syncError?.toString();

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Circle'),
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
                          'Could not refresh live users. Make sure the API is running.',
                      onRetry: () => widget.controller.syncFromApi(),
                    ),
                  ),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search users',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _countChip(
                      Icons.people_outline,
                      '${circleUsers.length} circle',
                    ),
                    const SizedBox(width: 8),
                    _countChip(
                      Icons.person_add_alt_1,
                      '${candidates.length} users',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Circle',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (circleUsers.isEmpty)
                  const Text(
                    'No users in your circle yet.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  ...circleUsers.map(
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
                        trailing: IconButton(
                          onPressed: () async {
                            final message = await widget.controller
                                .removeAccountFromMyList(user.id.toString());
                            if (!mounted) {
                              return;
                            }
                            _showMessage(message.toString());
                          },
                          icon: const Icon(
                            Icons.person_remove_alt_1,
                            color: Color(0xFF8A2B16),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Add People',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (candidates.isEmpty)
                  const Text(
                    'No users found.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  ...candidates.map((user) {
                    final added =
                        (widget.controller.isAddedByMe(user.id.toString())
                            as bool?) ??
                        false;
                    return Card(
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
                        trailing: IconButton(
                          onPressed: () async {
                            final message = added
                                ? await widget.controller
                                      .removeAccountFromMyList(
                                        user.id.toString(),
                                      )
                                : await widget.controller.addAccountToMyList(
                                    user.id.toString(),
                                  );
                            if (!mounted) {
                              return;
                            }
                            _showMessage(message.toString());
                          },
                          icon: Icon(
                            added
                                ? Icons.check_circle_outline
                                : Icons.person_add_alt_1,
                            color: added ? AppColors.green : null,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _countChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
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
