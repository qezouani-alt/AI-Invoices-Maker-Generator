import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_service.dart';

/// Owns loading, freshness, and presentation for App Open ads.
///
/// Test ad units have been removed. The
/// release build is intentionally disabled until a production unit ID is
/// supplied with `--dart-define`, which prevents test ads or placeholder IDs
/// from reaching the App Store build.
class AppOpenAdService {
  AppOpenAdService._();

  static final AppOpenAdService instance = AppOpenAdService._();

  static const _iosReleaseAdUnitId = String.fromEnvironment(
    'ca-app-pub-2535194044471316/6974241458',
  );

  // Google recommends discarding an App Open ad after four hours. A short
  // display interval also prevents rapid app switching from becoming noisy.
  static const _maximumAdAge = Duration(hours: 4);
  static const _minimumDisplayInterval = Duration(minutes: 10);

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  DateTime? _lastShownAt;
  Future<void>? _initialization;
  bool _initialized = false;
  bool _isLoading = false;
  bool _isShowingAd = false;

  bool get isShowingAd => _isShowingAd;

  bool get isEnabled => _adUnitId != null;

  String? get _adUnitId {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    return _nonEmptyOrNull(_iosReleaseAdUnitId);
  }

  String? _nonEmptyOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> initialize() {
    if (!isEnabled) return Future<void>.value();
    return _initialization ??= _initializeInternal();
  }

  Future<void> _initializeInternal() async {
    try {
      if (!await AdMobService.instance.ensureInitialized()) return;
      _initialized = true;
      await loadAd();
    } catch (error, stackTrace) {
      debugPrint('[AdMob] Initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> loadAd() async {
    final adUnitId = _adUnitId;
    if (!_initialized || adUnitId == null || _isLoading || _ad != null) {
      return;
    }

    _isLoading = true;
    try {
      await AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoading = false;
            _ad = ad;
            _loadedAt = DateTime.now();
            debugPrint('[AdMob] App Open ad loaded.');
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            debugPrint('[AdMob] App Open ad failed to load: $error');
          },
        ),
      );
    } catch (error, stackTrace) {
      _isLoading = false;
      debugPrint('[AdMob] App Open ad load error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> showAdIfAvailable() async {
    if (!_initialized || _isShowingAd) return false;

    final now = DateTime.now();
    final lastShownAt = _lastShownAt;
    if (lastShownAt != null &&
        now.difference(lastShownAt) < _minimumDisplayInterval) {
      return false;
    }

    final loadedAt = _loadedAt;
    if (_ad == null ||
        loadedAt == null ||
        now.difference(loadedAt) >= _maximumAdAge) {
      await _disposeLoadedAd();
      unawaited(loadAd());
      return false;
    }

    final ad = _ad!;
    _ad = null;
    _loadedAt = null;
    _isShowingAd = true;
    AdMobService.instance.beginFullScreenAd();
    _lastShownAt = now;

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdShowedFullScreenContent: (_) {
        debugPrint('[AdMob] App Open ad displayed.');
      },
      onAdImpression: (_) {
        debugPrint('[AdMob] App Open ad impression recorded.');
      },
      onAdDismissedFullScreenContent: (dismissedAd) {
        debugPrint('[AdMob] App Open ad dismissed.');
        dismissedAd.dispose();
        _isShowingAd = false;
        AdMobService.instance.endFullScreenAd();
        unawaited(loadAd());
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        debugPrint('[AdMob] App Open ad failed to show: $error');
        failedAd.dispose();
        _isShowingAd = false;
        AdMobService.instance.endFullScreenAd();
        unawaited(loadAd());
      },
    );

    try {
      await ad.show();
      return true;
    } catch (error, stackTrace) {
      debugPrint('[AdMob] App Open ad presentation error: $error');
      debugPrintStack(stackTrace: stackTrace);
      await ad.dispose();
      _isShowingAd = false;
      AdMobService.instance.endFullScreenAd();
      unawaited(loadAd());
      return false;
    }
  }

  Future<void> _disposeLoadedAd() async {
    final ad = _ad;
    _ad = null;
    _loadedAt = null;
    if (ad != null) await ad.dispose();
  }
}
