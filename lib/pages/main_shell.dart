import 'package:flutter/material.dart';
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        indicatorColor: AppColors.green.withValues(alpha: .12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
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
