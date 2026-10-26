import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class AvatarImage extends StatelessWidget {
  final String photoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const AvatarImage({
    super.key,
    required this.photoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }

    // Base64 Data URI (e.g. data:image/jpeg;base64,...)
    if (photoUrl.startsWith('data:image')) {
      try {
        final commaIndex = photoUrl.indexOf(',');
        final base64Data = commaIndex != -1 ? photoUrl.substring(commaIndex + 1) : photoUrl;
        final Uint8List bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => fallback ?? const Icon(Icons.person, color: Colors.white),
        );
      } catch (e) {
        return fallback ?? const Icon(Icons.person, color: Colors.white);
      }
    }

    // Network HTTP/HTTPS image
    return Image.network(
      photoUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => fallback ?? const Icon(Icons.person, color: Colors.white),
    );
  }
}
