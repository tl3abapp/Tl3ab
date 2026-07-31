import 'dart:convert';

import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.name,
    this.photoData,
    this.radius = 22,
    this.fallbackIcon,
  });

  final String? name;
  final String? photoData;
  final double radius;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final image = _profileImage(photoData);
    return CircleAvatar(
      radius: radius,
      backgroundImage: image,
      child: image == null ? _fallback() : null,
    );
  }

  Widget _fallback() {
    final icon = fallbackIcon;
    if (icon != null) {
      return Icon(icon, size: radius);
    }
    return Text(
      _initialFor(name),
      style: TextStyle(fontWeight: FontWeight.w800, fontSize: radius * 0.75),
    );
  }

  ImageProvider<Object>? _profileImage(String? rawPhotoData) {
    final value = rawPhotoData?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final base64Value = value.startsWith('data:')
        ? value.substring(value.indexOf(',') + 1)
        : value;

    try {
      return MemoryImage(base64Decode(base64Value));
    } catch (_) {
      return null;
    }
  }

  String _initialFor(String? rawName) {
    final value = rawName?.trim();
    if (value == null || value.isEmpty) {
      return 'P';
    }
    return value.substring(0, 1).toUpperCase();
  }
}
