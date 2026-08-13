import 'package:flutter/material.dart';
import 'package:padel_connect/app_language.dart';
import 'package:padel_connect/theme/app_theme.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    required this.controller,
    required this.threadId,
    super.key,
  });

  final dynamic controller;
  final String threadId;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessageChanged() => setState(() {});

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _send() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    widget.controller.sendMessage(widget.threadId, text);
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final thread = widget.controller.getThreadById(widget.threadId);
        final languageCode = widget.controller.generalSettings.languageCode
            .toString();
        String tr(String english, String arabic) =>
            appText(languageCode, english, arabic);
        if (thread == null) {
          return Scaffold(
            appBar: AppBar(title: Text(tr('Chat', 'المحادثة'))),
            body: Center(
              child: Text(
                tr('Thread not found', 'المحادثة غير موجودة'),
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          );
        }

        final messages = (thread.messages as List).toList();
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7FBF9), AppColors.bg],
              ),
            ),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thread.title.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                appIsArabic(languageCode)
                                    ? '${messages.length} رسائل'
                                    : '${messages.length} messages',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.stroke),
                          ),
                          child: const Icon(
                            Icons.more_horiz,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Text(
                            tr('No messages yet', 'لا توجد رسائل بعد'),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          itemCount: messages.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final mine = message.isMine == true;
                            return Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * .76,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    12,
                                    8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: mine
                                        ? const LinearGradient(
                                            colors: [
                                              AppColors.green,
                                              AppColors.dark,
                                            ],
                                          )
                                        : null,
                                    color: mine ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: mine
                                        ? null
                                        : Border.all(color: AppColors.stroke),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: .04,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!mine)
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              message.sender.toString(),
                                              style: const TextStyle(
                                                color: AppColors.green,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          message.text.toString(),
                                          style: TextStyle(
                                            color: mine
                                                ? Colors.white
                                                : AppColors.text,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _shortTime(message.sentAt as DateTime),
                                        style: TextStyle(
                                          color: mine
                                              ? Colors.white.withValues(
                                                  alpha: .82,
                                                )
                                              : AppColors.muted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.stroke),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.muted,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: tr(
                                'Type a message...',
                                'اكتب رسالة...',
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed: _messageController.text.trim().isEmpty
                              ? null
                              : _send,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            minimumSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.send_rounded),
                        ),
                      ],
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
