import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SitePreviewSurface extends StatefulWidget {
  const SitePreviewSurface({super.key, required this.html});

  final String html;

  @override
  State<SitePreviewSurface> createState() => _SitePreviewSurfaceState();
}

class _SitePreviewSurfaceState extends State<SitePreviewSurface> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => request.url == 'about:blank'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadHtmlString(widget.html);
  }

  @override
  void didUpdateWidget(covariant SitePreviewSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _controller.loadHtmlString(widget.html);
    }
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
