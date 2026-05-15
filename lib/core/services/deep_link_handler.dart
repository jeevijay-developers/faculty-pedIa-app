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
      _handleUri(uri, isInitial: true);
    } catch (_) {
      // Ignore malformed or unsupported initial links.
    }
  }

  void _listenUriStream() {
    _sub = uriLinkStream.listen(
      (uri) {
        if (uri == null) return;
        _handleUri(uri, isInitial: false);
      },
      onError: (_) {
        // Ignore stream errors.
      },
    );
  }

  void _handleUri(Uri uri, {required bool isInitial}) {
    if (uri.host != 'facultypedia.app') return;
    if (uri.pathSegments.length < 2) return;
    final resource = uri.pathSegments.first;
    final id = uri.pathSegments[1];
    if (id.isEmpty) return;
    if (resource == 'course') {
      _openWithBackStack('/course/$id', isInitial: isInitial);
    } else if (resource == 'educator') {
      _openWithBackStack('/educator/$id', isInitial: isInitial);
    }
  }

  void _openWithBackStack(String location, {required bool isInitial}) {
    final currentUri = widget.router.routeInformationProvider.value.uri;
    if (currentUri.path == location) return;

    if (!isInitial) {
      widget.router.push(location);
      return;
    }

    if (currentUri.path == '/splash') {
      // Ensure we land on a base route first so back navigation works.
      widget.router.go('/home');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.router.push(location);
      });
      return;
    }

    widget.router.push(location);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
