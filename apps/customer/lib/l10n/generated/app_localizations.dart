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

  /// No description provided for @sosCallWaiting.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}. The call starts after 3 seconds in Kaylo.'**
  String sosCallWaiting(String name);

  /// No description provided for @sosCallProgress.
  ///
  /// In en, this message translates to:
  /// **'{attempted} of {total} calls attempted'**
  String sosCallProgress(int attempted, int total);

  /// No description provided for @sosCallsFinished.
  ///
  /// In en, this message translates to:
  /// **'Call sequence finished. An attempted call does not confirm someone answered.'**
  String get sosCallsFinished;

  /// No description provided for @sosCallsStopped.
  ///
  /// In en, this message translates to:
  /// **'Remaining calls stopped. An ongoing call can be ended in your phone app.'**
  String get sosCallsStopped;

  /// No description provided for @sosStopCalls.
  ///
  /// In en, this message translates to:
  /// **'Stop remaining calls'**
  String get sosStopCalls;

  /// No description provided for @sosAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'SIM calling is available on Android phones.'**
  String get sosAndroidOnly;

  /// No description provided for @careDosesTaken.
  ///
  /// In en, this message translates to:
  /// **'{taken} of {total} doses taken'**
  String careDosesTaken(int taken, int total);

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @searchServices.
  ///
  /// In en, this message translates to:
  /// **'Search services…'**
  String get searchServices;

  /// No description provided for @whatDoYouNeedHelpWith.
  ///
  /// In en, this message translates to:
  /// **'What do you need help with?'**
  String get whatDoYouNeedHelpWith;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Solutions for\nyour home.'**
  String get homeSubtitle;

  /// No description provided for @farm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farm;

  /// No description provided for @farmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Care and support\nfor your farm.'**
  String get farmSubtitle;

  /// No description provided for @care.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get care;

  /// No description provided for @careSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help for your\nloved ones.'**
  String get careSubtitle;

  /// No description provided for @popularServices.
  ///
  /// In en, this message translates to:
  /// **'Popular Services'**
  String get popularServices;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help you today?'**
  String get howCanWeHelp;

  /// No description provided for @heroCoconutTitle.
  ///
  /// In en, this message translates to:
  /// **'Coconut\nHarvesting\nMade Easy'**
  String get heroCoconutTitle;

  /// No description provided for @heroCoconutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book trusted climbers\nin your area'**
  String get heroCoconutSubtitle;

  /// No description provided for @heroCleanTitle.
  ///
  /// In en, this message translates to:
  /// **'Deep Clean\nYour Home\nToday'**
  String get heroCleanTitle;

  /// No description provided for @heroCleanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Professional services\nat your doorstep'**
  String get heroCleanSubtitle;

  /// No description provided for @heroPlumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Expert Plumbers\n& Farmers\nReady'**
  String get heroPlumberTitle;

  /// No description provided for @heroPlumberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reliable helpers for\nevery task'**
  String get heroPlumberSubtitle;

  /// No description provided for @heroBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get heroBookNow;

  /// No description provided for @heroExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get heroExplore;

  /// No description provided for @heroHireNow.
  ///
  /// In en, this message translates to:
  /// **'Hire Now'**
  String get heroHireNow;

  /// No description provided for @promoTitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss important work'**
  String get promoTitle;

  /// No description provided for @promoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set reminders and we\'ll take\ncare of the rest.'**
  String get promoSubtitle;

  /// No description provided for @promoButton.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get promoButton;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYou;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @careModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Kaylo Care Mode'**
  String get careModeTitle;

  /// No description provided for @careModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Larger text and simpler screens for seniors'**
  String get careModeSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Booking updates and offers'**
  String get pushNotificationsSubtitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @termsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsPrivacy;

  /// No description provided for @madeInKerala.
  ///
  /// In en, this message translates to:
  /// **'Made with ♥ in Kerala'**
  String get madeInKerala;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @statBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get statBookings;

  /// No description provided for @statRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get statRating;

  /// No description provided for @statSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get statSaved;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @myBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track and manage your services'**
  String get myBookingsSubtitle;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddresses;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, language, care mode, notifications'**
  String get settingsSubtitle;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @rateKaylo.
  ///
  /// In en, this message translates to:
  /// **'Rate Kaylo'**
  String get rateKaylo;

  /// No description provided for @rateThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the love!'**
  String get rateThanks;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutConfirmTitle;

  /// No description provided for @logOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to book services.'**
  String get logOutConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @profileEditSoon.
  ///
  /// In en, this message translates to:
  /// **'Profile editing arrives with sign-in'**
  String get profileEditSoon;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @statCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statCompleted;

  /// No description provided for @kayloCare.
  ///
  /// In en, this message translates to:
  /// **'Kaylo Care'**
  String get kayloCare;

  /// No description provided for @careHomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'How can we care for you today?'**
  String get careHomeGreeting;

  /// No description provided for @medicineReminders.
  ///
  /// In en, this message translates to:
  /// **'Medicine Reminders'**
  String get medicineReminders;

  /// No description provided for @medicineRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss a dose'**
  String get medicineRemindersSubtitle;

  /// No description provided for @doctorAppointment.
  ///
  /// In en, this message translates to:
  /// **'Doctor Appointment'**
  String get doctorAppointment;

  /// No description provided for @doctorAppointmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book a visit or teleconsult'**
  String get doctorAppointmentSubtitle;

  /// No description provided for @emergencySos.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergencySos;

  /// No description provided for @emergencySosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alert your family instantly'**
  String get emergencySosSubtitle;

  /// No description provided for @caregiverBooking.
  ///
  /// In en, this message translates to:
  /// **'Book a Caregiver'**
  String get caregiverBooking;

  /// No description provided for @caregiverBookingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted help at home'**
  String get caregiverBookingSubtitle;

  /// No description provided for @themeCareOverride.
  ///
  /// In en, this message translates to:
  /// **'Theme follows Care Mode while it is on'**
  String get themeCareOverride;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @voiceSearch.
  ///
  /// In en, this message translates to:
  /// **'Voice search'**
  String get voiceSearch;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get voiceListening;

  /// No description provided for @voiceTapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Speak now, in any app language'**
  String get voiceTapToSpeak;

  /// No description provided for @voiceYouSaid.
  ///
  /// In en, this message translates to:
  /// **'You said'**
  String get voiceYouSaid;

  /// No description provided for @voiceNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching service found. Try again?'**
  String get voiceNoMatch;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice search is not available on this device'**
  String get voiceUnavailable;

  /// No description provided for @voiceTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get voiceTryAgain;

  /// No description provided for @voiceMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access was denied. Allow it in your browser or phone settings to use voice search.'**
  String get voiceMicDenied;

  /// No description provided for @homeServices.
  ///
  /// In en, this message translates to:
  /// **'Home Services'**
  String get homeServices;

  /// No description provided for @allHomeServices.
  ///
  /// In en, this message translates to:
  /// **'All Home Services'**
  String get allHomeServices;

  /// No description provided for @exploreHomeServices.
  ///
  /// In en, this message translates to:
  /// **'Explore verified home service professionals'**
  String get exploreHomeServices;

  /// No description provided for @serviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetails;

  /// No description provided for @professionalAtDoorstep.
  ///
  /// In en, this message translates to:
  /// **'Professional services at your doorstep'**
  String get professionalAtDoorstep;

  /// No description provided for @popularSubServices.
  ///
  /// In en, this message translates to:
  /// **'Popular Sub-services'**
  String get popularSubServices;

  /// No description provided for @selectSubServices.
  ///
  /// In en, this message translates to:
  /// **'Select sub-services'**
  String get selectSubServices;

  /// No description provided for @startingFrom.
  ///
  /// In en, this message translates to:
  /// **'Starts from'**
  String get startingFrom;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookNow;

  /// No description provided for @bookService.
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get bookService;

  /// No description provided for @workersAvailable.
  ///
  /// In en, this message translates to:
  /// **'workers available'**
  String get workersAvailable;

  /// No description provided for @availableWorkers.
  ///
  /// In en, this message translates to:
  /// **'Available Workers'**
  String get availableWorkers;

  /// No description provided for @sortAndFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort & Filter'**
  String get sortAndFilter;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get priceLowToHigh;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get priceHighToLow;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @availableToday.
  ///
  /// In en, this message translates to:
  /// **'Available Today'**
  String get availableToday;

  /// No description provided for @minRating.
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get minRating;

  /// No description provided for @verifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified Only'**
  String get verifiedOnly;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @noWorkersFound.
  ///
  /// In en, this message translates to:
  /// **'No workers found matching your criteria'**
  String get noWorkersFound;

  /// No description provided for @workerProfile.
  ///
  /// In en, this message translates to:
  /// **'Worker Profile'**
  String get workerProfile;

  /// No description provided for @completedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed Jobs'**
  String get completedJobs;

  /// No description provided for @yearsExperience.
  ///
  /// In en, this message translates to:
  /// **'Years Experience'**
  String get yearsExperience;

  /// No description provided for @trustScore.
  ///
  /// In en, this message translates to:
  /// **'Trust Score'**
  String get trustScore;

  /// No description provided for @responseTime.
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get responseTime;

  /// No description provided for @certifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @customerReviews.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customerReviews;

  /// No description provided for @verifiedProfessional.
  ///
  /// In en, this message translates to:
  /// **'Verified Professional'**
  String get verifiedProfessional;

  /// No description provided for @searchServicesOrWorkers.
  ///
  /// In en, this message translates to:
  /// **'Search services or professionals…'**
  String get searchServicesOrWorkers;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @professionals.
  ///
  /// In en, this message translates to:
  /// **'Professionals'**
  String get professionals;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found for'**
  String get noResultsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try searching for another service or professional'**
  String get tryDifferentSearch;

  /// No description provided for @selectSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Select Specialty'**
  String get selectSpecialty;

  /// No description provided for @availableDoctors.
  ///
  /// In en, this message translates to:
  /// **'Available Doctors'**
  String get availableDoctors;

  /// No description provided for @consultationFee.
  ///
  /// In en, this message translates to:
  /// **'Consultation Fee'**
  String get consultationFee;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get selectDate;

  /// No description provided for @selectTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Time slot'**
  String get selectTimeSlot;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @consultationType.
  ///
  /// In en, this message translates to:
  /// **'Consultation Type'**
  String get consultationType;

  /// No description provided for @homeVisit.
  ///
  /// In en, this message translates to:
  /// **'Home Visit'**
  String get homeVisit;

  /// No description provided for @teleconsult.
  ///
  /// In en, this message translates to:
  /// **'Video Teleconsult'**
  String get teleconsult;

  /// No description provided for @confirmAppointment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Appointment'**
  String get confirmAppointment;

  /// No description provided for @upcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointments'**
  String get upcomingAppointments;

  /// No description provided for @appointmentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Appointment Confirmed!'**
  String get appointmentConfirmed;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Your appointment has been scheduled.'**
  String get appointmentDetails;

  /// No description provided for @selectCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Select Caregiver'**
  String get selectCaregiver;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @selectHours.
  ///
  /// In en, this message translates to:
  /// **'Select Hours'**
  String get selectHours;

  /// No description provided for @careType.
  ///
  /// In en, this message translates to:
  /// **'Care Type'**
  String get careType;

  /// No description provided for @elderlyCare.
  ///
  /// In en, this message translates to:
  /// **'Elderly Care'**
  String get elderlyCare;

  /// No description provided for @postOpCare.
  ///
  /// In en, this message translates to:
  /// **'Post-operative Care'**
  String get postOpCare;

  /// No description provided for @companionship.
  ///
  /// In en, this message translates to:
  /// **'Companionship'**
  String get companionship;

  /// No description provided for @mobilityAssistance.
  ///
  /// In en, this message translates to:
  /// **'Mobility Assistance'**
  String get mobilityAssistance;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @caregiverBooked.
  ///
  /// In en, this message translates to:
  /// **'Caregiver Booked!'**
  String get caregiverBooked;

  /// No description provided for @caregiverBookingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your caregiver request has been submitted.'**
  String get caregiverBookingSuccess;

  /// No description provided for @nearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get nearYou;

  /// No description provided for @farmServices.
  ///
  /// In en, this message translates to:
  /// **'Farm Services'**
  String get farmServices;

  /// No description provided for @farmServicesTagline.
  ///
  /// In en, this message translates to:
  /// **'Verified climbers, harvesters and farm hands, booked by the tree or by the hour.'**
  String get farmServicesTagline;

  /// No description provided for @noServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get noServicesTitle;

  /// No description provided for @noServicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Farm services will appear here as workers are onboarded.'**
  String get noServicesDescription;

  /// No description provided for @perUnit.
  ///
  /// In en, this message translates to:
  /// **'per {unit}'**
  String perUnit(String unit);

  /// No description provided for @unitTree.
  ///
  /// In en, this message translates to:
  /// **'tree'**
  String get unitTree;

  /// No description provided for @unitHour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get unitHour;

  /// No description provided for @unitVisit.
  ///
  /// In en, this message translates to:
  /// **'visit'**
  String get unitVisit;

  /// No description provided for @unitTreeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tree} other{{count} trees}}'**
  String unitTreeCount(int count);

  /// No description provided for @unitHourCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String unitHourCount(int count);

  /// No description provided for @unitVisitCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 visit} other{{count} visits}}'**
  String unitVisitCount(int count);

  /// No description provided for @serviceStandards.
  ///
  /// In en, this message translates to:
  /// **'What the worker commits to'**
  String get serviceStandards;

  /// No description provided for @standardSafetyHarness.
  ///
  /// In en, this message translates to:
  /// **'Safety harness on every climb'**
  String get standardSafetyHarness;

  /// No description provided for @standardBunchProtection.
  ///
  /// In en, this message translates to:
  /// **'Bunches lowered on ropes, never dropped'**
  String get standardBunchProtection;

  /// No description provided for @standardDebrisCleared.
  ///
  /// In en, this message translates to:
  /// **'Fronds and husks cleared before leaving'**
  String get standardDebrisCleared;

  /// No description provided for @standardGroundNets.
  ///
  /// In en, this message translates to:
  /// **'Ground nets to protect crops below'**
  String get standardGroundNets;

  /// No description provided for @standardPowerLineGuard.
  ///
  /// In en, this message translates to:
  /// **'Safe clearance from power lines'**
  String get standardPowerLineGuard;

  /// No description provided for @standardWoodChipping.
  ///
  /// In en, this message translates to:
  /// **'Cut branches chipped or stacked neatly'**
  String get standardWoodChipping;

  /// No description provided for @standardEcoCompost.
  ///
  /// In en, this message translates to:
  /// **'Organic compost and mulch only'**
  String get standardEcoCompost;

  /// No description provided for @standardPestPrevention.
  ///
  /// In en, this message translates to:
  /// **'Pest check on every visit'**
  String get standardPestPrevention;

  /// No description provided for @standardBoundaryClearing.
  ///
  /// In en, this message translates to:
  /// **'Boundaries and drains cleared'**
  String get standardBoundaryClearing;

  /// No description provided for @standardVerifiedWorker.
  ///
  /// In en, this message translates to:
  /// **'ID-verified worker'**
  String get standardVerifiedWorker;

  /// No description provided for @standardOnTimeArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrives in the booked time slot'**
  String get standardOnTimeArrival;

  /// No description provided for @standardFairPrice.
  ///
  /// In en, this message translates to:
  /// **'Price agreed before work starts'**
  String get standardFairPrice;

  /// No description provided for @workersNearYou.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 verified worker near you} other{{count} verified workers near you}}'**
  String workersNearYou(int count);

  /// No description provided for @noWorkersYet.
  ///
  /// In en, this message translates to:
  /// **'Workers for this service are being onboarded'**
  String get noWorkersYet;

  /// No description provided for @liveTotalNote.
  ///
  /// In en, this message translates to:
  /// **'Your total updates live as you set the quantity on the next step.'**
  String get liveTotalNote;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @priceEach.
  ///
  /// In en, this message translates to:
  /// **'{price} each'**
  String priceEach(String price);

  /// No description provided for @calculation.
  ///
  /// In en, this message translates to:
  /// **'How it adds up'**
  String get calculation;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'{price} × {units}'**
  String breakdown(String price, String units);

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @farmAddress.
  ///
  /// In en, this message translates to:
  /// **'Farm address'**
  String get farmAddress;

  /// No description provided for @farmAddressHint.
  ///
  /// In en, this message translates to:
  /// **'House name, street, town'**
  String get farmAddressHint;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the farm address'**
  String get addressRequired;

  /// No description provided for @serviceAddress.
  ///
  /// In en, this message translates to:
  /// **'Service address'**
  String get serviceAddress;

  /// No description provided for @serviceAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the service address'**
  String get serviceAddressRequired;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @popularSearches.
  ///
  /// In en, this message translates to:
  /// **'Popular searches'**
  String get popularSearches;

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get continueToPayment;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentTitle;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get orderSummary;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total payable'**
  String get totalPayable;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @payUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get payUpi;

  /// No description provided for @payUpiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Google Pay, PhonePe, Paytm'**
  String get payUpiSubtitle;

  /// No description provided for @payCard.
  ///
  /// In en, this message translates to:
  /// **'Credit or debit card'**
  String get payCard;

  /// No description provided for @payCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visa, Mastercard, RuPay'**
  String get payCardSubtitle;

  /// No description provided for @payAfter.
  ///
  /// In en, this message translates to:
  /// **'Pay cash after the service'**
  String get payAfter;

  /// No description provided for @payAfterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hand the cash to the worker once the job is done'**
  String get payAfterSubtitle;

  /// No description provided for @confirmAndPay.
  ///
  /// In en, this message translates to:
  /// **'Confirm and pay {amount}'**
  String confirmAndPay(String amount);

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'The payment did not go through. Please try again.'**
  String get paymentFailed;

  /// No description provided for @draftMissing.
  ///
  /// In en, this message translates to:
  /// **'This step needs a booking in progress. Start again from Farm Services.'**
  String get draftMissing;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingConfirmed;

  /// No description provided for @bookingConfirmedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your worker will arrive on {date} at {time}'**
  String bookingConfirmedSubtitle(String date, String time);

  /// No description provided for @bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get bookingId;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @viewMyBookings.
  ///
  /// In en, this message translates to:
  /// **'View my bookings'**
  String get viewMyBookings;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @noBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get noBookingsTitle;

  /// No description provided for @noBookingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Book a farm or home service and it will show up here.'**
  String get noBookingsDescription;

  /// No description provided for @bookAService.
  ///
  /// In en, this message translates to:
  /// **'Book a service'**
  String get bookAService;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @messagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with the workers you have booked'**
  String get messagesSubtitle;

  /// No description provided for @noMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noMessagesTitle;

  /// No description provided for @noMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Once you book a worker, you can message them here.'**
  String get noMessagesDescription;

  /// No description provided for @noMessagesInThread.
  ///
  /// In en, this message translates to:
  /// **'Say hello to start the conversation'**
  String get noMessagesInThread;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeMessage;

  /// No description provided for @todaysMedicines.
  ///
  /// In en, this message translates to:
  /// **'Today\'s medicines'**
  String get todaysMedicines;

  /// No description provided for @medicinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the circle after you take a dose'**
  String get medicinesSubtitle;

  /// No description provided for @pendingDoses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All doses taken} =1{1 dose pending} other{{count} doses pending}}'**
  String pendingDoses(int count);

  /// No description provided for @nextDose.
  ///
  /// In en, this message translates to:
  /// **'Next: {name} at {time}'**
  String nextDose(String name, String time);

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get medicineName;

  /// No description provided for @medicineNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. BP tablet'**
  String get medicineNameHint;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @dosageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 tablet after breakfast'**
  String get dosageHint;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @addedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String addedBy(String name);

  /// No description provided for @markedTaken.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as taken'**
  String markedTaken(String name);

  /// No description provided for @markedPending.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as pending'**
  String markedPending(String name);

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get nameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number'**
  String get phoneRequired;

  /// No description provided for @noRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get noRemindersTitle;

  /// No description provided for @noRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your medicines and Kaylo will remind you at the right time.'**
  String get noRemindersDescription;

  /// No description provided for @pressAndHold.
  ///
  /// In en, this message translates to:
  /// **'Press and hold'**
  String get pressAndHold;

  /// No description provided for @holdSeconds.
  ///
  /// In en, this message translates to:
  /// **'Hold for 3 seconds'**
  String get holdSeconds;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String secondsShort(int seconds);

  /// No description provided for @sosHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Hold for 3 seconds to call your contacts through your SIM, primary contact first. After each call ends, return to Kaylo to continue. Normal SIM charges apply.'**
  String get sosHoldHint;

  /// No description provided for @sosReleasedEarly.
  ///
  /// In en, this message translates to:
  /// **'Keep holding for 3 seconds to start calling'**
  String get sosReleasedEarly;

  /// No description provided for @sosSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Help is on the way'**
  String get sosSentTitle;

  /// No description provided for @sosSentContacts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contact alerted with your location} other{{count} contacts alerted with your location}}'**
  String sosSentContacts(int count);

  /// No description provided for @sosCallingPrimary.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}'**
  String sosCallingPrimary(String name);

  /// No description provided for @sosNoContacts.
  ///
  /// In en, this message translates to:
  /// **'Add an emergency contact first, so someone receives the alert.'**
  String get sosNoContacts;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get emergencyContacts;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get addContact;

  /// No description provided for @contactName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactName;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @relationshipHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Daughter'**
  String get relationshipHint;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @setAsPrimary.
  ///
  /// In en, this message translates to:
  /// **'Set as primary'**
  String get setAsPrimary;

  /// No description provided for @removeContact.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeContact;

  /// No description provided for @sosHistory.
  ///
  /// In en, this message translates to:
  /// **'SOS history'**
  String get sosHistory;

  /// No description provided for @alertsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No alerts sent} =1{1 alert sent} other{{count} alerts sent}}'**
  String alertsCount(int count);

  /// No description provided for @noSosTitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts sent'**
  String get noSosTitle;

  /// No description provided for @noSosDescription.
  ///
  /// In en, this message translates to:
  /// **'Alerts you send will be listed here with who was notified.'**
  String get noSosDescription;

  /// No description provided for @alertedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contact notified} other{{count} contacts notified}}'**
  String alertedCount(int count);

  /// No description provided for @sosStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get sosStatusOpen;

  /// No description provided for @sosStatusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get sosStatusAcknowledged;

  /// No description provided for @sosStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get sosStatusResolved;

  /// No description provided for @locationShared.
  ///
  /// In en, this message translates to:
  /// **'Location shared: {location}'**
  String locationShared(String location);

  /// No description provided for @primaryContact.
  ///
  /// In en, this message translates to:
  /// **'Primary contact: {name}'**
  String primaryContact(String name);

  /// No description provided for @unitOrder.
  ///
  /// In en, this message translates to:
  /// **'order'**
  String get unitOrder;

  /// No description provided for @unitOrderCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order} other{{count} orders}}'**
  String unitOrderCount(int count);

  /// No description provided for @standardPartsQuoted.
  ///
  /// In en, this message translates to:
  /// **'Spare parts quoted before fitting'**
  String get standardPartsQuoted;

  /// No description provided for @standardCleanupAfter.
  ///
  /// In en, this message translates to:
  /// **'Work area cleaned before leaving'**
  String get standardCleanupAfter;

  /// No description provided for @standardBackgroundChecked.
  ///
  /// In en, this message translates to:
  /// **'Background-checked caregiver'**
  String get standardBackgroundChecked;

  /// No description provided for @standardPrescriptionChecked.
  ///
  /// In en, this message translates to:
  /// **'Prescription checked by a pharmacist'**
  String get standardPrescriptionChecked;

  /// No description provided for @careServices.
  ///
  /// In en, this message translates to:
  /// **'Care Services'**
  String get careServices;

  /// No description provided for @allServices.
  ///
  /// In en, this message translates to:
  /// **'All services'**
  String get allServices;

  /// No description provided for @homeServicesTagline.
  ///
  /// In en, this message translates to:
  /// **'Plumbers, electricians and cleaners who show up on time and clean up after.'**
  String get homeServicesTagline;

  /// No description provided for @careServicesTagline.
  ///
  /// In en, this message translates to:
  /// **'Trained caregivers and doorstep medicines for the people you look after.'**
  String get careServicesTagline;

  /// No description provided for @allServicesTagline.
  ///
  /// In en, this message translates to:
  /// **'Everything Kaylo offers, across home, farm and care.'**
  String get allServicesTagline;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get locating;

  /// No description provided for @locationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services and try again.'**
  String get locationServicesOff;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was not granted.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for Kaylo. Allow it in your device settings.'**
  String get locationDeniedForever;

  /// No description provided for @locationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Could not get a GPS fix. Move to open sky and try again.'**
  String get locationTimeout;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location is unavailable right now.'**
  String get locationUnavailable;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get noNotificationsTitle;

  /// No description provided for @noNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Booking updates, messages and reminders will show up here.'**
  String get noNotificationsDescription;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Yesterday} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get bookingDetails;

  /// No description provided for @cancelBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get cancelBookingTitle;

  /// No description provided for @cancelBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'The worker will be released. You can book again anytime.'**
  String get cancelBookingMessage;

  /// No description provided for @keepBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get keepBooking;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelled;

  /// No description provided for @bookingCancelledBanner.
  ///
  /// In en, this message translates to:
  /// **'This booking was cancelled.'**
  String get bookingCancelledBanner;

  /// No description provided for @stepRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get stepRequested;

  /// No description provided for @stepConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get stepConfirmed;

  /// No description provided for @stepInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get stepInProgress;

  /// No description provided for @stepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get stepCompleted;

  /// No description provided for @assignedWorker.
  ///
  /// In en, this message translates to:
  /// **'Your worker'**
  String get assignedWorker;

  /// No description provided for @noWorkerYet.
  ///
  /// In en, this message translates to:
  /// **'A worker will be assigned before the visit.'**
  String get noWorkerYet;

  /// No description provided for @messageWorker.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageWorker;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @bookingRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Booking rescheduled'**
  String get bookingRescheduled;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyFilters;

  /// No description provided for @sortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get sortRelevance;

  /// No description provided for @sortPriceLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceLowHigh;

  /// No description provided for @sortPriceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceHighLow;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No services match'**
  String get noResultsTitle;

  /// No description provided for @noResultsDescription.
  ///
  /// In en, this message translates to:
  /// **'Try another word, or describe the problem: \"tap is leaking\" works too.'**
  String get noResultsDescription;

  /// No description provided for @resultsFor.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result for \"{query}\"} other{{count} results for \"{query}\"}}'**
  String resultsFor(int count, String query);

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocation;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @townOrCity.
  ///
  /// In en, this message translates to:
  /// **'Town or city'**
  String get townOrCity;

  /// No description provided for @townHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kannur'**
  String get townHint;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get saveLocation;

  /// No description provided for @townRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a town or city'**
  String get townRequired;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location set to {label}'**
  String locationUpdated(String label);

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get enableLocation;

  /// No description provided for @enableLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Kaylo uses your location to show workers near you and to share it in an SOS alert.'**
  String get enableLocationSubtitle;

  /// No description provided for @locationWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your location will appear here'**
  String get locationWillAppear;

  /// No description provided for @locateAgain.
  ///
  /// In en, this message translates to:
  /// **'Locate again'**
  String get locateAgain;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get enterManually;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @noAddressesTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get noAddressesTitle;

  /// No description provided for @noAddressesDescription.
  ///
  /// In en, this message translates to:
  /// **'Save your home or farm once and pick it in a tap when booking.'**
  String get noAddressesDescription;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @removeAddress.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAddress;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get addressLabel;

  /// No description provided for @labelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get labelHome;

  /// No description provided for @labelFarm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get labelFarm;

  /// No description provided for @labelWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get labelWork;

  /// No description provided for @labelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get labelOther;

  /// No description provided for @labelOtherHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Amma\'s house'**
  String get labelOtherHint;

  /// No description provided for @addressLine.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLine;

  /// No description provided for @addressSaved.
  ///
  /// In en, this message translates to:
  /// **'Address saved'**
  String get addressSaved;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get emailUs;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @reportProblemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong'**
  String get reportProblemSubtitle;

  /// No description provided for @reportProblemTemplate.
  ///
  /// In en, this message translates to:
  /// **'What happened:\nWhere in the app:\nPhone model:'**
  String get reportProblemTemplate;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faq;

  /// No description provided for @faqBookQ.
  ///
  /// In en, this message translates to:
  /// **'How do I book a service?'**
  String get faqBookQ;

  /// No description provided for @faqBookA.
  ///
  /// In en, this message translates to:
  /// **'Pick a service from the home screen or search, choose a date, time slot and quantity, add the address, and confirm. You get a booking ID right away and can track it under Bookings.'**
  String get faqBookA;

  /// No description provided for @faqPayQ.
  ///
  /// In en, this message translates to:
  /// **'How do I pay?'**
  String get faqPayQ;

  /// No description provided for @faqPayA.
  ///
  /// In en, this message translates to:
  /// **'UPI and cards are charged when you confirm. Choose \"Pay after service\" to pay the worker directly once the job is done.'**
  String get faqPayA;

  /// No description provided for @faqCancelQ.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel or reschedule?'**
  String get faqCancelQ;

  /// No description provided for @faqCancelA.
  ///
  /// In en, this message translates to:
  /// **'Yes. Open the booking under Bookings and use Reschedule or Cancel. Both are free until the worker is on the way.'**
  String get faqCancelA;

  /// No description provided for @faqWorkersQ.
  ///
  /// In en, this message translates to:
  /// **'How are workers verified?'**
  String get faqWorkersQ;

  /// No description provided for @faqWorkersA.
  ///
  /// In en, this message translates to:
  /// **'Every worker\'s ID is checked before they are listed, and ratings come only from customers who completed a booking.'**
  String get faqWorkersA;

  /// No description provided for @faqCareQ.
  ///
  /// In en, this message translates to:
  /// **'What is Care Mode?'**
  String get faqCareQ;

  /// No description provided for @faqCareA.
  ///
  /// In en, this message translates to:
  /// **'Care Mode turns the whole app into a large-text, high-contrast layout for seniors, with medicine reminders and one-hold SOS.'**
  String get faqCareA;

  /// No description provided for @faqSosQ.
  ///
  /// In en, this message translates to:
  /// **'How does SOS work?'**
  String get faqSosQ;

  /// No description provided for @faqSosA.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the SOS button for three seconds. Every emergency contact receives your location, and the primary contact is called.'**
  String get faqSosA;

  /// No description provided for @helpFooter.
  ///
  /// In en, this message translates to:
  /// **'Kaylo is built by a small team in Kerala. Every message is read.'**
  String get helpFooter;

  /// No description provided for @couldNotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open your email app.'**
  String get couldNotOpenEmail;

  /// No description provided for @rateTitle.
  ///
  /// In en, this message translates to:
  /// **'How is Kaylo working for you?'**
  String get rateTitle;

  /// No description provided for @rateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your rating tells the team where to focus next.'**
  String get rateSubtitle;

  /// No description provided for @rateComment.
  ///
  /// In en, this message translates to:
  /// **'Anything we should improve? (optional)'**
  String get rateComment;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitRating;

  /// No description provided for @pickAStar.
  ///
  /// In en, this message translates to:
  /// **'Pick a star rating first'**
  String get pickAStar;

  /// No description provided for @youRated.
  ///
  /// In en, this message translates to:
  /// **'You rated Kaylo {stars} of 5'**
  String youRated(int stars);

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get confirmLocation;

  /// No description provided for @moveMapToPlacePin.
  ///
  /// In en, this message translates to:
  /// **'Move the map to place the pin'**
  String get moveMapToPlacePin;

  /// No description provided for @findingAddress.
  ///
  /// In en, this message translates to:
  /// **'Finding address…'**
  String get findingAddress;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get selectedLocation;

  /// No description provided for @mapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map preview unavailable'**
  String get mapUnavailable;

  /// No description provided for @searchTownHint.
  ///
  /// In en, this message translates to:
  /// **'Search a town or city'**
  String get searchTownHint;

  /// No description provided for @workerAbout.
  ///
  /// In en, this message translates to:
  /// **'{name} is a Kaylo professional in {place} with {jobs} completed jobs.'**
  String workerAbout(String name, String place, int jobs);

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification in progress'**
  String get verificationPending;

  /// No description provided for @certGovtId.
  ///
  /// In en, this message translates to:
  /// **'Government ID verified'**
  String get certGovtId;

  /// No description provided for @certGovtIdSub.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar or Voter ID checked'**
  String get certGovtIdSub;

  /// No description provided for @certPolice.
  ///
  /// In en, this message translates to:
  /// **'Police clearance verified'**
  String get certPolice;

  /// No description provided for @certPoliceSub.
  ///
  /// In en, this message translates to:
  /// **'Background check clear'**
  String get certPoliceSub;

  /// No description provided for @certSkill.
  ///
  /// In en, this message translates to:
  /// **'Kaylo skill certified'**
  String get certSkill;

  /// No description provided for @certSkillSub.
  ///
  /// In en, this message translates to:
  /// **'Practical skills tested'**
  String get certSkillSub;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate'**
  String get hourlyRate;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get perHour;

  /// No description provided for @priceOnVisit.
  ///
  /// In en, this message translates to:
  /// **'Price shared on visit'**
  String get priceOnVisit;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @newService.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newService;

  /// No description provided for @nearbyFirst.
  ///
  /// In en, this message translates to:
  /// **'Nearby first'**
  String get nearbyFirst;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String inDays(int count);

  /// No description provided for @whoIsItFor.
  ///
  /// In en, this message translates to:
  /// **'Who is it for?'**
  String get whoIsItFor;

  /// No description provided for @appointmentNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes for the doctor (optional)'**
  String get appointmentNotes;

  /// No description provided for @appointmentConfirmedWith.
  ///
  /// In en, this message translates to:
  /// **'Appointment booked with {doctor}'**
  String appointmentConfirmedWith(String doctor);

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments yet'**
  String get noUpcomingAppointments;

  /// No description provided for @specGeneral.
  ///
  /// In en, this message translates to:
  /// **'General physician'**
  String get specGeneral;

  /// No description provided for @specCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardiologist'**
  String get specCardio;

  /// No description provided for @specOrtho.
  ///
  /// In en, this message translates to:
  /// **'Orthopaedic'**
  String get specOrtho;

  /// No description provided for @specGeriatric.
  ///
  /// In en, this message translates to:
  /// **'Geriatrician'**
  String get specGeriatric;

  /// No description provided for @specAyurveda.
  ///
  /// In en, this message translates to:
  /// **'Ayurveda'**
  String get specAyurveda;

  /// No description provided for @incPlumbTap.
  ///
  /// In en, this message translates to:
  /// **'Tap repair'**
  String get incPlumbTap;

  /// No description provided for @incPlumbPipe.
  ///
  /// In en, this message translates to:
  /// **'Pipe leakage'**
  String get incPlumbPipe;

  /// No description provided for @incPlumbDrain.
  ///
  /// In en, this message translates to:
  /// **'Drain cleaning'**
  String get incPlumbDrain;

  /// No description provided for @incPlumbInstall.
  ///
  /// In en, this message translates to:
  /// **'Installation'**
  String get incPlumbInstall;

  /// No description provided for @incElecSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switchboard repair'**
  String get incElecSwitch;

  /// No description provided for @incElecWiring.
  ///
  /// In en, this message translates to:
  /// **'Wiring fix'**
  String get incElecWiring;

  /// No description provided for @incElecFan.
  ///
  /// In en, this message translates to:
  /// **'Fan installation'**
  String get incElecFan;

  /// No description provided for @incElecMcb.
  ///
  /// In en, this message translates to:
  /// **'MCB tripping'**
  String get incElecMcb;

  /// No description provided for @incCleanDeep.
  ///
  /// In en, this message translates to:
  /// **'Full home deep clean'**
  String get incCleanDeep;

  /// No description provided for @incCleanKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen cleaning'**
  String get incCleanKitchen;

  /// No description provided for @incCleanBath.
  ///
  /// In en, this message translates to:
  /// **'Bathroom scrub'**
  String get incCleanBath;

  /// No description provided for @incCleanSofa.
  ///
  /// In en, this message translates to:
  /// **'Sofa shampoo'**
  String get incCleanSofa;

  /// No description provided for @incCarpFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture repair'**
  String get incCarpFurniture;

  /// No description provided for @incCarpDoor.
  ///
  /// In en, this message translates to:
  /// **'Doors and windows'**
  String get incCarpDoor;

  /// No description provided for @incCarpLock.
  ///
  /// In en, this message translates to:
  /// **'Lock installation'**
  String get incCarpLock;

  /// No description provided for @incCarpCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom woodwork'**
  String get incCarpCustom;

  /// No description provided for @incPaintInterior.
  ///
  /// In en, this message translates to:
  /// **'Interior painting'**
  String get incPaintInterior;

  /// No description provided for @incPaintExterior.
  ///
  /// In en, this message translates to:
  /// **'Exterior painting'**
  String get incPaintExterior;

  /// No description provided for @incPaintPutty.
  ///
  /// In en, this message translates to:
  /// **'Wall putty and primer'**
  String get incPaintPutty;

  /// No description provided for @incPaintWaterproof.
  ///
  /// In en, this message translates to:
  /// **'Waterproofing'**
  String get incPaintWaterproof;

  /// No description provided for @incAcFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter cleaning'**
  String get incAcFilter;

  /// No description provided for @incAcGas.
  ///
  /// In en, this message translates to:
  /// **'Gas refill'**
  String get incAcGas;

  /// No description provided for @incAcCooling.
  ///
  /// In en, this message translates to:
  /// **'Cooling issue repair'**
  String get incAcCooling;

  /// No description provided for @incAcInstall.
  ///
  /// In en, this message translates to:
  /// **'Installation and removal'**
  String get incAcInstall;

  /// No description provided for @incApplWasher.
  ///
  /// In en, this message translates to:
  /// **'Washing machine'**
  String get incApplWasher;

  /// No description provided for @incApplFridge.
  ///
  /// In en, this message translates to:
  /// **'Refrigerator'**
  String get incApplFridge;

  /// No description provided for @incApplMicrowave.
  ///
  /// In en, this message translates to:
  /// **'Microwave'**
  String get incApplMicrowave;

  /// No description provided for @incApplTv.
  ///
  /// In en, this message translates to:
  /// **'TV mounting and repair'**
  String get incApplTv;

  /// No description provided for @incGenInspect.
  ///
  /// In en, this message translates to:
  /// **'General inspection'**
  String get incGenInspect;

  /// No description provided for @incGenRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair and fix'**
  String get incGenRepair;

  /// No description provided for @incGenInstall.
  ///
  /// In en, this message translates to:
  /// **'New installation'**
  String get incGenInstall;

  /// No description provided for @incGenMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get incGenMaintain;

  /// No description provided for @invoiceEmail.
  ///
  /// In en, this message translates to:
  /// **'Email for the invoice'**
  String get invoiceEmail;

  /// No description provided for @invoiceEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address for the invoice'**
  String get invoiceEmailRequired;

  /// No description provided for @confirmationEmail.
  ///
  /// In en, this message translates to:
  /// **'Email for the confirmation (optional)'**
  String get confirmationEmail;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @payNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cards, netbanking or UPI, secured by Razorpay'**
  String get payNowSubtitle;

  /// No description provided for @prescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptions;

  /// No description provided for @prescriptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan, read and keep your health records'**
  String get prescriptionsSubtitle;

  /// No description provided for @trustedContacts.
  ///
  /// In en, this message translates to:
  /// **'Trusted contacts'**
  String get trustedContacts;

  /// No description provided for @trustedContactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect family and doctors for SOS calls'**
  String get trustedContactsSubtitle;

  /// No description provided for @sosStartFailedContacts.
  ///
  /// In en, this message translates to:
  /// **'Could not start SOS. Check your connection and trusted contacts.'**
  String get sosStartFailedContacts;

  /// No description provided for @sosStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start SOS. Please try again.'**
  String get sosStartFailed;

  /// No description provided for @sosModeKaylo.
  ///
  /// In en, this message translates to:
  /// **'Kaylo call'**
  String get sosModeKaylo;

  /// No description provided for @sosModeSim.
  ///
  /// In en, this message translates to:
  /// **'SIM call'**
  String get sosModeSim;

  /// No description provided for @manageTrustedContacts.
  ///
  /// In en, this message translates to:
  /// **'Manage trusted contacts'**
  String get manageTrustedContacts;

  /// No description provided for @sosKayloHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Hold for 3 seconds to invite your trusted Kaylo contacts. They can join the call together. An invitation does not mean someone has answered.'**
  String get sosKayloHoldHint;

  /// No description provided for @contactsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open phone contacts.'**
  String get contactsOpenFailed;

  /// No description provided for @chooseFromPhoneContacts.
  ///
  /// In en, this message translates to:
  /// **'Choose from phone contacts'**
  String get chooseFromPhoneContacts;

  /// No description provided for @sosContactsSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contact was skipped: its number cannot be dialled.} other{{count} contacts were skipped: their numbers cannot be dialled.}}'**
  String sosContactsSkipped(int count);

  /// No description provided for @incomingSosTitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming Kaylo SOS'**
  String get incomingSosTitle;

  /// No description provided for @incomingSosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A trusted contact needs help'**
  String get incomingSosSubtitle;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @joinCall.
  ///
  /// In en, this message translates to:
  /// **'Join call'**
  String get joinCall;

  /// No description provided for @signInLiveForContacts.
  ///
  /// In en, this message translates to:
  /// **'Sign into the live app to connect trusted contacts.'**
  String get signInLiveForContacts;

  /// No description provided for @couldNotConnectRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Please try again.'**
  String get couldNotConnectRetry;

  /// No description provided for @refreshConnections.
  ///
  /// In en, this message translates to:
  /// **'Refresh connections'**
  String get refreshConnections;

  /// No description provided for @trustedCircleTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring your circle into Kaylo'**
  String get trustedCircleTitle;

  /// No description provided for @trustedCircleBody.
  ///
  /// In en, this message translates to:
  /// **'Invite up to five family members or doctors who use Kaylo. When they accept your code, they can receive your SOS alerts and join the same voice call.'**
  String get trustedCircleBody;

  /// No description provided for @getInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Get my invite code'**
  String get getInviteCode;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get inviteCodeCopied;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @inviteCodeValidity.
  ///
  /// In en, this message translates to:
  /// **'Valid for seven days. Share only with people you trust.'**
  String get inviteCodeValidity;

  /// No description provided for @acceptInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept someone’s invitation'**
  String get acceptInviteTitle;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @acceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accept invitation'**
  String get acceptInvitation;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted. You are now connected and can receive their SOS alerts.'**
  String get invitationAccepted;

  /// No description provided for @yourConnections.
  ///
  /// In en, this message translates to:
  /// **'Your connections'**
  String get yourConnections;

  /// No description provided for @noConnectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No connections yet'**
  String get noConnectionsYet;

  /// No description provided for @receivesYourSos.
  ///
  /// In en, this message translates to:
  /// **'Receives your SOS alerts'**
  String get receivesYourSos;

  /// No description provided for @youReceiveTheirSos.
  ///
  /// In en, this message translates to:
  /// **'You receive their SOS alerts'**
  String get youReceiveTheirSos;

  /// No description provided for @removeConnection.
  ///
  /// In en, this message translates to:
  /// **'Remove connection'**
  String get removeConnection;

  /// No description provided for @removeConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove connection?'**
  String get removeConnectionTitle;

  /// No description provided for @removeConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'This connection will no longer receive SOS call invitations.'**
  String get removeConnectionBody;

  /// No description provided for @contactsLoadFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load contacts. Retry'**
  String get contactsLoadFailedRetry;

  /// No description provided for @callTitle.
  ///
  /// In en, this message translates to:
  /// **'Kaylo SOS call'**
  String get callTitle;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callEnded;

  /// No description provided for @callYourCircle.
  ///
  /// In en, this message translates to:
  /// **'Your trusted circle'**
  String get callYourCircle;

  /// No description provided for @callCouldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect'**
  String get callCouldNotConnect;

  /// No description provided for @callConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get callConnecting;

  /// No description provided for @callKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep Kaylo open during the call.'**
  String get callKeepOpen;

  /// No description provided for @retryCall.
  ///
  /// In en, this message translates to:
  /// **'Retry call'**
  String get retryCall;

  /// No description provided for @callErrorRoom.
  ///
  /// In en, this message translates to:
  /// **'This call is unavailable or has ended. Return to SOS to start a new call.'**
  String get callErrorRoom;

  /// No description provided for @callErrorSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not load call settings. Check your connection and retry.'**
  String get callErrorSettings;

  /// No description provided for @callErrorMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Could not access the microphone. Check microphone access for Kaylo and retry.'**
  String get callErrorMicrophone;

  /// No description provided for @callErrorJoin.
  ///
  /// In en, this message translates to:
  /// **'Could not join this call. Retry, or ask the caller to start a new SOS call.'**
  String get callErrorJoin;

  /// No description provided for @callInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Connection interrupted. Retrying…'**
  String get callInterrupted;

  /// No description provided for @callPeerConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get callPeerConnected;

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

  /// No description provided for @callPeerConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get callPeerConnecting;

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

  /// No description provided for @callInvitedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Invited • Waiting to answer'**
  String get callInvitedWaiting;

  /// No description provided for @callDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get callDeclined;

  /// No description provided for @callLeft.
  ///
  /// In en, this message translates to:
  /// **'Left the call'**
  String get callLeft;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @callAudioOutputFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change audio output. The call is still active.'**
  String get callAudioOutputFailed;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @callEndForEveryone.
  ///
  /// In en, this message translates to:
  /// **'End call for everyone'**
  String get callEndForEveryone;

  /// No description provided for @callLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave call'**
  String get callLeave;

  /// No description provided for @prescriptionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load prescriptions. Please try again.'**
  String get prescriptionsLoadFailed;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete that action.'**
  String get actionFailed;

  /// No description provided for @prescriptionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the prescription. Please try again.'**
  String get prescriptionSaveFailed;

  /// No description provided for @prescriptionsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your health records, together'**
  String get prescriptionsHeadline;

  /// No description provided for @prescriptionsIntro.
  ///
  /// In en, this message translates to:
  /// **'Scan a prescription or type a previous record. PDFs are saved privately on this device.'**
  String get prescriptionsIntro;

  /// No description provided for @prescriptionsAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'Prescription scanning and PDFs are currently available in the Android app.'**
  String get prescriptionsAndroidOnly;

  /// No description provided for @scanOrPhotos.
  ///
  /// In en, this message translates to:
  /// **'Scan / photos'**
  String get scanOrPhotos;

  /// No description provided for @typeRecord.
  ///
  /// In en, this message translates to:
  /// **'Type record'**
  String get typeRecord;

  /// No description provided for @searchPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'Search prescriptions'**
  String get searchPrescriptions;

  /// No description provided for @noPrescriptionsYet.
  ///
  /// In en, this message translates to:
  /// **'No prescriptions yet'**
  String get noPrescriptionsYet;

  /// No description provided for @noMatchingPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'No matching prescriptions'**
  String get noMatchingPrescriptions;

  /// No description provided for @prescriptionNeedsTitleText.
  ///
  /// In en, this message translates to:
  /// **'Add a title and prescription text.'**
  String get prescriptionNeedsTitleText;

  /// No description provided for @prescriptionRecord.
  ///
  /// In en, this message translates to:
  /// **'Prescription record'**
  String get prescriptionRecord;

  /// No description provided for @reviewPrescription.
  ///
  /// In en, this message translates to:
  /// **'Review prescription'**
  String get reviewPrescription;

  /// No description provided for @deletePrescription.
  ///
  /// In en, this message translates to:
  /// **'Delete prescription'**
  String get deletePrescription;

  /// No description provided for @deletePrescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete prescription?'**
  String get deletePrescriptionTitle;

  /// No description provided for @deletePrescriptionBody.
  ///
  /// In en, this message translates to:
  /// **'The PDF and text will be removed from this device.'**
  String get deletePrescriptionBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @prescriptionReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Review the extracted text against the original. Handwriting may be incomplete or incorrect; confirm medicine names and doses with your doctor.'**
  String get prescriptionReviewHint;

  /// No description provided for @viewOriginalPdf.
  ///
  /// In en, this message translates to:
  /// **'View original PDF'**
  String get viewOriginalPdf;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @extractedTextNotes.
  ///
  /// In en, this message translates to:
  /// **'Extracted text / notes'**
  String get extractedTextNotes;

  /// No description provided for @prescriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Prescription details'**
  String get prescriptionDetails;

  /// No description provided for @prescriptionEditHint.
  ///
  /// In en, this message translates to:
  /// **'Editing this text keeps the original scanned PDF unchanged.'**
  String get prescriptionEditHint;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @savePrescription.
  ///
  /// In en, this message translates to:
  /// **'Save prescription'**
  String get savePrescription;

  /// No description provided for @openSavedPdf.
  ///
  /// In en, this message translates to:
  /// **'Open saved PDF'**
  String get openSavedPdf;

  /// No description provided for @shareSavedPdf.
  ///
  /// In en, this message translates to:
  /// **'Share saved PDF'**
  String get shareSavedPdf;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteRequiresLive.
  ///
  /// In en, this message translates to:
  /// **'Account deletion requires a signed-in live account.'**
  String get deleteRequiresLive;

  /// No description provided for @deleteNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Deletion was not confirmed. Please retry.'**
  String get deleteNotConfirmed;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account. Please try again.'**
  String get deleteFailed;

  /// No description provided for @deleteAccountHeadline.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your Kaylo account?'**
  String get deleteAccountHeadline;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This removes your sign-in, profile, bookings, messages, care records and prescriptions stored on this device. It cannot be undone. Complete or cancel active bookings first. For unresolved payments, contact kayloapp@gmail.com.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountNote.
  ///
  /// In en, this message translates to:
  /// **'Payment processors may retain transaction records. Documents you previously shared are not removed from other people’s devices.'**
  String get deleteAccountNote;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeleteToConfirm;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get deleting;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @paymentVerified.
  ///
  /// In en, this message translates to:
  /// **'Payment verified. Your booking is confirmed.'**
  String get paymentVerified;

  /// No description provided for @paymentNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment was not completed.'**
  String get paymentNotCompleted;

  /// No description provided for @checkoutOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open secure checkout. Please try again.'**
  String get checkoutOpenFailed;

  /// No description provided for @cardsAndUpi.
  ///
  /// In en, this message translates to:
  /// **'Cards and UPI'**
  String get cardsAndUpi;

  /// No description provided for @paymentMethodsBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a card manually or choose UPI in secure Razorpay checkout. Where supported, choose Razorpay’s save-card option to use that card again. Saved cards are managed inside checkout.'**
  String get paymentMethodsBody;

  /// No description provided for @paymentMethodsNote.
  ///
  /// In en, this message translates to:
  /// **'Kaylo does not store your full card number, CVV or PIN. NFC card enrolment is not supported by the current payment integration.'**
  String get paymentMethodsNote;

  /// No description provided for @completePendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Complete a pending payment'**
  String get completePendingPayment;

  /// No description provided for @noPendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Your next booking will open checkout, where you can add or select a card.'**
  String get noPendingPayments;

  /// No description provided for @pendingBookingLine.
  ///
  /// In en, this message translates to:
  /// **'Booking {id} • {date}'**
  String pendingBookingLine(String id, String date);

  /// No description provided for @bookingsLoadFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookings. Retry'**
  String get bookingsLoadFailedRetry;

  /// No description provided for @openingPayment.
  ///
  /// In en, this message translates to:
  /// **'Opening payment…'**
  String get openingPayment;

  /// No description provided for @payAndBook.
  ///
  /// In en, this message translates to:
  /// **'Pay & book'**
  String get payAndBook;

  /// No description provided for @appointmentPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete payment. Your appointment is not confirmed. Please try again.'**
  String get appointmentPaymentFailed;

  /// No description provided for @visitPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete payment. Your visit is not confirmed. Please try again.'**
  String get visitPaymentFailed;

  /// No description provided for @careServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This care service is unavailable.'**
  String get careServiceUnavailable;

  /// No description provided for @appointmentNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment was not completed. Your appointment is not confirmed.'**
  String get appointmentNotConfirmed;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get hapticFeedback;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffects;

  /// No description provided for @voiceStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting microphone…'**
  String get voiceStarting;

  /// No description provided for @ocrNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Some text could not be read. Check the original scan and correct the notes before using them.'**
  String get ocrNeedsReview;

  /// No description provided for @allBookings.
  ///
  /// In en, this message translates to:
  /// **'All bookings'**
  String get allBookings;

  /// No description provided for @noCompletedBookings.
  ///
  /// In en, this message translates to:
  /// **'No completed bookings yet'**
  String get noCompletedBookings;

  /// No description provided for @noCompletedBookingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your completed jobs will appear here once the work is done.'**
  String get noCompletedBookingsDescription;

  /// No description provided for @verificationRecord.
  ///
  /// In en, this message translates to:
  /// **'Verification record'**
  String get verificationRecord;

  /// No description provided for @refreshVerification.
  ///
  /// In en, this message translates to:
  /// **'Refresh verification status'**
  String get refreshVerification;

  /// No description provided for @verificationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the current verification status. Please try again.'**
  String get verificationLoadError;

  /// No description provided for @kayloVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified on Kaylo'**
  String get kayloVerified;

  /// No description provided for @notYetVerified.
  ///
  /// In en, this message translates to:
  /// **'Not yet verified'**
  String get notYetVerified;

  /// No description provided for @viewVerification.
  ///
  /// In en, this message translates to:
  /// **'View verification record'**
  String get viewVerification;

  /// No description provided for @verificationRecorded.
  ///
  /// In en, this message translates to:
  /// **'This professional’s profile is marked as verified in Kaylo.'**
  String get verificationRecorded;

  /// No description provided for @verificationNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'No verified status is recorded for this profile.'**
  String get verificationNotRecorded;

  /// No description provided for @listedServices.
  ///
  /// In en, this message translates to:
  /// **'Listed services'**
  String get listedServices;

  /// No description provided for @profileReference.
  ///
  /// In en, this message translates to:
  /// **'Profile reference'**
  String get profileReference;

  /// No description provided for @serviceArea.
  ///
  /// In en, this message translates to:
  /// **'Service area'**
  String get serviceArea;

  /// No description provided for @verificationScope.
  ///
  /// In en, this message translates to:
  /// **'This record reflects the profile’s current status. Supporting documents and check details are not available. It is not a government licence or a professional qualification.'**
  String get verificationScope;

  /// No description provided for @selectOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get selectOnMap;

  /// No description provided for @chooseAddress.
  ///
  /// In en, this message translates to:
  /// **'Choose an address'**
  String get chooseAddress;

  /// No description provided for @offerFirst100Title.
  ///
  /// In en, this message translates to:
  /// **'Your first one is special'**
  String get offerFirst100Title;

  /// No description provided for @offerFirst100Body.
  ///
  /// In en, this message translates to:
  /// **'₹100 off your first booking of ₹499 or more.'**
  String get offerFirst100Body;

  /// No description provided for @offerKaylo150Title.
  ///
  /// In en, this message translates to:
  /// **'A little help with bigger jobs'**
  String get offerKaylo150Title;

  /// No description provided for @offerKaylo150Body.
  ///
  /// In en, this message translates to:
  /// **'₹150 off a booking of ₹1,499 or more. Once per account.'**
  String get offerKaylo150Body;

  /// No description provided for @offerWeekend100Title.
  ///
  /// In en, this message translates to:
  /// **'A weekend well spent'**
  String get offerWeekend100Title;

  /// No description provided for @offerWeekend100Body.
  ///
  /// In en, this message translates to:
  /// **'₹100 off ₹999 or more on Saturdays and Sundays. Once per account.'**
  String get offerWeekend100Body;

  /// No description provided for @offerWeekday50Title.
  ///
  /// In en, this message translates to:
  /// **'A midweek lift'**
  String get offerWeekday50Title;

  /// No description provided for @offerWeekday50Body.
  ///
  /// In en, this message translates to:
  /// **'₹50 off ₹599 or more, Monday to Friday. Once per account.'**
  String get offerWeekday50Body;

  /// No description provided for @offerHome80Title.
  ///
  /// In en, this message translates to:
  /// **'Home, sorted'**
  String get offerHome80Title;

  /// No description provided for @offerHome80Body.
  ///
  /// In en, this message translates to:
  /// **'₹80 off a home service of ₹499 or more. Once per account.'**
  String get offerHome80Body;

  /// No description provided for @offerFarm125Title.
  ///
  /// In en, this message translates to:
  /// **'For the land that feeds us'**
  String get offerFarm125Title;

  /// No description provided for @offerFarm125Body.
  ///
  /// In en, this message translates to:
  /// **'₹125 off a farm service of ₹999 or more. Once per account.'**
  String get offerFarm125Body;

  /// No description provided for @offerCare60Title.
  ///
  /// In en, this message translates to:
  /// **'Care, made a little lighter'**
  String get offerCare60Title;

  /// No description provided for @offerCare60Body.
  ///
  /// In en, this message translates to:
  /// **'₹60 off a Care booking of ₹399 or more. Once per account.'**
  String get offerCare60Body;

  /// No description provided for @offerKaylo300Title.
  ///
  /// In en, this message translates to:
  /// **'For the really big days'**
  String get offerKaylo300Title;

  /// No description provided for @offerKaylo300Body.
  ///
  /// In en, this message translates to:
  /// **'₹300 off a booking of ₹2,999 or more. Once per account.'**
  String get offerKaylo300Body;

  /// No description provided for @offerNext75Title.
  ///
  /// In en, this message translates to:
  /// **'Something for next time'**
  String get offerNext75Title;

  /// No description provided for @offerNext75Body.
  ///
  /// In en, this message translates to:
  /// **'₹75 off your next booking of ₹799 or more. Unlocks after a confirmed booking.'**
  String get offerNext75Body;

  /// No description provided for @offerThanks120Title.
  ///
  /// In en, this message translates to:
  /// **'Three bookings in. Thank you.'**
  String get offerThanks120Title;

  /// No description provided for @offerThanks120Body.
  ///
  /// In en, this message translates to:
  /// **'₹120 off a booking of ₹999 or more. Unlocks after three confirmed bookings.'**
  String get offerThanks120Body;

  /// No description provided for @offerReasonFirstOnly.
  ///
  /// In en, this message translates to:
  /// **'For your first booking only'**
  String get offerReasonFirstOnly;

  /// No description provided for @offerReasonUsed.
  ///
  /// In en, this message translates to:
  /// **'Already used'**
  String get offerReasonUsed;

  /// No description provided for @offerReasonRewardUsed.
  ///
  /// In en, this message translates to:
  /// **'Reward used'**
  String get offerReasonRewardUsed;

  /// No description provided for @offerReasonWeekend.
  ///
  /// In en, this message translates to:
  /// **'Available on weekends'**
  String get offerReasonWeekend;

  /// No description provided for @offerReasonWeekday.
  ///
  /// In en, this message translates to:
  /// **'Available Monday to Friday'**
  String get offerReasonWeekday;

  /// No description provided for @offerReasonNeedsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Unlocks after your first confirmed booking'**
  String get offerReasonNeedsConfirmed;

  /// No description provided for @offerReasonNeedsThree.
  ///
  /// In en, this message translates to:
  /// **'Unlocks after three confirmed bookings'**
  String get offerReasonNeedsThree;

  /// No description provided for @offerReasonHomeOnly.
  ///
  /// In en, this message translates to:
  /// **'For home services only'**
  String get offerReasonHomeOnly;

  /// No description provided for @offerReasonFarmOnly.
  ///
  /// In en, this message translates to:
  /// **'For farm services only'**
  String get offerReasonFarmOnly;

  /// No description provided for @offerReasonCareOnly.
  ///
  /// In en, this message translates to:
  /// **'For Care bookings only'**
  String get offerReasonCareOnly;

  /// No description provided for @offerReasonAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add {amount} more to use this offer'**
  String offerReasonAddMore(String amount);

  /// No description provided for @offerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Offer not available'**
  String get offerNotAvailable;

  /// No description provided for @offersTitle.
  ///
  /// In en, this message translates to:
  /// **'A little more Kaylo'**
  String get offersTitle;

  /// No description provided for @offersHeadline.
  ///
  /// In en, this message translates to:
  /// **'Everyday help.\nA little extra happiness.'**
  String get offersHeadline;

  /// No description provided for @offersIntro.
  ///
  /// In en, this message translates to:
  /// **'Thoughtful savings for the jobs that matter. One offer per booking.'**
  String get offersIntro;

  /// No description provided for @offersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your offers couldn’t load. Please try again.'**
  String get offersLoadFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @enterCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon code'**
  String get enterCouponCode;

  /// No description provided for @couponNotFound.
  ///
  /// In en, this message translates to:
  /// **'That code isn’t available'**
  String get couponNotFound;

  /// No description provided for @offersTerms.
  ///
  /// In en, this message translates to:
  /// **'Discounts reduce your booking total. They cannot be exchanged for cash or combined. Cancelled bookings release their offer. Eligibility is checked again at checkout.'**
  String get offersTerms;

  /// No description provided for @offerAmountOff.
  ///
  /// In en, this message translates to:
  /// **'{amount} off'**
  String offerAmountOff(String amount);

  /// No description provided for @applyOffer.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyOffer;

  /// No description provided for @removeOffer.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeOffer;

  /// No description provided for @offerYouSave.
  ///
  /// In en, this message translates to:
  /// **'You save {amount}'**
  String offerYouSave(String amount);

  /// No description provided for @offersAndRewards.
  ///
  /// In en, this message translates to:
  /// **'Offers & rewards'**
  String get offersAndRewards;

  /// No description provided for @offerCodeApplied.
  ///
  /// In en, this message translates to:
  /// **'{code} applied'**
  String offerCodeApplied(String code);

  /// No description provided for @offerStampApplied.
  ///
  /// In en, this message translates to:
  /// **'APPLIED'**
  String get offerStampApplied;

  /// No description provided for @offersReadyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 offer ready to use} other{{count} offers ready to use}}'**
  String offersReadyCount(int count);

  /// No description provided for @yourRewards.
  ///
  /// In en, this message translates to:
  /// **'Your rewards'**
  String get yourRewards;

  /// No description provided for @allOffers.
  ///
  /// In en, this message translates to:
  /// **'All offers'**
  String get allOffers;

  /// No description provided for @offerLabel.
  ///
  /// In en, this message translates to:
  /// **'Offer • {code}'**
  String offerLabel(String code);

  /// No description provided for @scratchCoverTitle.
  ///
  /// In en, this message translates to:
  /// **'A little thank you'**
  String get scratchCoverTitle;

  /// No description provided for @scratchCoverHint.
  ///
  /// In en, this message translates to:
  /// **'Scratch to reveal your reward'**
  String get scratchCoverHint;

  /// No description provided for @revealReward.
  ///
  /// In en, this message translates to:
  /// **'Reveal reward'**
  String get revealReward;

  /// No description provided for @scratchSemantics.
  ///
  /// In en, this message translates to:
  /// **'Scratch reward. Reveal {amount} off a booking.'**
  String scratchSemantics(String amount);

  /// No description provided for @bannerWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'A warm welcome. ₹100 on us.'**
  String get bannerWelcomeTitle;

  /// No description provided for @bannerWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Your first-booking offer is unlocked'**
  String get bannerWelcomeBody;

  /// No description provided for @bannerRewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Good work. A little extra joy.'**
  String get bannerRewardsTitle;

  /// No description provided for @bannerRewardsBody.
  ///
  /// In en, this message translates to:
  /// **'Explore your offers & scratch rewards'**
  String get bannerRewardsBody;

  /// No description provided for @secretTagline.
  ///
  /// In en, this message translates to:
  /// **'A little care goes a long way.'**
  String get secretTagline;

  /// No description provided for @secretSemantics.
  ///
  /// In en, this message translates to:
  /// **'Kaylo. Made with care.'**
  String get secretSemantics;

  /// Button that opens the add-card / add-UPI sheet
  ///
  /// In en, this message translates to:
  /// **'Add payment method'**
  String get addPaymentMethod;

  /// Label of the card expiry field
  ///
  /// In en, this message translates to:
  /// **'Expiry (MM/YY)'**
  String get cardExpiry;

  /// Label of the name-on-card field
  ///
  /// In en, this message translates to:
  /// **'Name on card'**
  String get cardHolderName;

  /// Label of the card number field
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get cardNumber;

  /// Small chip on the payment method used by default
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultTag;

  /// Body of the confirm dialog before removing a saved method
  ///
  /// In en, this message translates to:
  /// **'Remove this payment method? You can add it again any time.'**
  String get deletePaymentMethodConfirm;

  /// Empty state title when nothing is saved
  ///
  /// In en, this message translates to:
  /// **'No saved payment methods'**
  String get noPaymentMethods;

  /// Empty state body when nothing is saved
  ///
  /// In en, this message translates to:
  /// **'Save a UPI ID or card to pay faster next time.'**
  String get noPaymentMethodsSubtitle;

  /// Snackbar after saving a method
  ///
  /// In en, this message translates to:
  /// **'Payment method saved'**
  String get paymentMethodAdded;

  /// Snackbar after removing a method
  ///
  /// In en, this message translates to:
  /// **'Payment method removed'**
  String get paymentMethodRemoved;

  /// Remove action on a saved method, and the confirm dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMethod;

  /// Submit button of the add-method sheet
  ///
  /// In en, this message translates to:
  /// **'Save payment method'**
  String get savePaymentMethod;

  /// Action that makes a saved method the default
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setDefault;

  /// Label of the UPI ID field
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get upiId;

  /// Cash line on confirmation and details while the job is open
  ///
  /// In en, this message translates to:
  /// **'Pay the worker {amount} in cash when the job is done'**
  String payCashAmount(String amount);

  /// Cash line on details once the job is completed
  ///
  /// In en, this message translates to:
  /// **'Paid {amount} in cash'**
  String paidCashAmount(String amount);

  /// Banner on booking details while the worker travels
  ///
  /// In en, this message translates to:
  /// **'Your worker is on the way'**
  String get workerOnTheWay;

  /// Banner on booking details when the worker has arrived
  ///
  /// In en, this message translates to:
  /// **'Your worker has arrived'**
  String get workerArrived;

  /// Title and button of the review card after a completed booking
  ///
  /// In en, this message translates to:
  /// **'Rate your worker'**
  String get rateYourWorker;

  /// Helper line under the review card title
  ///
  /// In en, this message translates to:
  /// **'How did it go? A line or two helps other customers.'**
  String get rateWorkerHint;

  /// Hint of the optional review text field
  ///
  /// In en, this message translates to:
  /// **'Say a little about the work (optional)'**
  String get reviewTextHint;

  /// Submit button of the review sheet
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// Snackbar after a review is saved
  ///
  /// In en, this message translates to:
  /// **'Thanks, your review is in'**
  String get reviewSubmitted;

  /// Title of the review card once a review exists
  ///
  /// In en, this message translates to:
  /// **'Your review'**
  String get yourReview;

  /// Action to change an existing review
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editReview;

  /// Error when submitting without picking stars
  ///
  /// In en, this message translates to:
  /// **'Pick a star rating first'**
  String get ratingRequired;

  /// Accessibility label of each star in the review sheet
  ///
  /// In en, this message translates to:
  /// **'{count} of 5 stars'**
  String starLabel(int count);

  /// Heading for priced add-ons ticked on a service page
  ///
  /// In en, this message translates to:
  /// **'Add-ons'**
  String get addOns;

  /// Line in the worker instructions listing the ticked add-ons
  ///
  /// In en, this message translates to:
  /// **'Add-ons: {list}'**
  String addOnsIncluded(String list);

  /// Suffix on a time slot chip the worker already holds
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get slotBooked;

  /// Error when continuing with a slot the worker already holds
  ///
  /// In en, this message translates to:
  /// **'That time is already booked for this worker. Pick another slot.'**
  String get slotTakenMessage;

  /// No description provided for @partnerAccountNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This is a Kaylo Partner account. Please use the Kaylo Partner app.'**
  String get partnerAccountNotAllowed;

  /// No description provided for @customerProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We could not verify your customer profile. Check your connection and sign in again.'**
  String get customerProfileUnavailable;

  /// Section header on a doctor appointment booking
  ///
  /// In en, this message translates to:
  /// **'Your doctor'**
  String get yourDoctor;

  /// Section header on a caregiver booking
  ///
  /// In en, this message translates to:
  /// **'Your caregiver'**
  String get yourCaregiver;

  /// Doctor booking whose appointment record is not available yet
  ///
  /// In en, this message translates to:
  /// **'Kaylo Care is confirming your doctor. We will let you know as soon as it is done.'**
  String get doctorPending;

  /// Caregiver booking whose record is not available yet
  ///
  /// In en, this message translates to:
  /// **'Kaylo Care is confirming your caregiver. We will let you know as soon as it is done.'**
  String get caregiverPending;

  /// Other Care bookings, such as medicine delivery, which have no provider card
  ///
  /// In en, this message translates to:
  /// **'The Kaylo Care team is handling this request.'**
  String get careRequestHandled;

  /// Label before the patient name on a doctor appointment
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientLabel;

  /// Label before the time slot on a doctor appointment
  ///
  /// In en, this message translates to:
  /// **'Appointment time'**
  String get appointmentTime;

  /// Label before the start time of a caregiver visit
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get startsAt;

  /// Length of a caregiver visit
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hoursCount(int count);

  /// Cancel dialog body for a Care booking, which has no worker to release
  ///
  /// In en, this message translates to:
  /// **'This Care booking will be cancelled. You can book again anytime.'**
  String get cancelCareBookingMessage;

  /// Label for the notes line of a Care booking
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get bookingNotes;
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
