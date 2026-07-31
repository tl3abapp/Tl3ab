import 'package:flutter/material.dart';
import 'package:padel_connect/pages/chat_thread_page.dart';
import 'package:padel_connect/theme/app_theme.dart';
import 'package:padel_connect/widgets/user_avatar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({required this.controller, super.key});

  final dynamic controller;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _searchController = TextEditingController();

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
        final threads = (widget.controller.threads as List).toList();
        final query = _searchController.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? threads
            : threads.where((thread) {
                final title = thread.title.toString().toLowerCase();
                final preview = thread.preview.toString().toLowerCase();
                return title.contains(query) || preview.contains(query);
              }).toList();
        final matchingFriends = query.isEmpty
            ? const <dynamic>[]
            : (widget.controller.friendUsers as List).where((user) {
                final name = user.name.toString().toLowerCase();
                final handle = user.handle.toString().toLowerCase();
                return name.contains(query) || handle.contains(query);
              }).toList();

        final unreadTotal = threads.fold<int>(
          0,
          (sum, item) => sum + ((item.unreadCount as int?) ?? 0),
        );

        return SafeArea(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7FBF9), AppColors.bg],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                Row(
                  children: [
                    const Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7EF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        unreadTotal > 0 ? '$unreadTotal unread' : 'No unread',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Circle and game conversations',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search chats',
                  ),
                ),
                const SizedBox(height: 14),
                if (matchingFriends.isNotEmpty) ...[
                  const Text(
                    'Start a chat',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  ...matchingFriends.map((user) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: UserAvatar(
                          name: user.name.toString(),
                          photoData: user.photoData?.toString(),
                        ),
                        title: Text(user.name.toString()),
                        subtitle: Text('@${user.handle}'),
                        trailing: const Icon(Icons.chat_bubble_outline),
                        onTap: () async {
                          final threadId = await widget.controller
                              .openOrCreateDirectThread(
                                user.id.toString(),
                                user.name.toString(),
                              );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatThreadPage(
                                controller: widget.controller,
                                threadId: threadId.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
                if (filtered.isEmpty && matchingFriends.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: const Text(
                      'No chats yet',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  ...filtered.map(
                    (thread) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.stroke),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .04),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          widget.controller.markThreadRead(
                            thread.id.toString(),
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatThreadPage(
                                controller: widget.controller,
                                threadId: thread.id.toString(),
                              ),
                            ),
                          );
                        },
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [AppColors.dark, AppColors.green],
                            ),
                          ),
                          child: const Icon(
                            Icons.group_outlined,
                            color: AppColors.lime,
                          ),
                        ),
                        title: Text(
                          thread.title.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            thread.preview.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _shortTime(thread.lastActivity as DateTime),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            if ((thread.unreadCount as int) > 0)
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.green,
                                child: Text(
                                  '${thread.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _shortTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
