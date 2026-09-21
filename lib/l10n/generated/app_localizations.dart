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

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookNow;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get selectDate;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @selectTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Time slot'**
  String get selectTimeSlot;

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
  /// **'Pay after service'**
  String get payAfter;

  /// No description provided for @payAfterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay the worker once the job is done'**
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
  /// **'Press and hold the button for 3 seconds. Your emergency contacts get your location right away.'**
  String get sosHoldHint;

  /// No description provided for @sosReleasedEarly.
  ///
  /// In en, this message translates to:
  /// **'Keep holding for 3 seconds to send an alert'**
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

  /// No description provided for @homeServices.
  ///
  /// In en, this message translates to:
  /// **'Home Services'**
  String get homeServices;

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

  /// No description provided for @serviceAddress.
  ///
  /// In en, this message translates to:
  /// **'Service address'**
  String get serviceAddress;

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

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

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
