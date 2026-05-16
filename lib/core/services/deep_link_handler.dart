import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flinku_sdk/flinku_sdk.dart';
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
    _handleFlinkuMatch();
    _listenInitialUri();
    _listenUriStream();
  }

  Future<void> _handleFlinkuMatch() async {
    try {
      final link = await Flinku.match();
      final deepLink = link?.deepLink?.toString() ?? '';
      if (deepLink.isEmpty) return;
      final uri = Uri.tryParse(deepLink);
      if (uri == null) return;
      _handleUri(uri, isInitial: true);
      await Flinku.reset();
    } catch (_) {
      // Ignore Flinku match errors.
    }
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
    final target = _parseDeepLink(uri);
    if (target == null) return;
    final resource = target.key;
    final id = target.value;
    if (resource == 'course') {
      _openWithBackStack('/course/$id', isInitial: isInitial);
    } else if (resource == 'educator') {
      _openWithBackStack('/educator/$id', isInitial: isInitial);
    }
  }

  MapEntry<String, String>? _parseDeepLink(Uri uri) {
    if (uri.scheme == 'facultypedia') {
      final resource = uri.host;
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (resource.isEmpty || id.isEmpty) return null;
      return MapEntry(resource, id);
    }
    if (uri.host == 'facultypedia.app') {
      if (uri.pathSegments.length < 2) return null;
      final resource = uri.pathSegments.first;
      final id = uri.pathSegments[1];
      if (resource.isEmpty || id.isEmpty) return null;
      return MapEntry(resource, id);
    }
    return null;
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
