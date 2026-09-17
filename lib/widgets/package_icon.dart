import 'package:fl_clash/plugins/app.dart';
import 'package:flutter/material.dart';

class PackageIcon extends StatelessWidget {
  final String packageName;
  final double size;
  final App? client;

  const PackageIcon({
    super.key,
    required this.packageName,
    this.size = 48,
    this.client,
  });

  Widget _placeholder() {
    return SizedBox(width: size, height: size);
  }

  Widget _image(ImageProvider image) {
    return Image(
      image: image,
      gaplessPlayback: true,
      width: size,
      height: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appClient = client ?? app;
    if (appClient == null || packageName.isEmpty) {
      return _placeholder();
    }
    if (appClient.hasPackageIcon(packageName)) {
      final icon = appClient.getCachedPackageIcon(packageName);
      if (icon == null) {
        return _placeholder();
      }
      return _image(icon);
    }
    return FutureBuilder<ImageProvider?>(
      future: appClient.getPackageIcon(packageName),
      builder: (_, snapshot) {
        final icon = snapshot.data;
        if (icon == null) {
          return _placeholder();
        }
        return _image(icon);
      },
    );
  }
}
