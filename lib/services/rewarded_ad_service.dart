import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_service.dart';

enum RewardedAdOutcome { earned, dismissed, unavailable, failed }

/// Loads and presents the rewarded ad used to generate a new invoice or quote.
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  static const _iosReleaseAdUnitId = String.fromEnvironment(
    'ca-app-pub-2535194044471316/9981774678',
  );

  static const _maximumAdAge = Duration(hours: 1);

  RewardedAd? _ad;
  DateTime? _loadedAt;
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

  Future<bool> loadAd() {
    if (!isEnabled) return Future<bool>.value(false);
    if (_hasFreshAd) return Future<bool>.value(true);
    return _loadOperation ??= _loadAdInternal().whenComplete(() {
      _loadOperation = null;
    });
  }

  bool get _hasFreshAd {
    final loadedAt = _loadedAt;
    return _ad != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _maximumAdAge;
  }

  Future<bool> _loadAdInternal() async {
    await _disposeLoadedAd();
    if (!await AdMobService.instance.ensureInitialized()) return false;

    final adUnitId = _adUnitId;
    if (adUnitId == null) return false;

    final completer = Completer<bool>();
    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loadedAt = DateTime.now();
            debugPrint('[AdMob] Rewarded ad loaded.');
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdMob] Rewarded ad failed to load: $error');
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[AdMob] Rewarded ad load error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }

  Future<RewardedAdOutcome> showAd() async {
    if (_isShowingAd) return RewardedAdOutcome.failed;
    if (!await loadAd()) return RewardedAdOutcome.unavailable;

    final ad = _ad;
    if (ad == null) return RewardedAdOutcome.unavailable;

    _ad = null;
    _loadedAt = null;
    _isShowingAd = true;
    AdMobService.instance.beginFullScreenAd();

    var rewardEarned = false;
    final outcome = Completer<RewardedAdOutcome>();

    void finish(RewardedAdOutcome value) {
      _isShowingAd = false;
      AdMobService.instance.endFullScreenAd();
      if (!outcome.isCompleted) outcome.complete(value);
      unawaited(loadAd());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) {
        debugPrint('[AdMob] Rewarded ad displayed.');
      },
      onAdImpression: (_) {
        debugPrint('[AdMob] Rewarded ad impression recorded.');
      },
      onAdDismissedFullScreenContent: (dismissedAd) {
        dismissedAd.dispose();
        debugPrint('[AdMob] Rewarded ad dismissed. Earned: $rewardEarned');
        finish(
          rewardEarned ? RewardedAdOutcome.earned : RewardedAdOutcome.dismissed,
        );
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        failedAd.dispose();
        debugPrint('[AdMob] Rewarded ad failed to show: $error');
        finish(RewardedAdOutcome.failed);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          rewardEarned = true;
          debugPrint('[AdMob] Reward earned: ${reward.amount} ${reward.type}.');
        },
      );
    } catch (error, stackTrace) {
      debugPrint('[AdMob] Rewarded ad presentation error: $error');
      debugPrintStack(stackTrace: stackTrace);
      await ad.dispose();
      finish(RewardedAdOutcome.failed);
    }

    return outcome.future;
  }

  Future<void> _disposeLoadedAd() async {
    final ad = _ad;
    _ad = null;
    _loadedAt = null;
    if (ad != null) await ad.dispose();
  }
}
