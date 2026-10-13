import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/app_lock_screen.dart';
import '../services/admob_service.dart';
import '../services/app_lock_service.dart';
import '../services/app_open_ad_service.dart';
import '../theme/app_theme.dart';

/// Keeps the application content behind an authentication screen while the
/// app is locked or after it returns from the background.
class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _ready = false;
  bool _locked = false;
  bool _enabled = false;
  bool _backgrounded = false;
  bool _obscured = false;
  Timer? _appOpenAdTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLockService.lockRequest.addListener(_handleLockRequest);
    _loadLockState();
  }

  @override
  void dispose() {
    _appOpenAdTimer?.cancel();
    AppLockService.lockRequest.removeListener(_handleLockRequest);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadLockState() async {
    final enabled = await AppLockService.isEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _locked = enabled;
      _obscured = false;
      _ready = true;
    });
    if (!enabled) _scheduleAppOpenAd();
  }

  void _handleLockRequest() {
    _loadLockState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A full-screen ad briefly changes the native lifecycle. It must not make
    // the app lock itself behind the ad.
    if (AdMobService.instance.isFullScreenAdShowing) {
      if (state == AppLifecycleState.resumed && mounted) {
        setState(() => _obscured = false);
      }
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Hide financial data from the app-switcher snapshot and transient
      // system overlays, even before the app reaches paused.
      if (mounted) setState(() => _obscured = true);
    } else if (state == AppLifecycleState.paused) {
      _backgrounded = true;
    } else if (state == AppLifecycleState.resumed && _backgrounded) {
      _backgrounded = false;
      _loadLockState();
    } else if (state == AppLifecycleState.resumed && mounted) {
      setState(() => _obscured = false);
    }
  }

  void _unlock() {
    if (!mounted) return;
    setState(() => _locked = false);
    _scheduleAppOpenAd();
  }

  void _scheduleAppOpenAd() {
    _appOpenAdTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _locked || _obscured) return;
      _appOpenAdTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted || _locked || _obscured) return;
        unawaited(AppOpenAdService.instance.showAdIfAvailable());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.emerald)),
      );
    }

    if (_enabled && _locked) {
      return AppLockScreen(onUnlocked: _unlock);
    }
    if (_obscured) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(
          child: Icon(Icons.lock_rounded, color: AppTheme.emerald, size: 48),
        ),
      );
    }
    return widget.child;
  }
}
