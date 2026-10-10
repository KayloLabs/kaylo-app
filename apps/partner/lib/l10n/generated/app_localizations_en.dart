// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kaylo Partner';

  @override
  String get refreshJobsTooltip => 'Refresh jobs';

  @override
  String get tabJobs => 'Jobs';

  @override
  String get tabEarnings => 'Earnings';

  @override
  String get tabProfile => 'Profile';

  @override
  String get dutyOnline => 'You\'re Online';

  @override
  String get dutyOffline => 'You\'re Offline';

  @override
  String dutyTakingOrders(String district) {
    return 'Taking orders in $district';
  }

  @override
  String get dutyNotReceivingRequests => 'Not receiving requests';

  @override
  String get todaysPay => 'Today\'s Pay';

  @override
  String get jobsToday => 'Jobs Today';

  @override
  String get rating => 'Rating';

  @override
  String get activeJob => 'Active Job';

  @override
  String get offlineTitle => 'You\'re Offline';

  @override
  String get offlineDescription =>
      'Switch your duty status to Online above to receive nearby job requests from customers.';

  @override
  String newRequests(int count) {
    return 'New Requests ($count)';
  }

  @override
  String get searchingForRequests => 'Searching for requests...';

  @override
  String get searchingForRequestsSubtitle =>
      'You will hear a ping when a nearby customer books.';

  @override
  String get payout => 'Payout';

  @override
  String get decline => 'Decline';

  @override
  String get acceptJob => 'Accept Job';

  @override
  String get stageRequested => 'Requested';

  @override
  String get stageAccepted => 'Accepted';

  @override
  String get stageOnTheWay => 'On the way';

  @override
  String get stageArrived => 'Arrived';

  @override
  String get stageInProgress => 'In progress';

  @override
  String get stageCompleted => 'Completed';

  @override
  String get stageCancelled => 'Cancelled';

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionStartTravel => 'Start travel';

  @override
  String get actionArrived => 'I have arrived';

  @override
  String get actionStartJob => 'Start job';

  @override
  String get actionCompleteJob => 'Complete job';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get profileLanguageTile => 'Language';

  @override
  String get appSettingsHeader => 'App Settings';

  @override
  String get profileTitle => 'Partner profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get verifiedPartner => 'Verified partner';

  @override
  String get verificationUnderReview => 'Verification in progress';

  @override
  String get verificationRejected => 'Verification rejected';

  @override
  String get verificationNotStarted => 'Not verified yet';

  @override
  String get performanceHeader => 'Performance & ratings';

  @override
  String get totalJobs => 'Total jobs';

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String memberSince(String date) {
    return 'Since $date';
  }

  @override
  String get offeredServicesHeader => 'Services you offer';

  @override
  String get noServicesYet => 'No services listed yet';

  @override
  String get payoutHeader => 'Payout account';

  @override
  String upiLabel(String upi) {
    return 'UPI ID: $upi';
  }

  @override
  String get noPayoutYet => 'No payout account yet';

  @override
  String get bankChangeNote => 'Bank account changes go through support';

  @override
  String get verificationHeader => 'KYC & verification';

  @override
  String get documentAadhaar => 'Aadhaar card';

  @override
  String get documentPoliceCertificate => 'Police clearance certificate';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusNotSubmitted => 'Not submitted';

  @override
  String get areaScheduleHeader => 'Service area & schedule';

  @override
  String travelRadius(String km) {
    return '$km km radius';
  }

  @override
  String get noDistrictYet => 'Service area not set';

  @override
  String get hoursNotSet => 'Working hours not set';

  @override
  String get customHours => 'Different hours on different days';

  @override
  String get manageAvailability => 'Manage availability';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutTitle => 'Log out?';

  @override
  String get logOutBody =>
      'You will need to sign in again with your phone number to receive jobs.';

  @override
  String get cancel => 'Cancel';

  @override
  String get notRegisteredTitle => 'Finish your registration';

  @override
  String get notRegisteredBody =>
      'Your worker profile is not set up yet. Complete registration to start receiving jobs.';

  @override
  String get profileLoadFailed => 'Could not load your profile';

  @override
  String get retry => 'Retry';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get districtLabel => 'District';

  @override
  String get travelRadiusLabel => 'Travel radius (km)';

  @override
  String get upiIdLabel => 'UPI ID';

  @override
  String get servicesLabel => 'Services you offer';

  @override
  String get save => 'Save';

  @override
  String get profileSaved => 'Profile updated';

  @override
  String get nameRequired => 'Enter your name';

  @override
  String get chooseOneService => 'Choose at least one service';

  @override
  String get invalidUpi => 'Enter a valid UPI ID, like name@bank';

  @override
  String get radiusRange => 'Enter a radius between 1 and 100 km';

  @override
  String get dutyUpdateFailed => 'Could not update your availability';

  @override
  String get dutyTakingOrdersAnywhere => 'Taking job requests';

  @override
  String get availabilityTitle => 'My availability';

  @override
  String get workingHoursHeader => 'Working hours';

  @override
  String get workingHoursHint =>
      'Customers can only book you inside these hours.';

  @override
  String get dayOff => 'Day off';

  @override
  String get saveHours => 'Save hours';

  @override
  String get hoursSaved => 'Working hours saved';

  @override
  String get endAfterStart => 'The end time must be after the start';

  @override
  String get daysOffHeader => 'Days off';

  @override
  String get daysOffHint => 'Customers cannot book these days.';

  @override
  String get addDaysOff => 'Add days off';

  @override
  String get noDaysOff => 'No days off planned';

  @override
  String get reasonLabel => 'Reason (optional)';

  @override
  String get reasonHint => 'Festival, travel, family…';

  @override
  String get timeOffAdded => 'Days off added';

  @override
  String get timeOffRemoved => 'Days off removed';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String dateRange(String from, String to) {
    return '$from to $to';
  }
}
