import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_service.dart';

/// Preloads and presents the interstitial used when entering Expenses.
///
/// Test ad units have been removed. Ads
/// remain disabled until a production unit ID is supplied with `--dart-define`.
class InterstitialAdService {
  InterstitialAdService._();

  static final InterstitialAdService instance = InterstitialAdService._();

  static const _iosReleaseAdUnitId = String.fromEnvironment(
    'ca-app-pub-2535194044471316/5661159784',
  );

  static const _maximumAdAge = Duration(hours: 1);
  static const _minimumDisplayInterval = Duration(minutes: 2);

  InterstitialAd? _ad;
  DateTime? _loadedAt;
  DateTime? _lastShownAt;
  Future<bool>? _loadOperation;
  bool _isShowingAd = false;

  bool get isEnabled => _adUnitId != null;

  String? get _adUnitId {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    return _nonEmptyOrNull(_iosReleaseAdUnitId);
  }

  String? _nonEmptyOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool get _hasFreshAd {
    final loadedAt = _loadedAt;
    return _ad != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _maximumAdAge;
  }

  Future<bool> loadAd() {
    if (!isEnabled) return Future<bool>.value(false);
    if (_hasFreshAd) return Future<bool>.value(true);
    return _loadOperation ??= _loadAdInternal().whenComplete(() {
      _loadOperation = null;
    });
  }

  Future<bool> _loadAdInternal() async {
    await _disposeLoadedAd();
    if (!await AdMobService.instance.ensureInitialized()) return false;

    final adUnitId = _adUnitId;
    if (adUnitId == null) return false;

    final completer = Completer<bool>();
    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loadedAt = DateTime.now();
            debugPrint('[AdMob] Expenses interstitial loaded.');
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdMob] Expenses interstitial failed to load: $error');
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[AdMob] Expenses interstitial load error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }

  /// Shows a preloaded ad and completes after dismissal. If no ad is ready,
  /// this returns immediately and starts loading one for the next visit.
  Future<bool> showAdIfAvailable() async {
    if (_isShowingAd || AdMobService.instance.isFullScreenAdShowing) {
      return false;
    }

    final lastShownAt = _lastShownAt;
    if (lastShownAt != null &&
        DateTime.now().difference(lastShownAt) < _minimumDisplayInterval) {
      return false;
    }

    if (!_hasFreshAd) {
      unawaited(loadAd());
      return false;
    }

    final ad = _ad;
    if (ad == null) return false;

    _ad = null;
    _loadedAt = null;
    _isShowingAd = true;
    AdMobService.instance.beginFullScreenAd();

    final dismissed = Completer<bool>();

    void finish(bool wasShown) {
      _isShowingAd = false;
      AdMobService.instance.endFullScreenAd();
      if (!dismissed.isCompleted) dismissed.complete(wasShown);
      unawaited(loadAd());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        _lastShownAt = DateTime.now();
        debugPrint('[AdMob] Expenses interstitial displayed.');
      },
      onAdImpression: (_) {
        debugPrint('[AdMob] Expenses interstitial impression recorded.');
      },
      onAdDismissedFullScreenContent: (dismissedAd) {
        dismissedAd.dispose();
        debugPrint('[AdMob] Expenses interstitial dismissed.');
        finish(true);
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        failedAd.dispose();
        debugPrint('[AdMob] Expenses interstitial failed to show: $error');
        finish(false);
      },
    );

    try {
      await ad.show();
    } catch (error, stackTrace) {
      debugPrint('[AdMob] Expenses interstitial presentation error: $error');
      debugPrintStack(stackTrace: stackTrace);
      await ad.dispose();
      finish(false);
    }

    return dismissed.future;
  }

  Future<void> _disposeLoadedAd() async {
    final ad = _ad;
    _ad = null;
    _loadedAt = null;
    if (ad != null) await ad.dispose();
  }
}
