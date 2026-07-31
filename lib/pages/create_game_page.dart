import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 30);
  bool _saving = false;
  String _targetKey = 'circle';
  String _ratingFilter = 'all';
  String _hostSide = 'left';
  Uint8List? _courtPhotoBytes;

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

  Future<void> _pickCourtPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1280,
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() => _courtPhotoBytes = bytes);
  }

  Future<void> _create() async {
    final title = _titleController.text.trim();
    final fallbackArea = (widget.controller.selectedArea ?? '').toString();
    final area = _areaController.text.trim().isEmpty
        ? fallbackArea
        : _areaController.text.trim();

    if (title.isEmpty || area.isEmpty) {
      _showSnack('Add title and area.');
      return;
    }

    if (_targetKey == 'selected' && _selectedUserIds.isEmpty) {
      _showSnack('Pick at least one user.');
      return;
    }

    final startsAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    setState(() => _saving = true);
    try {
      final scope = widget.controller.parseTargetScopeKey(_targetKey);
      final result = await widget.controller.createTargetedGame(
        title: title,
        area: area,
        startTime: startsAt,
        scope: scope,
        selectedUserIds: _selectedUserIds.toList(growable: false),
        hostSide: _hostSide,
        courtPhotoData: _courtPhotoBytes == null
            ? null
            : base64Encode(_courtPhotoBytes!),
      );

      if (!mounted) {
        return;
      }

      final inviteLink = result.match.inviteLink?.toString() ?? '';
      _showSnack(
        inviteLink.isEmpty ? result.message.toString() : 'Game + link created.',
      );
      Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('Could not create game.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
          'circle' => 'Circle joins directly',
          'friends' => 'Friends join directly',
          'public' => 'Public sends request',
          _ => 'Selected users join directly',
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text('Create Game'),
            leading: const BackButton(),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.sports_tennis),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _areaController,
                decoration: InputDecoration(
                  labelText: 'Area',
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
              _courtPhotoPicker(),
              const SizedBox(height: 14),
              const Text(
                'Your side',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                selected: {_hostSide},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() => _hostSide = selection.first);
                },
                segments: const [
                  ButtonSegment<String>(
                    value: 'left',
                    icon: Icon(Icons.keyboard_double_arrow_left),
                    label: Text('Left'),
                  ),
                  ButtonSegment<String>(
                    value: 'right',
                    icon: Icon(Icons.keyboard_double_arrow_right),
                    label: Text('Right'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Target',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _targetChip('circle', Icons.people_alt_outlined, 'Circle'),
                  _targetChip('friends', Icons.group_outlined, 'Friends'),
                  _targetChip('public', Icons.public, 'Public'),
                  _targetChip('selected', Icons.how_to_reg_outlined, 'Pick'),
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
                        label: const Text('Select shown'),
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
                        label: const Text('Clear'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (filteredUsers.isEmpty)
                  const Text(
                    'No users found.',
                    style: TextStyle(color: AppColors.muted),
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
                label: Text(_saving ? 'Creating...' : 'Create'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _courtPhotoPicker() {
    final photoBytes = _courtPhotoBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Court photo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (photoBytes == null)
          OutlinedButton.icon(
            onPressed: _pickCourtPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Upload court photo'),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.memory(photoBytes, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _pickCourtPhoto,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Change'),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Remove photo',
                        onPressed: () =>
                            setState(() => _courtPhotoBytes = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
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
          ? 'Pick the players who can join directly.'
          : '$selectedCount selected. They can join directly.';
    }

    final group = _targetKey == 'friends' ? 'friends' : 'circle players';
    return selectedCount == 0
        ? 'Filter or select players. If none are selected, all $group will receive it.'
        : '$selectedCount selected. Only these $group will receive it.';
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
        _ratingFilterChip('all', 'All'),
        _ratingFilterChip('beginner', 'Beginner'),
        _ratingFilterChip('intermediate', 'Intermediate'),
        _ratingFilterChip('pro', 'Pro'),
        _ratingFilterChip('unrated', 'Unrated'),
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
