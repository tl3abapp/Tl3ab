import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:padel_connect/app_language.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({required this.controller, super.key});

  final dynamic controller;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _postController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = (widget.controller.feedPosts as List).toList();
    final languageCode = widget.controller.generalSettings.languageCode
        .toString();
    String tr(String english, String arabic) =>
        appText(languageCode, english, arabic);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tr('Community', 'المجتمع'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Share', 'مشاركة'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _postController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: tr(
                      'Post about games or meetups...',
                      'اكتب عن المباريات أو التجمعات...',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final message = await widget.controller.createPost(
                        _postController.text,
                      );
                      _postController.clear();
                      if (!mounted) {
                        return;
                      }
                      _showSnack(message.toString());
                      setState(() {});
                    },
                    icon: const Icon(Icons.send),
                    label: Text(tr('Post', 'نشر')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...posts.map(
            (post) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _postAvatar(post),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          post.author.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if ((widget.controller.canDeletePost(post.id.toString())
                              as bool?) ??
                          false)
                        PopupMenuButton<String>(
                          tooltip: tr('Post options', 'خيارات المنشور'),
                          onSelected: (value) async {
                            if (value != 'delete') {
                              return;
                            }
                            final result = await widget.controller.deletePost(
                              post.id.toString(),
                            );
                            if (!mounted) {
                              return;
                            }
                            _showSnack(result.toString());
                            setState(() {});
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(tr('Delete post', 'حذف المنشور')),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(post.content.toString()),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await widget.controller.likePost(post.id.toString());
                          if (!mounted) {
                            return;
                          }
                          setState(() {});
                        },
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: Text('${post.likes}'),
                      ),
                      TextButton.icon(
                        onPressed: () => _openCommentDialog(post.id.toString()),
                        icon: const Icon(Icons.mode_comment_outlined, size: 18),
                        label: Text('${post.comments}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCommentDialog(String postId) async {
    final languageCode = widget.controller.generalSettings.languageCode
        .toString();
    String tr(String english, String arabic) =>
        appText(languageCode, english, arabic);
    final commentController = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(tr('Add comment', 'إضافة تعليق')),
          content: TextField(
            controller: commentController,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: tr('Write a comment', 'اكتب تعليقاً'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(tr('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () async {
                final message = await widget.controller.commentOnPost(
                  postId,
                  commentController.text,
                );
                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop(message.toString());
              },
              child: Text(tr('Comment', 'تعليق')),
            ),
          ],
        );
      },
    );
    commentController.dispose();
    if (!mounted || message == null) {
      return;
    }
    _showSnack(message);
    setState(() {});
  }

  Widget _postAvatar(dynamic post) {
    ImageProvider<Object>? image;
    final photoData = post.authorPhotoData?.toString();
    if (photoData != null && photoData.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photoData));
      } catch (_) {
        image = null;
      }
    }

    final author = post.author.toString();
    return CircleAvatar(
      radius: 16,
      backgroundImage: image,
      child: image == null
          ? Text(author.isEmpty ? 'P' : author.substring(0, 1).toUpperCase())
          : null,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
