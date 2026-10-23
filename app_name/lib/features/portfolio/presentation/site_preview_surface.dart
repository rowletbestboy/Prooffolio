import 'package:flutter/widgets.dart';

import 'site_preview_surface_native.dart'
    if (dart.library.html) 'site_preview_surface_web.dart'
    as platform;

class SitePreviewSurface extends StatelessWidget {
  const SitePreviewSurface({super.key, required this.html});

  final String html;

  @override
  Widget build(BuildContext context) => platform.SitePreviewSurface(html: html);
}
