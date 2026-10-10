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

  /// App bar title of the profile tab
  ///
  /// In en, this message translates to:
  /// **'Partner profile'**
  String get profileTitle;

  /// Action that opens the edit sheet
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// Chip on a verified worker
  ///
  /// In en, this message translates to:
  /// **'Verified partner'**
  String get verifiedPartner;

  /// Chip while the Trust Team reviews the worker
  ///
  /// In en, this message translates to:
  /// **'Verification in progress'**
  String get verificationUnderReview;

  /// Chip when verification was refused
  ///
  /// In en, this message translates to:
  /// **'Verification rejected'**
  String get verificationRejected;

  /// Chip before any verification
  ///
  /// In en, this message translates to:
  /// **'Not verified yet'**
  String get verificationNotStarted;

  /// Section header for rating and job counts
  ///
  /// In en, this message translates to:
  /// **'Performance & ratings'**
  String get performanceHeader;

  /// Metric label: completed jobs
  ///
  /// In en, this message translates to:
  /// **'Total jobs'**
  String get totalJobs;

  /// How many reviews the rating is based on
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// When the worker joined, month and year
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String memberSince(String date);

  /// Section header for the service chips
  ///
  /// In en, this message translates to:
  /// **'Services you offer'**
  String get offeredServicesHeader;

  /// Shown when the worker offers no service
  ///
  /// In en, this message translates to:
  /// **'No services listed yet'**
  String get noServicesYet;

  /// Section header for UPI and bank details
  ///
  /// In en, this message translates to:
  /// **'Payout account'**
  String get payoutHeader;

  /// The UPI handle line
  ///
  /// In en, this message translates to:
  /// **'UPI ID: {upi}'**
  String upiLabel(String upi);

  /// Shown when neither UPI nor bank account is set
  ///
  /// In en, this message translates to:
  /// **'No payout account yet'**
  String get noPayoutYet;

  /// Note under the payout card
  ///
  /// In en, this message translates to:
  /// **'Bank account changes go through support'**
  String get bankChangeNote;

  /// Section header for document states
  ///
  /// In en, this message translates to:
  /// **'KYC & verification'**
  String get verificationHeader;

  /// Document row title
  ///
  /// In en, this message translates to:
  /// **'Aadhaar card'**
  String get documentAadhaar;

  /// Document row title
  ///
  /// In en, this message translates to:
  /// **'Police clearance certificate'**
  String get documentPoliceCertificate;

  /// Document state chip
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// Document state chip
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Document state chip
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// Document state chip when nothing was uploaded
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get statusNotSubmitted;

  /// Section header for district, radius and hours
  ///
  /// In en, this message translates to:
  /// **'Service area & schedule'**
  String get areaScheduleHeader;

  /// How far the worker travels
  ///
  /// In en, this message translates to:
  /// **'{km} km radius'**
  String travelRadius(String km);

  /// Shown when no district is saved
  ///
  /// In en, this message translates to:
  /// **'Service area not set'**
  String get noDistrictYet;

  /// Shown when no weekly hours are saved
  ///
  /// In en, this message translates to:
  /// **'Working hours not set'**
  String get hoursNotSet;

  /// Schedule summary when the days differ
  ///
  /// In en, this message translates to:
  /// **'Different hours on different days'**
  String get customHours;

  /// Button to the availability screen
  ///
  /// In en, this message translates to:
  /// **'Manage availability'**
  String get manageAvailability;

  /// Log out button and dialog confirm
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// Log out dialog title
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutTitle;

  /// Log out dialog body
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again with your phone number to receive jobs.'**
  String get logOutBody;

  /// Dialog dismiss button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Profile tab when the person has no worker row
  ///
  /// In en, this message translates to:
  /// **'Finish your registration'**
  String get notRegisteredTitle;

  /// Explanation under notRegisteredTitle
  ///
  /// In en, this message translates to:
  /// **'Your worker profile is not set up yet. Complete registration to start receiving jobs.'**
  String get notRegisteredBody;

  /// Error state title
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile'**
  String get profileLoadFailed;

  /// Error state button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Edit sheet title
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// Edit sheet field
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// Edit sheet field
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// Edit sheet field
  ///
  /// In en, this message translates to:
  /// **'Travel radius (km)'**
  String get travelRadiusLabel;

  /// Edit sheet field
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get upiIdLabel;

  /// Edit sheet: label above the service chips
  ///
  /// In en, this message translates to:
  /// **'Services you offer'**
  String get servicesLabel;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Snackbar after a successful save
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileSaved;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameRequired;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Choose at least one service'**
  String get chooseOneService;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Enter a valid UPI ID, like name@bank'**
  String get invalidUpi;

  /// Validation message
  ///
  /// In en, this message translates to:
  /// **'Enter a radius between 1 and 100 km'**
  String get radiusRange;

  /// Snackbar when the duty switch could not be saved
  ///
  /// In en, this message translates to:
  /// **'Could not update your availability'**
  String get dutyUpdateFailed;

  /// Duty pill subtitle when no district is set
  ///
  /// In en, this message translates to:
  /// **'Taking job requests'**
  String get dutyTakingOrdersAnywhere;

  /// Availability screen title
  ///
  /// In en, this message translates to:
  /// **'My availability'**
  String get availabilityTitle;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get workingHoursHeader;

  /// Hint under the working hours header
  ///
  /// In en, this message translates to:
  /// **'Customers can only book you inside these hours.'**
  String get workingHoursHint;

  /// Shown on a weekday the worker does not work
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get dayOff;

  /// Button that saves the weekly hours
  ///
  /// In en, this message translates to:
  /// **'Save hours'**
  String get saveHours;

  /// Snackbar after saving hours
  ///
  /// In en, this message translates to:
  /// **'Working hours saved'**
  String get hoursSaved;

  /// Validation message for a day window
  ///
  /// In en, this message translates to:
  /// **'The end time must be after the start'**
  String get endAfterStart;

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Days off'**
  String get daysOffHeader;

  /// Hint under the days off header
  ///
  /// In en, this message translates to:
  /// **'Customers cannot book these days.'**
  String get daysOffHint;

  /// Button that opens the date range picker
  ///
  /// In en, this message translates to:
  /// **'Add days off'**
  String get addDaysOff;

  /// Empty state for days off
  ///
  /// In en, this message translates to:
  /// **'No days off planned'**
  String get noDaysOff;

  /// Field label in the add days off dialog
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonLabel;

  /// Hint text for the reason field
  ///
  /// In en, this message translates to:
  /// **'Festival, travel, family…'**
  String get reasonHint;

  /// Snackbar after adding days off
  ///
  /// In en, this message translates to:
  /// **'Days off added'**
  String get timeOffAdded;

  /// Snackbar after removing days off
  ///
  /// In en, this message translates to:
  /// **'Days off removed'**
  String get timeOffRemoved;

  /// Tooltip of the remove button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Dialog confirm button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// How many days a time off covers
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String dayCount(int count);

  /// A date range, first day to last day
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String dateRange(String from, String to);
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
