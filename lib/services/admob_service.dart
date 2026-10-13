import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Initializes Google Mobile Ads once per app session and owns the UMP consent
/// flow shared by every ad format.
class AdMobService {
  AdMobService._();

  static final AdMobService instance = AdMobService._();

  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(false);

  Future<bool>? _initialization;
  bool _isFullScreenAdShowing = false;

  bool get isFullScreenAdShowing => _isFullScreenAdShowing;

  void beginFullScreenAd() => _isFullScreenAdShowing = true;

  void endFullScreenAd() => _isFullScreenAdShowing = false;

  Future<bool> ensureInitialized() {
    return _initialization ??= _initializeInternal();
  }

  Future<bool> _initializeInternal() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }

    try {
      final canRequestAds = await _updateConsentInformation();
      if (!canRequestAds) {
        debugPrint('[AdMob] Consent does not currently allow ad requests.');
        return false;
      }

      await MobileAds.instance.initialize();
      return true;
    } catch (error, stackTrace) {
      debugPrint('[AdMob] Initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> _updateConsentInformation() async {
    final updateCompleter = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (formError != null) {
              debugPrint('[AdMob] Consent form error: ${formError.message}');
            }
          });
        } catch (error) {
          debugPrint('[AdMob] Could not present the consent form: $error');
        } finally {
          if (!updateCompleter.isCompleted) updateCompleter.complete();
        }
      },
      (formError) {
        debugPrint('[AdMob] Consent update error: ${formError.message}');
        if (!updateCompleter.isCompleted) updateCompleter.complete();
      },
    );

    try {
      await updateCompleter.future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      debugPrint('[AdMob] Consent update timed out.');
    }

    await _refreshPrivacyOptionsRequirement();
    return ConsentInformation.instance.canRequestAds();
  }

  Future<void> _refreshPrivacyOptionsRequirement() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (error) {
      debugPrint('[AdMob] Could not read privacy options status: $error');
      privacyOptionsRequired.value = false;
    }
  }

  Future<void> showPrivacyOptionsForm() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      await ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          debugPrint('[AdMob] Privacy options error: ${formError.message}');
        }
      });
      await _refreshPrivacyOptionsRequirement();
    } catch (error) {
      debugPrint('[AdMob] Could not show privacy options: $error');
    }
  }
}
