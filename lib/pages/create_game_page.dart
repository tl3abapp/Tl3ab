import 'package:flutter/material.dart';
import 'package:padel_connect/api/padel_api_client.dart';
import 'package:padel_connect/app_language.dart';
import 'package:padel_connect/theme/app_theme.dart';

class CreateGamePage extends StatefulWidget {
  const CreateGamePage({required this.controller, super.key});

  final dynamic controller;

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final Set<String> _selectedUserIds = <String>{};

  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 30);
  bool _saving = false;
  bool _scheduledGame = false;
  String _targetKey = 'circle';
  String _ratingFilter = 'all';
  String _hostSide = 'left';
  final List<DateTime> _extraTimeOptions = [];

  String get _languageCode =>
      widget.controller.generalSettings.languageCode.toString();

  String _tr(String english, String arabic) {
    return appText(_languageCode, english, arabic);
  }

  @override
  void initState() {
    super.initState();
    final key = widget.controller.defaultTargetScopeKey?.toString();
    if (key != null &&
        (key == 'circle' ||
            key == 'friends' ||
            key == 'public' ||
            key == 'selected')) {
      _targetKey = key;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) {
      setState(() => _time = selected);
    }
  }

  DateTime get _primaryStartTime =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _addTimeOption() async {
    if (_extraTimeOptions.length >= 2) {
      _showSnack(
        _tr('You can add up to 3 time choices.', 'تقدر تضيف إلى ٣ اختيارات.'),
      );
      return;
    }

    final initial = _extraTimeOptions.isEmpty
        ? _primaryStartTime.add(const Duration(hours: 1))
        : _extraTimeOptions.last.add(const Duration(hours: 1));
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: initial,
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null || !mounted) {
      return;
    }

    final option = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final duplicate = [
      _primaryStartTime,
      ..._extraTimeOptions,
    ].any((time) => time.isAtSameMomentAs(option));
    if (duplicate) {
      _showSnack(_tr('Time already added.', 'هذا الوقت مضاف من قبل.'));
      return;
    }

    setState(() => _extraTimeOptions.add(option));
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    final fallbackArea = (widget.controller.selectedArea ?? '').toString();
    final area = _areaController.text.trim().isEmpty
        ? fallbackArea
        : _areaController.text.trim();

    if (title.isEmpty || area.isEmpty) {
      _showSnack(_tr('Add title and area.', 'أضف العنوان والمنطقة.'));
      return;
    }

    if (_targetKey == 'selected' && _selectedUserIds.isEmpty) {
      _showSnack(_tr('Pick at least one user.', 'اختر لاعب واحد على الأقل.'));
      return;
    }

    final startsAt = _primaryStartTime;

    if (startsAt.isBefore(DateTime.now())) {
      _showSnack(_tr('Choose a future time.', 'اختر وقت قادم.'));
      return;
    }

    if (_scheduledGame && _extraTimeOptions.isEmpty) {
      _showSnack(
        _tr(
          'Add at least one more time choice.',
          'أضف اختيار وقت ثاني على الأقل.',
        ),
      );
      return;
    }

    setState(() => _saving = true);
    dynamic createdResult;
    try {
      createdResult = await widget.controller.createTargetedGameFromForm(
        title: title,
        area: area,
        startTime: startsAt,
        isScheduledGame: _scheduledGame,
        timeOptions: _scheduledGame
            ? _extraTimeOptions.toList(growable: false)
            : const [],
        targetKey: _targetKey,
        selectedUserIds: _selectedUserIds.toList(growable: false),
        hostSide: _hostSide,
      );
    } on ApiException catch (error) {
      debugPrint('Create game API failed: $error');
      createdResult = await _createOfflineFallback();
    } catch (error) {
      debugPrint('Create game failed: $error');
      createdResult = await _createOfflineFallback();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }

    if (!mounted || createdResult == null) {
      return;
    }

    String message;
    try {
      final inviteLink = createdResult.match.inviteLink?.toString() ?? '';
      message = inviteLink.isEmpty
          ? createdResult.message.toString()
          : _tr('Game + link created.', 'تم إنشاء المباراة والرابط.');
    } catch (_) {
      message = _tr('Game created.', 'تم إنشاء المباراة.');
    }

    _showSnack(message);
    if (mounted) {
      Navigator.of(context).pop(createdResult);
    }
  }

  Future<dynamic> _createOfflineFallback() async {
    try {
      return await widget.controller.createOfflineGameFromForm(
        title: _titleController.text.trim(),
        area: _areaController.text.trim().isEmpty
            ? (widget.controller.selectedArea ?? '').toString()
            : _areaController.text.trim(),
        startTime: _primaryStartTime,
        isScheduledGame: _scheduledGame,
        timeOptions: _scheduledGame
            ? _extraTimeOptions.toList(growable: false)
            : const [],
        targetKey: _targetKey,
        selectedUserIds: _selectedUserIds.toList(growable: false),
        hostSide: _hostSide,
      );
    } catch (error) {
      debugPrint('Offline game fallback failed: $error');
      if (mounted) {
        _showSnack(
          _tr(
            'Could not create game. Please check the details.',
            'تعذر إنشاء المباراة. تأكد من البيانات.',
          ),
        );
      }
      return null;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${_date.day}/${_date.month}/${_date.year}';
    final timeLabel = _time.format(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final users =
            (widget.controller.usersForTargetScope(_targetKey) as List)
                .toList();
        final filteredUsers = users.where(_matchesRatingFilter).toList();
        final showPlayerPicker = _targetKey != 'public';
        final selectedCount = _selectedUserIds.length;
        final targetHelp = switch (_targetKey) {
          'circle' => _tr('Circle joins directly', 'السيركل ينضمون مباشرة'),
          'friends' => _tr('Friends join directly', 'الأصدقاء ينضمون مباشرة'),
          'public' => _tr('Public sends request', 'العامة يرسلون طلب انضمام'),
          _ => _tr(
            'Selected users join directly',
            'اللاعبون المختارون ينضمون مباشرة',
          ),
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(_tr('Create Game', 'إنشاء مباراة')),
            leading: const BackButton(),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _tr('Title', 'العنوان'),
                  prefixIcon: const Icon(Icons.sports_tennis),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _areaController,
                decoration: InputDecoration(
                  labelText: _tr('Area', 'المنطقة'),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  hintText: (widget.controller.selectedArea ?? 'Kuwait City')
                      .toString(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(dateLabel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(timeLabel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _scheduleOptionsSection(),
              const SizedBox(height: 14),
              Text(
                _tr('Your side', 'جهتك'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                selected: {_hostSide},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() => _hostSide = selection.first);
                },
                segments: [
                  ButtonSegment<String>(
                    value: 'left',
                    icon: const Icon(Icons.keyboard_double_arrow_left),
                    label: Text(_tr('Left', 'يسار')),
                  ),
                  ButtonSegment<String>(
                    value: 'right',
                    icon: const Icon(Icons.keyboard_double_arrow_right),
                    label: Text(_tr('Right', 'يمين')),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _tr('Target', 'المستهدفون'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _targetChip(
                    'circle',
                    Icons.people_alt_outlined,
                    _tr('Circle', 'السيركل'),
                  ),
                  _targetChip(
                    'friends',
                    Icons.group_outlined,
                    _tr('Friends', 'الأصدقاء'),
                  ),
                  _targetChip('public', Icons.public, _tr('Public', 'عام')),
                  _targetChip(
                    'selected',
                    Icons.how_to_reg_outlined,
                    _tr('Pick', 'اختيار'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                targetHelp,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (showPlayerPicker) ...[
                const SizedBox(height: 12),
                Text(
                  _playerPickerHelp(selectedCount),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                _ratingFilterBar(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: filteredUsers.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  _selectedUserIds.addAll(
                                    filteredUsers.map(
                                      (user) => user.id.toString(),
                                    ),
                                  );
                                });
                              },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: Text(_tr('Select shown', 'اختيار الظاهرين')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectedUserIds.isEmpty
                            ? null
                            : () {
                                setState(_selectedUserIds.clear);
                              },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: Text(_tr('Clear', 'مسح')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (filteredUsers.isEmpty)
                  Text(
                    _tr('No users found.', 'لا يوجد لاعبون.'),
                    style: const TextStyle(color: AppColors.muted),
                  )
                else
                  ...filteredUsers.map((user) {
                    final userId = user.id.toString();
                    final selected = _selectedUserIds.contains(userId);
                    return CheckboxListTile(
                      value: selected,
                      contentPadding: EdgeInsets.zero,
                      title: Text(user.name.toString()),
                      subtitle: Text(
                        '@${user.handle}\n${widget.controller.privateRatingLabelForUser(userId)}',
                      ),
                      isThreeLine: true,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedUserIds.add(userId);
                          } else {
                            _selectedUserIds.remove(userId);
                          }
                        });
                      },
                    );
                  }),
              ],
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _saving ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_outlined),
                label: Text(
                  _saving
                      ? _tr('Creating...', 'جاري الإنشاء...')
                      : _tr('Create', 'إنشاء'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scheduleOptionsSection() {
    final primaryLabel = _formatDateTime(_primaryStartTime);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('Game type', 'نوع المباراة'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            selected: {_scheduledGame},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              final value = selection.first;
              setState(() {
                _scheduledGame = value;
                if (!value) {
                  _extraTimeOptions.clear();
                }
              });
            },
            segments: [
              ButtonSegment<bool>(
                value: false,
                icon: const Icon(Icons.event_available_outlined),
                label: Text(_tr('Normal', 'عادية')),
              ),
              ButtonSegment<bool>(
                value: true,
                icon: const Icon(Icons.event_repeat_outlined),
                label: Text(_tr('Scheduled', 'مجدولة')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _scheduledGame
                ? _tr(
                    'Invitees can choose from the time options.',
                    'المدعوون يختارون من أوقات اللعب المقترحة.',
                  )
                : _tr('One confirmed play time.', 'وقت لعب واحد ومؤكد.'),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _tr('Play scheduling', 'جدولة اللعب'),
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _timeOptionRow(
            label: _tr('Main time', 'الوقت الأساسي'),
            value: primaryLabel,
            onDelete: null,
          ),
          if (_scheduledGame) ...[
            ..._extraTimeOptions.asMap().entries.map(
              (entry) => _timeOptionRow(
                label: _tr(
                  'Option ${entry.key + 2}',
                  'الاختيار ${entry.key + 2}',
                ),
                value: _formatDateTime(entry.value),
                onDelete: () {
                  setState(() => _extraTimeOptions.removeAt(entry.key));
                },
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _extraTimeOptions.length >= 2 ? null : _addTimeOption,
              icon: const Icon(Icons.add_alarm_outlined),
              label: Text(_tr('Add time choice', 'إضافة اختيار وقت')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeOptionRow({
    required String label,
    required String value,
    required VoidCallback? onDelete,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule_outlined, color: AppColors.green),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(value),
      trailing: onDelete == null
          ? null
          : IconButton(
              tooltip: _tr('Remove', 'إزالة'),
              onPressed: onDelete,
              icon: const Icon(Icons.close),
            ),
    );
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year}, $hour:$minute';
  }

  Widget _targetChip(String key, IconData icon, String label) {
    final selected = _targetKey == key;
    return ChoiceChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      onSelected: (_) {
        if (_targetKey == key) {
          return;
        }
        setState(() {
          _targetKey = key;
          _selectedUserIds.clear();
          _ratingFilter = 'all';
        });
      },
    );
  }

  String _playerPickerHelp(int selectedCount) {
    if (_targetKey == 'selected') {
      return selectedCount == 0
          ? _tr(
              'Pick the players who can join directly.',
              'اختر اللاعبين اللي ينضمون مباشرة.',
            )
          : _tr(
              '$selectedCount selected. They can join directly.',
              'تم اختيار $selectedCount. يقدرون ينضمون مباشرة.',
            );
    }

    final group = _targetKey == 'friends'
        ? _tr('friends', 'الأصدقاء')
        : _tr('circle players', 'لاعبو السيركل');
    return selectedCount == 0
        ? _tr(
            'Filter or select players. If none are selected, all $group will receive it.',
            'فلتر أو اختر لاعبين. إذا ما اخترت أحد، راح توصل لكل $group.',
          )
        : _tr(
            '$selectedCount selected. Only these $group will receive it.',
            'تم اختيار $selectedCount. فقط هؤلاء من $group راح توصلهم.',
          );
  }

  bool _matchesRatingFilter(dynamic user) {
    final rating =
        widget.controller.privateRatingForUser(user.id.toString()) as int?;
    return switch (_ratingFilter) {
      'beginner' => rating != null && rating <= 3,
      'intermediate' => rating != null && rating >= 4 && rating <= 6,
      'pro' => rating != null && rating >= 7,
      'unrated' => rating == null,
      _ => true,
    };
  }

  Widget _ratingFilterBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ratingFilterChip('all', _tr('All', 'الكل')),
        _ratingFilterChip('beginner', _tr('Beginner', 'مبتدئ')),
        _ratingFilterChip('intermediate', _tr('Intermediate', 'متوسط')),
        _ratingFilterChip('pro', _tr('Pro', 'محترف')),
        _ratingFilterChip('unrated', _tr('Unrated', 'بدون تقييم')),
      ],
    );
  }

  Widget _ratingFilterChip(String key, String label) {
    return ChoiceChip(
      selected: _ratingFilter == key,
      label: Text(label),
      onSelected: (_) => setState(() => _ratingFilter = key),
    );
  }
}
