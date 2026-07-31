import 'package:flutter/material.dart';
import 'package:padel_connect/theme/app_theme.dart';
import 'package:padel_connect/widgets/user_avatar.dart';
import 'package:padel_connect/widgets/user_private_profile_sheet.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({required this.controller, super.key});

  final dynamic controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Friends'),
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
                _UsersList(
                  controller: controller,
                  users: controller.friendUsers as List,
                  emptyTitle: 'No friends yet',
                ),
                _UsersList(
                  controller: controller,
                  users: controller.followers as List,
                  emptyTitle: 'No followers',
                ),
                _UsersList(
                  controller: controller,
                  users: controller.following as List,
                  emptyTitle: 'No following',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.controller,
    required this.users,
    required this.emptyTitle,
  });

  final dynamic controller;
  final List users;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(emptyTitle, style: const TextStyle(color: AppColors.muted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final following =
            controller.isFollowingUser(user.id.toString()) as bool;
        final ratingLabel = controller
            .privateRatingLabelForUser(user.id.toString())
            .toString();
        return Card(
          child: ListTile(
            onTap: () => showUserPrivateProfileSheet(
              context: context,
              controller: controller,
              user: user,
            ),
            leading: UserAvatar(
              name: user.name.toString(),
              photoData: user.photoData?.toString(),
            ),
            title: Text(user.name.toString()),
            subtitle: Text('@${user.handle}\n$ratingLabel'),
            isThreeLine: true,
            trailing: TextButton(
              onPressed: () async {
                final message = await controller.toggleFollowUser(
                  user.id.toString(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(message.toString())));
                }
              },
              child: Text(following ? 'Following' : 'Follow'),
            ),
          ),
        );
      },
    );
  }
}
