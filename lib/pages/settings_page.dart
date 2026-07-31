import 'package:flutter/material.dart';
import 'package:padel_connect/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({required this.controller, super.key});

  final dynamic controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final privacy = widget.controller.privacySettings;
        final general = widget.controller.generalSettings;
        final isDeactivated =
            (widget.controller.isCurrentAccountDeactivated as bool?) ?? false;
        final deletionDate = widget.controller.currentAccountDeletionDate;

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7FBF9), AppColors.bg],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.text,
                          side: const BorderSide(color: AppColors.stroke),
                        ),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Settings',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        icon: Icons.watch_outlined,
                        text: 'Watch Ready',
                        color: const Color(0xFFEAF7EF),
                        textColor: AppColors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Privacy, notifications, account and app controls',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  _headerCard(
                    title: 'Quick Status',
                    subtitle: isDeactivated
                        ? 'Account paused${deletionDate == null ? '' : ' until ${deletionDate.day}/${deletionDate.month}/${deletionDate.year}'}'
                        : 'Account active and synced',
                    trailing: Icon(
                      isDeactivated
                          ? Icons.pause_circle_outline
                          : Icons.verified_user_outlined,
                      color: isDeactivated
                          ? const Color(0xFFB42318)
                          : AppColors.green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _SectionTitle('Privacy'),
                  _sectionCard(
                    children: [
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.lock_outline),
                        value: privacy.privateProfile,
                        onChanged: (value) {
                          widget.controller.updatePrivacySettings(
                            privacy.copyWith(privateProfile: value),
                          );
                        },
                        title: const Text('Private profile'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.mail_outline),
                        value: privacy.showEmailOnProfile,
                        onChanged: (value) {
                          widget.controller.updatePrivacySettings(
                            privacy.copyWith(showEmailOnProfile: value),
                          );
                        },
                        title: const Text('Show email'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.phone_outlined),
                        value: privacy.showPhoneOnProfile,
                        onChanged: (value) {
                          widget.controller.updatePrivacySettings(
                            privacy.copyWith(showPhoneOnProfile: value),
                          );
                        },
                        title: const Text('Show phone'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.location_on_outlined),
                        value: privacy.showAreaOnProfile,
                        onChanged: (value) {
                          widget.controller.updatePrivacySettings(
                            privacy.copyWith(showAreaOnProfile: value),
                          );
                        },
                        title: const Text('Show area'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.groups_2_outlined),
                        value: privacy.autoApproveCircleJoin,
                        onChanged: (value) {
                          widget.controller.updatePrivacySettings(
                            privacy.copyWith(autoApproveCircleJoin: value),
                          );
                        },
                        title: const Text('Circle instant join'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.chat_outlined),
                        value: privacy.allowDmFromEveryone,
                        onChanged: (value) {
                          widget.controller.updatePrivacySettings(
                            privacy.copyWith(allowDmFromEveryone: value),
                          );
                        },
                        title: const Text('DM from everyone'),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.public_outlined),
                        title: Text('Default game target'),
                        subtitle: Text('Create Game default option'),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _permissionChip(
                              label: 'Circle',
                              selected:
                                  widget.controller.defaultTargetScopeKey
                                      .toString() ==
                                  'circle',
                              onTap: () {
                                widget.controller.updatePrivacySettings(
                                  privacy.copyWith(
                                    defaultInvitePermission: 'circleOnly',
                                  ),
                                );
                              },
                            ),
                            _permissionChip(
                              label: 'Friends',
                              selected:
                                  widget.controller.defaultTargetScopeKey
                                      .toString() ==
                                  'friends',
                              onTap: () {
                                widget.controller.updatePrivacySettings(
                                  privacy.copyWith(
                                    defaultInvitePermission: 'friendsOnly',
                                  ),
                                );
                              },
                            ),
                            _permissionChip(
                              label: 'Public',
                              selected:
                                  widget.controller.defaultTargetScopeKey
                                      .toString() ==
                                  'public',
                              onTap: () {
                                widget.controller.updatePrivacySettings(
                                  privacy.copyWith(
                                    defaultInvitePermission: 'everyone',
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _SectionTitle('General'),
                  _sectionCard(
                    children: [
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.notifications_outlined),
                        value: general.pushInvites,
                        onChanged: (value) {
                          widget.controller.updateGeneralSettings(
                            general.copyWith(pushInvites: value),
                          );
                        },
                        title: const Text('Invite notifications'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.mark_chat_unread_outlined),
                        value: general.pushChat,
                        onChanged: (value) {
                          widget.controller.updateGeneralSettings(
                            general.copyWith(pushChat: value),
                          );
                        },
                        title: const Text('Chat notifications'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.sports_score_outlined),
                        value: general.pushMatchUpdates,
                        onChanged: (value) {
                          widget.controller.updateGeneralSettings(
                            general.copyWith(pushMatchUpdates: value),
                          );
                        },
                        title: const Text('Match updates'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.volume_up_outlined),
                        value: general.soundEnabled,
                        onChanged: (value) {
                          widget.controller.updateGeneralSettings(
                            general.copyWith(soundEnabled: value),
                          );
                        },
                        title: const Text('Sound'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.vibration_outlined),
                        value: general.vibrationEnabled,
                        onChanged: (value) {
                          widget.controller.updateGeneralSettings(
                            general.copyWith(vibrationEnabled: value),
                          );
                        },
                        title: const Text('Vibration'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        secondary: const Icon(Icons.view_agenda_outlined),
                        value: general.compactMode,
                        onChanged: (value) {
                          widget.controller.updateGeneralSettings(
                            general.copyWith(compactMode: value),
                          );
                        },
                        title: const Text('Compact mode'),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: DropdownButtonFormField<String>(
                          initialValue: general.languageCode,
                          decoration: const InputDecoration(
                            labelText: 'Language',
                            prefixIcon: Icon(Icons.language_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text('العربية'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            widget.controller.updateGeneralSettings(
                              general.copyWith(languageCode: value),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _SectionTitle('Account'),
                  _sectionCard(
                    children: [
                      ListTile(
                        leading: Icon(
                          isDeactivated
                              ? Icons.pause_circle
                              : Icons.verified_user,
                        ),
                        title: Text(
                          isDeactivated
                              ? 'Account is deactivated'
                              : 'Account active',
                        ),
                        subtitle: isDeactivated && deletionDate != null
                            ? Text(
                                'Scheduled delete: ${deletionDate.day}/${deletionDate.month}/${deletionDate.year}',
                              )
                            : const Text('Your account is available.'),
                      ),
                      const Divider(height: 1),
                      if (!isDeactivated)
                        ListTile(
                          leading: const Icon(Icons.pause_circle_outline),
                          title: const Text('Deactivate for 40 days'),
                          subtitle: const Text(
                            'You can reactivate before auto-delete',
                          ),
                          onTap: _deactivateAccount,
                        )
                      else
                        ListTile(
                          leading: const Icon(Icons.play_circle_outline),
                          title: const Text('Reactivate account'),
                          subtitle: const Text('Cancel scheduled deletion'),
                          onTap: _reactivateAccount,
                        ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_outlined),
                        title: const Text('Delete account permanently'),
                        subtitle: const Text('Immediate permanent delete'),
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _SectionTitle('App'),
                  _sectionCard(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.sync),
                        title: const Text('Sync now'),
                        subtitle: const Text('Refresh users, games, posts'),
                        onTap: () async {
                          await widget.controller.syncFromApi();
                          if (!context.mounted) {
                            return;
                          }
                          _showSnack('Synced.');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.restore_outlined),
                        title: const Text('Reset settings'),
                        subtitle: const Text('Privacy and general to default'),
                        onTap: () {
                          widget.controller.resetAppSettings();
                          _showSnack('Settings reset.');
                        },
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.watch_outlined),
                        title: Text('Smartwatch support'),
                        subtitle: Text(
                          'Phone notifications mirror to Apple Watch and Wear OS.',
                        ),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.language),
                        title: Text('Web ready'),
                        subtitle: Text(
                          'Run with --dart-define=PADEL_API_URL=<your_api>',
                        ),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('تلعب؟'),
                        subtitle: Text('Private padel social app'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deactivateAccount() async {
    final approved = await _confirm(
      title: 'Deactivate account?',
      body:
          'Your account will be paused and deleted after 40 days unless reactivated.',
      danger: true,
    );
    if (!approved) {
      return;
    }

    final message = await widget.controller.deactivateCurrentAccount(days: 40);
    if (!mounted) {
      return;
    }
    _showSnack(message.toString());
  }

  Future<void> _reactivateAccount() async {
    final message = await widget.controller.reactivateCurrentAccount();
    if (!mounted) {
      return;
    }
    _showSnack(message.toString());
  }

  Future<void> _deleteAccount() async {
    final approved = await _confirm(
      title: 'Delete account permanently?',
      body: 'This cannot be undone.',
      danger: true,
    );
    if (!approved) {
      return;
    }

    final message = await widget.controller.deleteCurrentAccount();
    if (!mounted) {
      return;
    }
    _showSnack(message.toString());
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: danger ? const Color(0xFFB42318) : null,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Widget _permissionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
      selectedColor: AppColors.green.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.green : AppColors.text,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(children: children),
      ),
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 15, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
