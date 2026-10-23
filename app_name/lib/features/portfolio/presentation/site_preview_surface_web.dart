import 'dart:ui_web' as ui;
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class SitePreviewSurface extends StatefulWidget {
  const SitePreviewSurface({super.key, required this.html});

  final String html;

  @override
  State<SitePreviewSurface> createState() => _SitePreviewSurfaceState();
}

class _SitePreviewSurfaceState extends State<SitePreviewSurface> {
  late final String _viewType;
  web.HTMLIFrameElement? _frame;

  @override
  void initState() {
    super.initState();
    _viewType = 'portfolio-site-preview-${identityHashCode(this)}';
    ui.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      final frame =
          web.document.createElement('iframe') as web.HTMLIFrameElement
            ..setAttribute('title', 'Portfolio website preview')
            ..sandbox.add('allow-scripts')
            ..srcdoc = widget.html.toJS;
      frame.style
        ..border = '0'
        ..height = '100%'
        ..width = '100%';
      _frame = frame;
      return frame;
    });
  }

  @override
  void didUpdateWidget(covariant SitePreviewSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _frame?.srcdoc = widget.html.toJS;
    }
  }

  @override
  void dispose() {
    _frame?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
