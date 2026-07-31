import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:padel_connect/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.controller,
    required this.onOpenMyGames,
    required this.onOpenFriends,
    required this.onOpenCircle,
    required this.onOpenSettings,
    required this.onSignOut,
    super.key,
  });

  final dynamic controller;
  final VoidCallback onOpenMyGames;
  final VoidCallback onOpenFriends;
  final VoidCallback onOpenCircle;
  final VoidCallback onOpenSettings;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    final privacy = controller.privacySettings;
    final friends = (controller.friendUsers as List).length;
    final followers = (controller.followers as List).length;
    final following = (controller.following as List).length;
    final circle = (controller.circleContacts as List).length;
    final games = (controller.myHostedMatches as List).length;
    final isDeactivated =
        (controller.isCurrentAccountDeactivated as bool?) ?? false;
    final deletionDate = controller.currentAccountDeletionDate as DateTime?;

    final showEmail = (privacy?.showEmailOnProfile as bool?) ?? true;
    final showPhone = (privacy?.showPhoneOnProfile as bool?) ?? true;
    final showArea = (privacy?.showAreaOnProfile as bool?) ?? true;

    ImageProvider<Object>? profileImage;
    final photoData = user?.photoData?.toString();
    if (photoData != null && photoData.isNotEmpty) {
      try {
        profileImage = MemoryImage(base64Decode(photoData));
      } catch (_) {
        profileImage = null;
      }
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FBF9), AppColors.bg],
          ),
        ),
        child: Stack(
          children: [
            Container(
              height: 300,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.dark, AppColors.green],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(34),
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                children: [
                  Row(
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      _topIconButton(
                        icon: Icons.settings_outlined,
                        onTap: onOpenSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white.withValues(alpha: .14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 47,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: const Color(0xFFE6ECF0),
                                backgroundImage: profileImage,
                                child: profileImage == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 44,
                                        color: AppColors.text,
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: IconButton.filled(
                                onPressed: () =>
                                    _openPhotoActions(context, controller),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.lime,
                                  foregroundColor: AppColors.dark,
                                ),
                                icon: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 18,
                                ),
                                tooltip: 'Change photo',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (user?.name ?? 'Player').toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '@${(user?.handle ?? 'player').toString()}',
                          style: const TextStyle(
                            color: Color(0xFFD7F1E5),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _heroChip(
                              Icons.location_on_outlined,
                              (user?.area ?? controller.selectedArea)
                                  .toString(),
                            ),
                            _heroChip(
                              Icons.groups_2_outlined,
                              '$friends friends',
                            ),
                            _heroChip(Icons.sports_tennis, '$games games'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isDeactivated) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF8CACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pause_circle_outline,
                            color: Color(0xFFB42318),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              deletionDate == null
                                  ? 'Account is deactivated.'
                                  : 'Account paused. Auto-delete: '
                                        '${deletionDate.day}/${deletionDate.month}/${deletionDate.year}',
                              style: const TextStyle(
                                color: Color(0xFF7A271A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statCard('Games', '$games'),
                      const SizedBox(width: 8),
                      _statCard('Friends', '$friends'),
                      const SizedBox(width: 8),
                      _statCard('Circle', '$circle'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _miniStat(
                        Icons.people_alt_outlined,
                        '$followers Followers',
                      ),
                      const SizedBox(width: 8),
                      _miniStat(Icons.person_add_alt_1, '$following Following'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        children: [
                          _menuTile(
                            icon: Icons.sports_tennis,
                            title: 'My Games',
                            trailingText: '$games',
                            onTap: onOpenMyGames,
                          ),
                          const Divider(height: 1),
                          _menuTile(
                            icon: Icons.group_outlined,
                            title: 'Friends',
                            onTap: onOpenFriends,
                          ),
                          const Divider(height: 1),
                          _menuTile(
                            icon: Icons.people_outline,
                            title: 'My Circle',
                            onTap: onOpenCircle,
                          ),
                          const Divider(height: 1),
                          _menuTile(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            onTap: onOpenSettings,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        children: [
                          _infoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: showEmail
                                ? (user?.email ?? '-').toString()
                                : 'Hidden by privacy',
                          ),
                          const Divider(height: 1),
                          _infoTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: showPhone
                                ? (user?.phoneNumber ?? '-').toString()
                                : 'Hidden by privacy',
                          ),
                          const Divider(height: 1),
                          _infoTile(
                            icon: Icons.location_on_outlined,
                            label: 'Area',
                            value: showArea
                                ? (user?.area ?? controller.selectedArea)
                                      .toString()
                                : 'Hidden by privacy',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8A2B16),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _heroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD8F3E7)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD8F3E7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPhotoActions(
    BuildContext context,
    dynamic controller,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose photo'),
                onTap: () => Navigator.of(context).pop('pick'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () => Navigator.of(context).pop('remove'),
              ),
            ],
          ),
        );
      },
    );

    if (action == 'pick') {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 960,
      );
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      final message = await controller.updateCurrentUserPhoto(bytes);
      if (!context.mounted) {
        return;
      }
      _showSnack(context, message.toString());
      return;
    }

    if (action == 'remove') {
      final message = await controller.removeCurrentUserPhoto();
      if (!context.mounted) {
        return;
      }
      _showSnack(context, message.toString());
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: const Color(0xFFEAF7EF),
        child: Icon(icon, size: 16, color: AppColors.green),
      ),
      title: Text(title),
      trailing: trailingText != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailingText,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ],
            )
          : const Icon(Icons.chevron_right),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: const Color(0xFFF5F9F7),
        child: Icon(icon, size: 15, color: AppColors.muted),
      ),
      title: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(label),
    );
  }
}
