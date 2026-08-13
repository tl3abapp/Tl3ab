import 'package:flutter/material.dart';
import 'package:padel_connect/app_language.dart';
import 'package:padel_connect/pages/chat_page.dart';
import 'package:padel_connect/pages/circle_page.dart';
import 'package:padel_connect/pages/community_page.dart';
import 'package:padel_connect/pages/friends_page.dart';
import 'package:padel_connect/pages/home_page.dart';
import 'package:padel_connect/pages/my_games_page.dart';
import 'package:padel_connect/pages/notifications_page.dart';
import 'package:padel_connect/pages/profile_page.dart';
import 'package:padel_connect/pages/search_page.dart';
import 'package:padel_connect/pages/settings_page.dart';
import 'package:padel_connect/theme/app_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.controller, super.key});

  final dynamic controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        controller: widget.controller,
        onOpenSearch: _openSearch,
        onOpenNotifications: _openNotifications,
      ),
      CommunityPage(controller: widget.controller),
      ChatPage(controller: widget.controller),
      ProfilePage(
        controller: widget.controller,
        onOpenMyGames: _openMyGames,
        onOpenFriends: _openFriends,
        onOpenCircle: _openCircle,
        onOpenSettings: _openSettings,
        onSignOut: _signOut,
      ),
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => pages[index],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final currentLanguage = widget.controller.generalSettings.languageCode
              .toString();
          return NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            indicatorColor: AppColors.green.withValues(alpha: .12),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: appText(currentLanguage, 'Home', 'الرئيسية'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.groups_outlined),
                selectedIcon: const Icon(Icons.groups),
                label: appText(currentLanguage, 'Community', 'المجتمع'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline),
                selectedIcon: const Icon(Icons.chat_bubble),
                label: appText(currentLanguage, 'Chat', 'المحادثة'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: appText(currentLanguage, 'Profile', 'الملف'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchPage(controller: widget.controller),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(controller: widget.controller),
      ),
    );
  }

  void _openFriends() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendsPage(controller: widget.controller),
      ),
    );
  }

  void _openMyGames() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyGamesPage(controller: widget.controller),
      ),
    );
  }

  void _openCircle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CirclePage(controller: widget.controller),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(controller: widget.controller),
      ),
    );
  }

  void _signOut() {
    widget.controller.signOut();
  }
}
