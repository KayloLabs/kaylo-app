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
  /// **'You will need your partner ID and password to sign in again.'**
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

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Sign in with the partner ID issued by Kaylo.'**
  String get authSubtitle;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Partner ID'**
  String get authPartnerId;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// Open self-service password recovery.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Contact Kaylo support'**
  String get authSupport;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Apply as a partner'**
  String get authApply;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Check application status'**
  String get authCheckStatus;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Demo: KP-000123 / kaylo123'**
  String get authDemoCredentials;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Enter a valid partner ID, like KP-000123.'**
  String get authInvalidId;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'The partner ID or password is incorrect.'**
  String get authInvalidCredentials;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get authTooManyAttempts;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get authNetworkError;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Unable to verify your account'**
  String get authUnavailableTitle;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'We could not verify your partner access. Try again or contact Kaylo support.'**
  String get authUnavailable;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters for your new password.'**
  String get authPasswordRule;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Choose a password different from your temporary password.'**
  String get authDifferentPassword;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign out and sign in again.'**
  String get authSessionExpired;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Your password update needs confirmation. Tap Save password again to retry securely.'**
  String get authPasswordConfirmation;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Use the partner ID and password issued by Kaylo. Customer accounts cannot sign in here.'**
  String get authIdentityNotAllowed;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Set your password'**
  String get authChangePassword;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Replace your temporary password before opening your partner account.'**
  String get authChangePasswordBody;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get authConfirmPassword;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get authSavePassword;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get authPasswordMismatch;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'This account has no issued worker profile. Apply to Kaylo or contact support about your application.'**
  String get authNotIssuedBody;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Jobs are available after Kaylo approves your verification. You can view your profile or contact support.'**
  String get authVerificationBody;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Job requests'**
  String get partnerJobNotifications;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'New job request'**
  String get partnerNewJobRequest;

  /// Partner issued-account authentication or notification text
  ///
  /// In en, this message translates to:
  /// **'Open Kaylo Partner to review the request.'**
  String get partnerOpenJobRequest;

  /// No description provided for @applicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply to Kaylo'**
  String get applicationTitle;

  /// No description provided for @applicationPersonal.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get applicationPersonal;

  /// No description provided for @applicationSkills.
  ///
  /// In en, this message translates to:
  /// **'Your work & service area'**
  String get applicationSkills;

  /// No description provided for @applicationDocuments.
  ///
  /// In en, this message translates to:
  /// **'Your documents'**
  String get applicationDocuments;

  /// No description provided for @applicationPayout.
  ///
  /// In en, this message translates to:
  /// **'Payout & consent'**
  String get applicationPayout;

  /// No description provided for @applicationStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String applicationStep(int current, int total);

  /// No description provided for @applicationIntro.
  ///
  /// In en, this message translates to:
  /// **'Apply without an account. Kaylo will review your details and documents before issuing a partner login.'**
  String get applicationIntro;

  /// No description provided for @applicationPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get applicationPhone;

  /// No description provided for @applicationEmail.
  ///
  /// In en, this message translates to:
  /// **'Delivery email'**
  String get applicationEmail;

  /// No description provided for @applicationEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Use an email you can access. Kaylo sends your partner ID and temporary password here after approval.'**
  String get applicationEmailHint;

  /// No description provided for @applicationInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number with country code'**
  String get applicationInvalidPhone;

  /// No description provided for @applicationInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid delivery email'**
  String get applicationInvalidEmail;

  /// No description provided for @applicationProfession.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get applicationProfession;

  /// No description provided for @applicationProfessionRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your profession'**
  String get applicationProfessionRequired;

  /// No description provided for @applicationExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience (years)'**
  String get applicationExperience;

  /// No description provided for @applicationInvalidExperience.
  ///
  /// In en, this message translates to:
  /// **'Enter experience from 0 to 60 years'**
  String get applicationInvalidExperience;

  /// No description provided for @applicationChooseDistrict.
  ///
  /// In en, this message translates to:
  /// **'Choose your district'**
  String get applicationChooseDistrict;

  /// No description provided for @applicationNoServices.
  ///
  /// In en, this message translates to:
  /// **'The service catalogue is not available yet. Please try again later.'**
  String get applicationNoServices;

  /// No description provided for @applicationDocumentsHint.
  ///
  /// In en, this message translates to:
  /// **'Add all five documents. Use JPG or PNG for photos; JPG, PNG or PDF for other documents. Maximum 10 MB per file.'**
  String get applicationDocumentsHint;

  /// No description provided for @applicationDocumentsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Documents are uploaded privately for Kaylo’s application review. They are not shown in the public status lookup.'**
  String get applicationDocumentsPrivacy;

  /// No description provided for @applicationPhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get applicationPhoto;

  /// No description provided for @applicationAadhaarFront.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar front'**
  String get applicationAadhaarFront;

  /// No description provided for @applicationAadhaarBack.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar back'**
  String get applicationAadhaarBack;

  /// No description provided for @applicationSelfie.
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get applicationSelfie;

  /// No description provided for @applicationChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get applicationChooseFile;

  /// No description provided for @applicationAllDocuments.
  ///
  /// In en, this message translates to:
  /// **'Add all five documents to continue'**
  String get applicationAllDocuments;

  /// No description provided for @applicationUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get applicationUpi;

  /// No description provided for @applicationBank.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get applicationBank;

  /// No description provided for @applicationAccountHolder.
  ///
  /// In en, this message translates to:
  /// **'Account holder name'**
  String get applicationAccountHolder;

  /// No description provided for @applicationBankName.
  ///
  /// In en, this message translates to:
  /// **'Bank name'**
  String get applicationBankName;

  /// No description provided for @applicationAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get applicationAccountNumber;

  /// No description provided for @applicationConfirmAccount.
  ///
  /// In en, this message translates to:
  /// **'Confirm account number'**
  String get applicationConfirmAccount;

  /// No description provided for @applicationIfsc.
  ///
  /// In en, this message translates to:
  /// **'IFSC code'**
  String get applicationIfsc;

  /// No description provided for @applicationBankRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the bank details'**
  String get applicationBankRequired;

  /// No description provided for @applicationInvalidAccount.
  ///
  /// In en, this message translates to:
  /// **'Enter a 9 to 18 digit account number'**
  String get applicationInvalidAccount;

  /// No description provided for @applicationAccountMismatch.
  ///
  /// In en, this message translates to:
  /// **'The account numbers do not match'**
  String get applicationAccountMismatch;

  /// No description provided for @applicationInvalidIfsc.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 11-character IFSC code'**
  String get applicationInvalidIfsc;

  /// No description provided for @applicationReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Check your details before sending.'**
  String get applicationReviewHint;

  /// No description provided for @applicationConsent.
  ///
  /// In en, this message translates to:
  /// **'I confirm these details are mine and accurate, and consent to Kaylo storing and reviewing my details and documents for partner verification.'**
  String get applicationConsent;

  /// No description provided for @applicationConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please give consent before submitting'**
  String get applicationConsentRequired;

  /// No description provided for @applicationKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep Kaylo open until all documents finish uploading. If your connection drops, retry here without creating another application.'**
  String get applicationKeepOpen;

  /// No description provided for @applicationBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get applicationBack;

  /// No description provided for @applicationContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get applicationContinue;

  /// No description provided for @applicationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get applicationSubmit;

  /// No description provided for @applicationSending.
  ///
  /// In en, this message translates to:
  /// **'Finish sending your application'**
  String get applicationSending;

  /// No description provided for @applicationRecoveryHint.
  ///
  /// In en, this message translates to:
  /// **'Your application is only ready for review when all five documents are received. Retry continues the same application. If you close the app before finishing, contact Kaylo with your reference.'**
  String get applicationRecoveryHint;

  /// No description provided for @applicationReference.
  ///
  /// In en, this message translates to:
  /// **'Application reference'**
  String get applicationReference;

  /// No description provided for @applicationUploadProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} documents received'**
  String applicationUploadProgress(int count, int total);

  /// No description provided for @applicationCheckStatus.
  ///
  /// In en, this message translates to:
  /// **'Check application status'**
  String get applicationCheckStatus;

  /// No description provided for @applicationBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get applicationBackToSignIn;

  /// No description provided for @applicationStatusHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your application reference to see its status. Personal details and documents are never displayed here.'**
  String get applicationStatusHint;

  /// No description provided for @applicationInvalidReference.
  ///
  /// In en, this message translates to:
  /// **'Enter the reference from your application'**
  String get applicationInvalidReference;

  /// No description provided for @applicationUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Application under review'**
  String get applicationUnderReview;

  /// No description provided for @applicationUnderReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Your details and all five documents have been received. Kaylo will review them before deciding on your application. This reference is not a partner login.'**
  String get applicationUnderReviewHint;

  /// No description provided for @applicationIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Documents still needed'**
  String get applicationIncomplete;

  /// No description provided for @applicationIncompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Your details were received, but document upload is not complete. Resume from this app session or contact Kaylo with your reference for help.'**
  String get applicationIncompleteHint;

  /// No description provided for @applicationApproved.
  ///
  /// In en, this message translates to:
  /// **'Application approved'**
  String get applicationApproved;

  /// No description provided for @applicationApprovedHint.
  ///
  /// In en, this message translates to:
  /// **'Kaylo sends your partner ID and temporary password to your delivery email after approval. If you have not received them, contact support. Your first sign-in requires a new password.'**
  String get applicationApprovedHint;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application not approved'**
  String get applicationRejected;

  /// No description provided for @applicationRejectedHint.
  ///
  /// In en, this message translates to:
  /// **'Kaylo has not approved this application. No partner login is available for it. Contact support with your reference for further help.'**
  String get applicationRejectedHint;

  /// No description provided for @applicationCopyReference.
  ///
  /// In en, this message translates to:
  /// **'Copy reference'**
  String get applicationCopyReference;

  /// No description provided for @applicationReferenceCopied.
  ///
  /// In en, this message translates to:
  /// **'Reference copied'**
  String get applicationReferenceCopied;

  /// No description provided for @applicationResumeUpload.
  ///
  /// In en, this message translates to:
  /// **'Resume document upload'**
  String get applicationResumeUpload;

  /// No description provided for @applicationContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Kaylo support'**
  String get applicationContactSupport;

  /// No description provided for @applicationSupportSubject.
  ///
  /// In en, this message translates to:
  /// **'Partner application help: {reference}'**
  String applicationSupportSubject(String reference);

  /// No description provided for @applicationSupportHint.
  ///
  /// In en, this message translates to:
  /// **'Email kayloapp@gmail.com with your application reference.'**
  String get applicationSupportHint;

  /// No description provided for @applicationDemoNotice.
  ///
  /// In en, this message translates to:
  /// **'Sample mode: this application stays in this app session and is not sent to Kaylo.'**
  String get applicationDemoNotice;

  /// No description provided for @applicationConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Check your connection and retry.'**
  String get applicationConnectionError;

  /// No description provided for @applicationAlreadyOpen.
  ///
  /// In en, this message translates to:
  /// **'There is already an open application for this phone number. Check its status or contact Kaylo support.'**
  String get applicationAlreadyOpen;

  /// No description provided for @applicationInvalidDetails.
  ///
  /// In en, this message translates to:
  /// **'Please check your application details.'**
  String get applicationInvalidDetails;

  /// No description provided for @applicationInvalidDocument.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid JPG, PNG or PDF file, up to 10 MB. Profile photos and selfies must be images.'**
  String get applicationInvalidDocument;

  /// No description provided for @applicationUploadExpired.
  ///
  /// In en, this message translates to:
  /// **'The upload session is no longer available. Contact Kaylo with your reference to finish your application.'**
  String get applicationUploadExpired;

  /// No description provided for @applicationNotFound.
  ///
  /// In en, this message translates to:
  /// **'No application matches that reference. Check the reference and try again.'**
  String get applicationNotFound;

  /// No description provided for @applicationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Applications are unavailable right now. Please try again later or contact Kaylo support.'**
  String get applicationUnavailable;

  /// No description provided for @applicationIdentityInUse.
  ///
  /// In en, this message translates to:
  /// **'This phone or email is already used by a Kaylo account. Contact support before applying with this identity.'**
  String get applicationIdentityInUse;

  /// No description provided for @liveJobsPending.
  ///
  /// In en, this message translates to:
  /// **'Live job requests and earnings are not available yet. Your profile and availability are ready to use.'**
  String get liveJobsPending;

  /// No description provided for @applicationChangesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get applicationChangesRequested;

  /// No description provided for @applicationChangesRequestedHint.
  ///
  /// In en, this message translates to:
  /// **'Kaylo needs updated documents before reviewing your application again. Open the secure link sent to your email to see the instructions and submit replacements.'**
  String get applicationChangesRequestedHint;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatMessages;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Chat ({count})'**
  String chatUnread(int count);

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'View conversation'**
  String get chatViewConversation;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Your conversations start here'**
  String get chatNoMessages;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Accept a job, then open Chat to message your customer.'**
  String get chatNoMessagesBody;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Send a message about this booking.'**
  String get chatStartConversation;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load this conversation. Please try again.'**
  String get chatLoadFailed;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Message your customer'**
  String get chatMessageHint;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get chatSend;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Your message wasn’t sent. Try sending it again.'**
  String get chatSendFailed;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Customer is typing…'**
  String get chatTyping;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatRead;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatSent;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'This booking has ended. You can still read its conversation.'**
  String get chatReadOnly;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'On my way'**
  String get chatOnMyWay;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'I’ve reached'**
  String get chatReached;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Running 10 min late'**
  String get chatLate;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Please share the exact location'**
  String get chatExactLocation;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Please come to the back gate.'**
  String get chatMockBackGate;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Okay, waiting.'**
  String get chatMockWaiting;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Call when you reach.'**
  String get chatMockCall;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Is 10 minutes fine?'**
  String get chatMockTenMinutes;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get chatMockThanks;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'The dog is friendly, don’t worry.'**
  String get chatMockDog;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get alertsMarkAllRead;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get alertsToday;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get alertsEarlier;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up'**
  String get alertsEmpty;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'New requests and job updates will appear here.'**
  String get alertsEmptyBody;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load your alerts. Please try again.'**
  String get alertsLoadFailed;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'We couldn’t update this alert. Please try again.'**
  String get alertsUpdateFailed;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'New job request'**
  String get alertNewRequest;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Job accepted'**
  String get alertAccepted;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Your customer knows you’re on the way'**
  String get alertOnTheWay;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Arrival confirmed'**
  String get alertArrived;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Work has started'**
  String get alertInProgress;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Job completed'**
  String get alertCompleted;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Job cancelled'**
  String get alertCancelled;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'{service} · {distance} km away'**
  String alertRequestBody(String service, String distance);

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'{service} · Open for booking details'**
  String alertJobBody(String service);

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get reviewsSeeAll;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Customer rating'**
  String get reviewsCustomerRating;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'{stars} stars: {count} reviews'**
  String reviewsDistribution(int stars, int count);

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reviewsAll;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'5 stars'**
  String get reviewsFive;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'4 stars'**
  String get reviewsFour;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'3 stars & below'**
  String get reviewsThreeBelow;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'No reviews here yet'**
  String get reviewsEmpty;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Customer reviews appear here after completed jobs.'**
  String get reviewsEmptyBody;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load your reviews. Please try again.'**
  String get reviewsLoadFailed;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Fixed the leaking tap neatly and explained the repair.'**
  String get reviewSample1;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'On time and very helpful.'**
  String get reviewSample2;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Good work. Left the place clean.'**
  String get reviewSample3;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Careful work and clear communication throughout.'**
  String get reviewSample4;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'The repair was good, but arrived half an hour late without an update.'**
  String get reviewSample5;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Would happily book again.'**
  String get reviewSample6;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Solved the problem and answered all our questions.'**
  String get reviewSample7;

  /// Partner messages, alerts and reviews
  ///
  /// In en, this message translates to:
  /// **'Patient, polite, and thorough. Thank you.'**
  String get reviewSample8;

  /// Partner communication and alert labels
  ///
  /// In en, this message translates to:
  /// **'Call customer'**
  String get chatCallCustomer;

  /// Partner communication and alert labels
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get chatNavigate;

  /// Partner communication and alert labels
  ///
  /// In en, this message translates to:
  /// **'You can view this job and contact the customer. Job status updates are not available yet.'**
  String get partnerJobReadOnly;

  /// Partner communication and alert labels
  ///
  /// In en, this message translates to:
  /// **'Cash collected'**
  String get alertCashCollected;

  /// Partner communication and alert labels
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get alertPaymentReceived;

  /// Partner communication and alert labels
  ///
  /// In en, this message translates to:
  /// **'Settlement recorded'**
  String get alertSettlement;

  /// Jobs tab snackbar when a manual refresh fails
  ///
  /// In en, this message translates to:
  /// **'We couldn’t refresh your jobs. Please try again.'**
  String get jobsRefreshFailed;

  /// Relative scheduled time: in X minutes
  ///
  /// In en, this message translates to:
  /// **'in {minutes} min'**
  String timeInMinutes(int minutes);

  /// Relative scheduled time: in X hours
  ///
  /// In en, this message translates to:
  /// **'in {hours} hr'**
  String timeInHours(int hours);

  /// Relative scheduled time: tomorrow at time
  ///
  /// In en, this message translates to:
  /// **'tomorrow {time}'**
  String timeTomorrow(String time);

  /// Relative scheduled time: today at time
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String timeToday(String time);

  /// Relative scheduled time: X minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String timeMinutesAgo(int minutes);

  /// Job sort option: nearest distance
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get sortNearest;

  /// Job sort option: highest payout
  ///
  /// In en, this message translates to:
  /// **'Highest payout'**
  String get sortHighestPayout;

  /// Job sort option: soonest scheduled time
  ///
  /// In en, this message translates to:
  /// **'Soonest'**
  String get sortSoonest;

  /// Empty state title when active filters return no jobs
  ///
  /// In en, this message translates to:
  /// **'No jobs match your filter'**
  String get filterEmptyTitle;

  /// Empty state subtitle when active filters return no jobs
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filter options or clear them to see all jobs.'**
  String get filterEmptySubtitle;

  /// Action button to clear active filters
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// Button to expand map to full screen
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// Button to open coordinates in external Google Maps application
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// Estimated travel duration in minutes
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min'**
  String aboutMinutes(int minutes);

  /// Title for full screen map route
  ///
  /// In en, this message translates to:
  /// **'Job Location Map'**
  String get jobLocationMap;

  /// No description provided for @servicePlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get servicePlumbing;

  /// No description provided for @serviceElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get serviceElectrical;

  /// No description provided for @serviceAppliances.
  ///
  /// In en, this message translates to:
  /// **'Appliances'**
  String get serviceAppliances;

  /// No description provided for @serviceCarpentry.
  ///
  /// In en, this message translates to:
  /// **'Carpentry'**
  String get serviceCarpentry;

  /// No description provided for @mapJobNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job not found'**
  String get mapJobNotFound;

  /// No description provided for @mapJobMissing.
  ///
  /// In en, this message translates to:
  /// **'This job could not be located.'**
  String get mapJobMissing;

  /// No description provided for @mapNavigationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Navigation is unavailable on this device'**
  String get mapNavigationUnavailable;

  /// No description provided for @mapLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location is unavailable for this job'**
  String get mapLocationUnavailable;

  /// No description provided for @mapDistanceEstimate.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away · about {minutes} min'**
  String mapDistanceEstimate(String distance, int minutes);

  /// No description provided for @jobDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String jobDistanceAway(String distance);

  /// No description provided for @mapApproximateArea.
  ///
  /// In en, this message translates to:
  /// **'Approximate area'**
  String get mapApproximateArea;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetTitle;

  /// No description provided for @authResetDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your Partner ID and the email address you registered with. We’ll email you a link to choose a new password.'**
  String get authResetDescription;

  /// No description provided for @authResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Registered email'**
  String get authResetEmail;

  /// No description provided for @authResetInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email address.'**
  String get authResetInvalidEmail;

  /// No description provided for @authResetSend.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authResetSend;

  /// No description provided for @authResetInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get authResetInbox;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'If these details match an active partner account, a reset link will arrive by email. Check your spam folder too. After resetting, sign in with your Partner ID and new password.'**
  String get authResetSent;

  /// No description provided for @authResetResend.
  ///
  /// In en, this message translates to:
  /// **'Send another link'**
  String get authResetResend;

  /// No description provided for @authResetResendIn.
  ///
  /// In en, this message translates to:
  /// **'Send again in {seconds}s'**
  String authResetResendIn(int seconds);

  /// No description provided for @authResetBack.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authResetBack;

  /// No description provided for @authResetDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo mode does not send reset emails. Use the live app to reset your password.'**
  String get authResetDemo;

  /// Confirmation after the server updates and reloads the job
  ///
  /// In en, this message translates to:
  /// **'Status updated to {stage}'**
  String jobStageUpdated(String stage);

  /// No description provided for @jobStageUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm the status update. Check the current job status and try again.'**
  String get jobStageUpdateFailed;

  /// No description provided for @jobCashRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash collection before completing this cash booking.'**
  String get jobCashRequired;

  /// No description provided for @homeMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeMorning;

  /// No description provided for @homeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeAfternoon;

  /// No description provided for @homeEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeEvening;

  /// No description provided for @homeDayOverview.
  ///
  /// In en, this message translates to:
  /// **'Your day, at a glance.'**
  String get homeDayOverview;

  /// No description provided for @homeReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for your next job'**
  String get homeReadyTitle;

  /// No description provided for @homeReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking requests will appear here. Keep your working hours up to date.'**
  String get homeReadyBody;

  /// No description provided for @homeRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Taking a break'**
  String get homeRestTitle;

  /// No description provided for @homeRestBody.
  ///
  /// In en, this message translates to:
  /// **'Customers can still request a booking within your working hours.'**
  String get homeRestBody;

  /// No description provided for @homeOnDuty.
  ///
  /// In en, this message translates to:
  /// **'On duty'**
  String get homeOnDuty;

  /// No description provided for @homeOffDuty.
  ///
  /// In en, this message translates to:
  /// **'Off duty'**
  String get homeOffDuty;

  /// No description provided for @homeOnDutyHint.
  ///
  /// In en, this message translates to:
  /// **'Open to new work'**
  String get homeOnDutyHint;

  /// No description provided for @homeOffDutyHint.
  ///
  /// In en, this message translates to:
  /// **'Scheduled bookings are still open'**
  String get homeOffDutyHint;

  /// No description provided for @homeSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get homeSchedule;

  /// No description provided for @homeHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get homeHistory;

  /// No description provided for @confirmCashReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash received'**
  String get confirmCashReceived;

  /// No description provided for @confirmCashReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you received {amount} from the customer. This will complete the job.'**
  String confirmCashReceivedBody(String amount);

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get cashReceived;

  /// No description provided for @cashAmountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The payable amount could not be loaded. Refresh the job before confirming cash.'**
  String get cashAmountUnavailable;

  /// No description provided for @callAudioOutputFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change audio output. The call is still active.'**
  String get callAudioOutputFailed;

  /// No description provided for @callConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get callConnecting;

  /// No description provided for @callCouldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect'**
  String get callCouldNotConnect;

  /// No description provided for @callDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get callDeclined;

  /// No description provided for @callEndForEveryone.
  ///
  /// In en, this message translates to:
  /// **'End call for everyone'**
  String get callEndForEveryone;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callEnded;

  /// No description provided for @callErrorJoin.
  ///
  /// In en, this message translates to:
  /// **'Could not join this call. Retry or ask the caller to start a new call.'**
  String get callErrorJoin;

  /// No description provided for @callErrorMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Could not access the microphone. Check microphone access for Kaylo and retry.'**
  String get callErrorMicrophone;

  /// No description provided for @callErrorRoom.
  ///
  /// In en, this message translates to:
  /// **'This call is unavailable or has ended. Ask the caller to start a new call.'**
  String get callErrorRoom;

  /// No description provided for @callErrorSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not load call settings. Check your connection and retry.'**
  String get callErrorSettings;

  /// No description provided for @callInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Connection interrupted. Retrying…'**
  String get callInterrupted;

  /// No description provided for @callInvitedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Invited • Waiting to answer'**
  String get callInvitedWaiting;

  /// No description provided for @callKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep Kaylo open during the call.'**
  String get callKeepOpen;

  /// No description provided for @callLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave call'**
  String get callLeave;

  /// No description provided for @callLeft.
  ///
  /// In en, this message translates to:
  /// **'Left the call'**
  String get callLeft;

  /// No description provided for @callPeerConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get callPeerConnected;

  /// No description provided for @callPeerConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get callPeerConnecting;

  /// No description provided for @callPeerFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get callPeerFailed;

  /// No description provided for @callPeerReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get callPeerReconnecting;

  /// No description provided for @callTitle.
  ///
  /// In en, this message translates to:
  /// **'Kaylo SOS call'**
  String get callTitle;

  /// No description provided for @callYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get callYou;

  /// No description provided for @callYouMuted.
  ///
  /// In en, this message translates to:
  /// **'You • Muted'**
  String get callYouMuted;

  /// No description provided for @callYourCircle.
  ///
  /// In en, this message translates to:
  /// **'Your trusted circle'**
  String get callYourCircle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @retryCall.
  ///
  /// In en, this message translates to:
  /// **'Retry call'**
  String get retryCall;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @bookingCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Kaylo call'**
  String get bookingCallTitle;

  /// No description provided for @bookingCallConnected.
  ///
  /// In en, this message translates to:
  /// **'Booking call'**
  String get bookingCallConnected;

  /// No description provided for @bookingCallIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming Kaylo call'**
  String get bookingCallIncoming;

  /// No description provided for @bookingCallIncomingBody.
  ///
  /// In en, this message translates to:
  /// **'A booking participant is calling.'**
  String get bookingCallIncomingBody;

  /// No description provided for @bookingCallFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the call. Check your connection and retry.'**
  String get bookingCallFailed;
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
