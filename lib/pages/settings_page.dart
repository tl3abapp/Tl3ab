import 'package:flutter/material.dart';
import 'package:padel_connect/app_language.dart';
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
        final languageCode = general.languageCode.toString();
        String tr(String english, String arabic) =>
            appText(languageCode, english, arabic);
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
                        tooltip: tr('Back', 'رجوع'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.text,
                          side: const BorderSide(color: AppColors.stroke),
                        ),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr('Settings', 'الإعدادات'),
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
                        text: tr('Watch Ready', 'جاهز للساعة'),
                        color: const Color(0xFFEAF7EF),
                        textColor: AppColors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'Privacy, notifications, account and app controls',
                      'الخصوصية، التنبيهات، الحساب، وإعدادات التطبيق',
                    ),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  _headerCard(
                    title: tr('Quick Status', 'الحالة السريعة'),
                    subtitle: isDeactivated
                        ? tr(
                            'Account paused${deletionDate == null ? '' : ' until ${deletionDate.day}/${deletionDate.month}/${deletionDate.year}'}',
                            'الحساب موقوف${deletionDate == null ? '' : ' إلى ${deletionDate.day}/${deletionDate.month}/${deletionDate.year}'}',
                          )
                        : tr('Account active and synced', 'الحساب نشط ومتزامن'),
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
                  _SectionTitle(tr('Privacy', 'الخصوصية')),
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
                        title: Text(tr('Private profile', 'ملف خاص')),
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
                        title: Text(tr('Show email', 'إظهار البريد')),
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
                        title: Text(tr('Show phone', 'إظهار الهاتف')),
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
                        title: Text(tr('Show area', 'إظهار المنطقة')),
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
                        title: Text(
                          tr('Circle instant join', 'انضمام السيركل تلقائي'),
                        ),
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
                        title: Text(tr('DM from everyone', 'رسائل من الجميع')),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.public_outlined),
                        title: Text(
                          tr('Default game target', 'هدف المباراة الافتراضي'),
                        ),
                        subtitle: Text(
                          tr(
                            'Create Game default option',
                            'الخيار الافتراضي لإنشاء مباراة',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _permissionChip(
                              label: tr('Circle', 'السيركل'),
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
                              label: tr('Friends', 'الأصدقاء'),
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
                              label: tr('Public', 'عام'),
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
                  _SectionTitle(tr('General', 'عام')),
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
                        title: Text(
                          tr('Invite notifications', 'تنبيهات الدعوات'),
                        ),
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
                        title: Text(
                          tr('Chat notifications', 'تنبيهات المحادثة'),
                        ),
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
                        title: Text(tr('Match updates', 'تحديثات المباراة')),
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
                        title: Text(tr('Sound', 'الصوت')),
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
                        title: Text(tr('Vibration', 'الاهتزاز')),
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
                        title: Text(tr('Compact mode', 'الوضع المختصر')),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: DropdownButtonFormField<String>(
                          initialValue: general.languageCode,
                          decoration: InputDecoration(
                            labelText: tr('Language', 'اللغة'),
                            prefixIcon: const Icon(Icons.language_outlined),
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
                  _SectionTitle(tr('Account', 'الحساب')),
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
                              ? tr('Account is deactivated', 'الحساب موقوف')
                              : tr('Account active', 'الحساب نشط'),
                        ),
                        subtitle: isDeactivated && deletionDate != null
                            ? Text(
                                tr(
                                  'Scheduled delete: ${deletionDate.day}/${deletionDate.month}/${deletionDate.year}',
                                  'الحذف المجدول: ${deletionDate.day}/${deletionDate.month}/${deletionDate.year}',
                                ),
                              )
                            : Text(
                                tr('Your account is available.', 'حسابك متاح.'),
                              ),
                      ),
                      const Divider(height: 1),
                      if (!isDeactivated)
                        ListTile(
                          leading: const Icon(Icons.pause_circle_outline),
                          title: Text(
                            tr('Deactivate for 40 days', 'إيقاف لمدة ٤٠ يوم'),
                          ),
                          subtitle: Text(
                            tr(
                              'You can reactivate before auto-delete',
                              'تقدر تفعله قبل الحذف التلقائي',
                            ),
                          ),
                          onTap: _deactivateAccount,
                        )
                      else
                        ListTile(
                          leading: const Icon(Icons.play_circle_outline),
                          title: Text(
                            tr('Reactivate account', 'إعادة تفعيل الحساب'),
                          ),
                          subtitle: Text(
                            tr(
                              'Cancel scheduled deletion',
                              'إلغاء الحذف المجدول',
                            ),
                          ),
                          onTap: _reactivateAccount,
                        ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_outlined),
                        title: Text(
                          tr(
                            'Delete account permanently',
                            'حذف الحساب نهائياً',
                          ),
                        ),
                        subtitle: Text(
                          tr('Immediate permanent delete', 'حذف نهائي مباشر'),
                        ),
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionTitle(tr('App', 'التطبيق')),
                  _sectionCard(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.sync),
                        title: Text(tr('Sync now', 'تحديث الآن')),
                        subtitle: Text(
                          tr(
                            'Refresh users, games, posts',
                            'تحديث اللاعبين والمباريات والمنشورات',
                          ),
                        ),
                        onTap: () async {
                          await widget.controller.syncFromApi();
                          if (!context.mounted) {
                            return;
                          }
                          _showSnack(tr('Synced.', 'تم التحديث.'));
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.restore_outlined),
                        title: Text(
                          tr('Reset settings', 'إعادة ضبط الإعدادات'),
                        ),
                        subtitle: Text(
                          tr(
                            'Privacy and general to default',
                            'إرجاع الخصوصية والعام للوضع الافتراضي',
                          ),
                        ),
                        onTap: () {
                          widget.controller.resetAppSettings();
                          _showSnack(
                            tr('Settings reset.', 'تمت إعادة ضبط الإعدادات.'),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.watch_outlined),
                        title: Text(
                          tr('Smartwatch support', 'دعم الساعة الذكية'),
                        ),
                        subtitle: Text(
                          tr(
                            'Phone notifications mirror to Apple Watch and Wear OS.',
                            'تنبيهات الهاتف تظهر على Apple Watch و Wear OS.',
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(tr('Web ready', 'جاهز للويب')),
                        subtitle: Text(
                          'Run with --dart-define=PADEL_API_URL=<your_api>',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('تلعب؟'),
                        subtitle: Text(
                          tr(
                            'Private padel social app',
                            'تطبيق اجتماعي خاص للبادل',
                          ),
                        ),
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
    final languageCode = widget.controller.generalSettings.languageCode
        .toString();
    final approved = await _confirm(
      title: appText(languageCode, 'Deactivate account?', 'إيقاف الحساب؟'),
      body: appText(
        languageCode,
        'Your account will be paused and deleted after 40 days unless reactivated.',
        'سيتم إيقاف حسابك وحذفه بعد ٤٠ يوم إذا لم تتم إعادة تفعيله.',
      ),
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
    final languageCode = widget.controller.generalSettings.languageCode
        .toString();
    final approved = await _confirm(
      title: appText(
        languageCode,
        'Delete account permanently?',
        'حذف الحساب نهائياً؟',
      ),
      body: appText(
        languageCode,
        'This cannot be undone.',
        'لا يمكن التراجع عن هذا الإجراء.',
      ),
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
    final languageCode = widget.controller.generalSettings.languageCode
        .toString();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(appText(languageCode, 'Cancel', 'إلغاء')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: danger ? const Color(0xFFB42318) : null,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(appText(languageCode, 'Confirm', 'تأكيد')),
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
