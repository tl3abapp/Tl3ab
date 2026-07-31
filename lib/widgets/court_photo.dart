import 'dart:convert';

import 'package:flutter/material.dart';

class CourtPhoto extends StatelessWidget {
  const CourtPhoto({
    this.photoData,
    this.borderRadius = 16,
    this.aspectRatio = 16 / 9,
    super.key,
  }) : _imageProvider = null;

  const CourtPhoto.fromProvider({
    required ImageProvider<Object> imageProvider,
    this.borderRadius = 16,
    this.aspectRatio = 16 / 9,
    super.key,
  }) : photoData = null,
       _imageProvider = imageProvider;

  final String? photoData;
  final double borderRadius;
  final double aspectRatio;
  final ImageProvider<Object>? _imageProvider;

  static ImageProvider<Object>? imageProvider(String? rawPhotoData) {
    final value = rawPhotoData?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final base64Value = value.contains(',')
          ? value.substring(value.indexOf(',') + 1)
          : value;
      return MemoryImage(base64Decode(base64Value));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _imageProvider ?? imageProvider(photoData);
    if (image == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image(image: image, fit: BoxFit.cover, width: double.infinity),
      ),
    );
  }
}
