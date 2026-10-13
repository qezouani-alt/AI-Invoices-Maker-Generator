# AI Invoices Maker & Generator

A Flutter app for invoices, quotes, expenses, tax reporting, and AI-assisted
document entry.

## AdMob ads

Debug builds use Google's official iOS sample App ID. Profile and release
builds use the production App ID. Debug and profile builds use Google's iOS
test ad units. Release builds use the production App Open ad unit;
interstitial and rewarded ads stay disabled until their production ad-unit IDs
are supplied. App Open ads can appear for returning users. An interstitial can
appear when entering Expenses, with a two-minute frequency cap. A rewarded ad is required before a
new invoice or quote is generated; editing an existing document does not show
one.

For a Codemagic iOS release, create `ios/Flutter/AdMob.local.xcconfig` during
the pre-build step (the file is gitignored):

```sh
printf 'ADMOB_APP_ID=%s\n' "$ADMOB_IOS_APP_ID" > ios/Flutter/AdMob.local.xcconfig
```

Then add the production App Open, Interstitial, and Rewarded ad units to the
Flutter build command:

```sh
flutter build ipa --release \
  --dart-define=ADMOB_IOS_APP_OPEN_AD_UNIT_ID="$ADMOB_IOS_APP_OPEN_AD_UNIT_ID" \
  --dart-define=ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID="$ADMOB_IOS_INTERSTITIAL_AD_UNIT_ID" \
  --dart-define=ADMOB_IOS_REWARDED_AD_UNIT_ID="$ADMOB_IOS_REWARDED_AD_UNIT_ID"
```
