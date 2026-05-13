import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uni_links/uni_links.dart';

class DeepLinkHandler extends StatefulWidget {
  final GoRouter router;
  final Widget child;

  const DeepLinkHandler({super.key, required this.router, required this.child});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  StreamSubscription<Uri?>? _sub;
  bool _handledInitial = false;

  @override
  void initState() {
    super.initState();
    _listenInitialUri();
    _listenUriStream();
  }

  Future<void> _listenInitialUri() async {
    if (_handledInitial) return;
    _handledInitial = true;
    try {
      final uri = await getInitialUri();
      if (uri == null) return;
      _handleUri(uri);
    } catch (_) {
      // Ignore malformed or unsupported initial links.
    }
  }

  void _listenUriStream() {
    _sub = uriLinkStream.listen(
      (uri) {
        if (uri == null) return;
        _handleUri(uri);
      },
      onError: (_) {
        // Ignore stream errors.
      },
    );
  }

  void _handleUri(Uri uri) {
    if (uri.host != 'facultypedia.app') return;
    if (uri.pathSegments.length < 2) return;
    final resource = uri.pathSegments.first;
    final id = uri.pathSegments[1];
    if (id.isEmpty) return;
    if (resource == 'course') {
      widget.router.go('/course/$id');
    } else if (resource == 'educator') {
      widget.router.go('/educator/$id');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
