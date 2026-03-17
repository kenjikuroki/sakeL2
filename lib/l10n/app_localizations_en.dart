// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sake Exam L2';

  @override
  String get homeTitle => 'Sake Exam L2: Study & Quiz';

  @override
  String get homeSubtitle => 'Master Advanced Sake Knowledge!';

  @override
  String get part1Title => 'Ingredients & Water';

  @override
  String get part2Title => 'Production Process';

  @override
  String get part3Title => 'Labels & Styles';

  @override
  String get part4Title => 'Serving & Pairing';

  @override
  String get reviewWeakness => 'Review Weakness';

  @override
  String get correct => 'Correct!';

  @override
  String get incorrect => 'Incorrect...';

  @override
  String get questionLabel => 'Question';

  @override
  String get resultTitle => 'Result';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data available';

  @override
  String get perfectMessage => 'PERFECT! 🎉';

  @override
  String get passMessage => 'Great job! You passed!';

  @override
  String get failMessage => 'Almost! Let\'s review.';

  @override
  String get imageQuestion => 'Image Question';

  @override
  String get reviewMistakes => 'Review Mistakes';

  @override
  String get retry => 'Retry';

  @override
  String get scoreLabel => 'Score';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get appVersion => 'Version';

  @override
  String get premiumUnlock => 'Unlock Premium';

  @override
  String get premiumDesc => 'Unlock all parts & remove ads';

  @override
  String get purchaseSuccess => 'Purchase successful!';

  @override
  String get restoreSuccess => 'Purchases restored!';

  @override
  String get restoreFail => 'Nothing to restore.';

  @override
  String get locked => 'Locked';

  @override
  String get buy => 'Buy';

  @override
  String get sisterAppTitle => 'Deepen your knowledge with our other apps';

  @override
  String get sisterAppSubtitle => 'Challenge another level!';

  @override
  String get sisterAppPopupTitle => 'Other Apps';

  @override
  String get sisterAppPopupBody =>
      'Opening the App Store to visit the app page.';

  @override
  String get cancel => 'Cancel';

  @override
  String get open => 'Open';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get sequential => 'Sequential';

  @override
  String get premiumUpgradeTitle => 'Premium Upgrade';

  @override
  String get premiumFeatureSequential =>
      '\'Sequential\' mode: Solve all questions in order from the first.';

  @override
  String get premiumFeatureAds =>
      'Remove all ads: Hide all banners and videos in the app.';

  @override
  String get premiumFeatureCategory =>
      'Category-based review: Efficiently review your weak points by chapter.';

  @override
  String get upgradeNow => 'Upgrade Now';

  @override
  String get whichPartToReview => 'Which part do you want to review?';

  @override
  String get allCategories => 'All Categories';

  @override
  String questionCount(Object count) {
    return '$count questions';
  }
}
