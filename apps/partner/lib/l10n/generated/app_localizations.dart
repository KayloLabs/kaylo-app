import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ml'),
    Locale('ta'),
  ];

  /// App bar title and application name
  ///
  /// In en, this message translates to:
  /// **'Kaylo Partner'**
  String get appTitle;

  /// Tooltip for refreshing jobs list
  ///
  /// In en, this message translates to:
  /// **'Refresh jobs'**
  String get refreshJobsTooltip;

  /// Bottom navigation tab label for jobs
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get tabJobs;

  /// Bottom navigation tab label for earnings
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get tabEarnings;

  /// Bottom navigation tab label for profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// Status text when worker is online
  ///
  /// In en, this message translates to:
  /// **'You\'re Online'**
  String get dutyOnline;

  /// Status text when worker is offline
  ///
  /// In en, this message translates to:
  /// **'You\'re Offline'**
  String get dutyOffline;

  /// Subtitle indicating worker is taking orders in district
  ///
  /// In en, this message translates to:
  /// **'Taking orders in {district}'**
  String dutyTakingOrders(String district);

  /// Subtitle indicating worker is not receiving requests
  ///
  /// In en, this message translates to:
  /// **'Not receiving requests'**
  String get dutyNotReceivingRequests;

  /// Summary label for earnings today
  ///
  /// In en, this message translates to:
  /// **'Today\'s Pay'**
  String get todaysPay;

  /// Summary label for count of jobs today
  ///
  /// In en, this message translates to:
  /// **'Jobs Today'**
  String get jobsToday;

  /// Summary label for worker rating
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Section header for the active job in progress
  ///
  /// In en, this message translates to:
  /// **'Active Job'**
  String get activeJob;

  /// Title for empty state when worker is offline
  ///
  /// In en, this message translates to:
  /// **'You\'re Offline'**
  String get offlineTitle;

  /// Description for empty state when worker is offline
  ///
  /// In en, this message translates to:
  /// **'Switch your duty status to Online above to receive nearby job requests from customers.'**
  String get offlineDescription;

  /// Section header for incoming job requests
  ///
  /// In en, this message translates to:
  /// **'New Requests ({count})'**
  String newRequests(int count);

  /// Empty state title when searching for job requests
  ///
  /// In en, this message translates to:
  /// **'Searching for requests...'**
  String get searchingForRequests;

  /// Empty state subtitle when searching for job requests
  ///
  /// In en, this message translates to:
  /// **'You will hear a ping when a nearby customer books.'**
  String get searchingForRequestsSubtitle;

  /// Payout label in job card
  ///
  /// In en, this message translates to:
  /// **'Payout'**
  String get payout;

  /// Button label to decline a requested job
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// Button label to accept a requested job
  ///
  /// In en, this message translates to:
  /// **'Accept Job'**
  String get acceptJob;

  /// Job stage label: requested
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get stageRequested;

  /// Job stage label: accepted
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get stageAccepted;

  /// Job stage label: on the way
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get stageOnTheWay;

  /// Job stage label: arrived
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get stageArrived;

  /// Job stage label: in progress
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get stageInProgress;

  /// Job stage label: completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get stageCompleted;

  /// Job stage label: cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get stageCancelled;

  /// Job action button: accept
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// Job action button: start travel
  ///
  /// In en, this message translates to:
  /// **'Start travel'**
  String get actionStartTravel;

  /// Job action button: I have arrived
  ///
  /// In en, this message translates to:
  /// **'I have arrived'**
  String get actionArrived;

  /// Job action button: start job
  ///
  /// In en, this message translates to:
  /// **'Start job'**
  String get actionStartJob;

  /// Job action button: complete job
  ///
  /// In en, this message translates to:
  /// **'Complete job'**
  String get actionCompleteJob;

  /// Title for the language selector sheet
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// Title for the language tile in the profile screen
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguageTile;

  /// Header for the App Settings section in the profile screen
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettingsHeader;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ml', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ml':
      return AppLocalizationsMl();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
