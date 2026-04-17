import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OfflineIndicator extends StatefulWidget {
  final Widget child;
  const OfflineIndicator({Key? key, required this.child}) : super(key: key);

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  StreamSubscription? _sub;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _checkConnectivity();
    _sub = Connectivity().onConnectivityChanged.listen((_) => _checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    bool offline;
    if (kIsWeb) {
      // On web, try fetching a tiny resource to check real connectivity
      try {
        final result = await Connectivity().checkConnectivity();
        offline = result.every((r) => r == ConnectivityResult.none);
      } catch (_) {
        offline = true;
      }
    } else {
      final result = await Connectivity().checkConnectivity();
      offline = result.every((r) => r == ConnectivityResult.none);
    }

    if (offline != _isOffline && mounted) {
      setState(() => _isOffline = offline);
      if (offline) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_isOffline)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SlideTransition(
                position: _slideAnim,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: Colors.red.shade700,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text('No internet connection',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
