// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'கெய்லோ பார்ட்னர்';

  @override
  String get refreshJobsTooltip => 'வேலைகளைப் புதுப்பிக்கவும்';

  @override
  String get tabJobs => 'வேலைகள்';

  @override
  String get tabEarnings => 'வருமானம்';

  @override
  String get tabProfile => 'சுயவிவரம்';

  @override
  String get dutyOnline => 'நீங்கள் ஆன்லைனில் உள்ளீர்கள்';

  @override
  String get dutyOffline => 'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள்';

  @override
  String dutyTakingOrders(String district) {
    return '$district இல் ஆர்டர்களை எடுக்கிறீர்கள்';
  }

  @override
  String get dutyNotReceivingRequests => 'கோரிக்கைகளைப் பெறவில்லை';

  @override
  String get todaysPay => 'இன்றைய வருமானம்';

  @override
  String get jobsToday => 'இன்றைய வேலைகள்';

  @override
  String get rating => 'மதிப்பீடு';

  @override
  String get activeJob => 'செயலில் உள்ள வேலை';

  @override
  String get offlineTitle => 'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள்';

  @override
  String get offlineDescription =>
      'அருகிலுள்ள வாடிக்கையாளர்களிடமிருந்து வேலை கோரிக்கைகளைப் பெற உங்கள் கடமை நிலையை ஆன்லைனுக்கு மாற்றவும்.';

  @override
  String newRequests(int count) {
    return 'புதிய கோரிக்கைகள் ($count)';
  }

  @override
  String get searchingForRequests => 'கோரிக்கைகளைத் தேடுகிறது...';

  @override
  String get searchingForRequestsSubtitle =>
      'அருகிலுள்ள வாடிக்கையாளர் முன்பதிவு செய்யும்போது ஒரு பிங் சத்தம் கேட்கும்.';

  @override
  String get payout => 'பேஅவுட்';

  @override
  String get decline => 'நிராகரி';

  @override
  String get acceptJob => 'வேலையை ஏற்றுக்கொள்';

  @override
  String get stageRequested => 'கோரப்பட்டது';

  @override
  String get stageAccepted => 'ஏற்றுக்கொள்ளப்பட்டது';

  @override
  String get stageOnTheWay => 'வழியில்';

  @override
  String get stageArrived => 'வந்துவிட்டது';

  @override
  String get stageInProgress => 'செயல்பாட்டில்';

  @override
  String get stageCompleted => 'முடிந்தது';

  @override
  String get stageCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get actionAccept => 'ஏற்றுக்கொள்';

  @override
  String get actionStartTravel => 'பயணத்தைத் தொடங்கு';

  @override
  String get actionArrived => 'நான் வந்துவிட்டேன்';

  @override
  String get actionStartJob => 'வேலையைத் தொடங்கு';

  @override
  String get actionCompleteJob => 'வேலையை முடி';

  @override
  String get languageSettings => 'மொழி அமைப்புகள்';

  @override
  String get profileLanguageTile => 'மொழி';

  @override
  String get appSettingsHeader => 'பயன்பாட்டு அமைப்புகள்';

  @override
  String get profileTitle => 'பார்ட்னர் சுயவிவரம்';

  @override
  String get editProfile => 'சுயவிவரத்தை மாற்று';

  @override
  String get verifiedPartner => 'சரிபார்க்கப்பட்ட பார்ட்னர்';

  @override
  String get verificationUnderReview => 'சரிபார்ப்பு நடைபெறுகிறது';

  @override
  String get verificationRejected => 'சரிபார்ப்பு நிராகரிக்கப்பட்டது';

  @override
  String get verificationNotStarted => 'இன்னும் சரிபார்க்கப்படவில்லை';

  @override
  String get performanceHeader => 'செயல்திறனும் மதிப்பீடும்';

  @override
  String get totalJobs => 'மொத்த வேலைகள்';

  @override
  String reviewsCount(int count) {
    return '$count மதிப்புரைகள்';
  }

  @override
  String memberSince(String date) {
    return '$date முதல்';
  }

  @override
  String get offeredServicesHeader => 'நீங்கள் வழங்கும் சேவைகள்';

  @override
  String get noServicesYet => 'இன்னும் சேவைகள் சேர்க்கப்படவில்லை';

  @override
  String get payoutHeader => 'பணம் பெறும் கணக்கு';

  @override
  String upiLabel(String upi) {
    return 'UPI ID: $upi';
  }

  @override
  String get noPayoutYet => 'இன்னும் கணக்கு சேர்க்கப்படவில்லை';

  @override
  String get bankChangeNote =>
      'வங்கிக் கணக்கு மாற்றங்கள் ஆதரவுக் குழு வழியாக நடக்கும்';

  @override
  String get verificationHeader => 'KYC மற்றும் சரிபார்ப்பு';

  @override
  String get documentAadhaar => 'ஆதார் அட்டை';

  @override
  String get documentPoliceCertificate => 'காவல்துறை அனுமதிச் சான்றிதழ்';

  @override
  String get statusVerified => 'சரிபார்க்கப்பட்டது';

  @override
  String get statusPending => 'நிலுவையில்';

  @override
  String get statusRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get statusNotSubmitted => 'சமர்ப்பிக்கப்படவில்லை';

  @override
  String get areaScheduleHeader => 'சேவைப் பகுதியும் நேரமும்';

  @override
  String travelRadius(String km) {
    return '$km கி.மீ. சுற்றளவில்';
  }

  @override
  String get noDistrictYet => 'சேவைப் பகுதி அமைக்கப்படவில்லை';

  @override
  String get hoursNotSet => 'வேலை நேரம் அமைக்கப்படவில்லை';

  @override
  String get customHours => 'நாளுக்கு நாள் வெவ்வேறு நேரம்';

  @override
  String get manageAvailability => 'கிடைக்கும் நேரத்தை மாற்று';

  @override
  String get logOut => 'வெளியேறு';

  @override
  String get logOutTitle => 'வெளியேறவா?';

  @override
  String get logOutBody =>
      'வேலைகளைப் பெற உங்கள் தொலைபேசி எண்ணுடன் மீண்டும் உள்நுழைய வேண்டும்.';

  @override
  String get cancel => 'ரத்து';

  @override
  String get notRegisteredTitle => 'பதிவை முடிக்கவும்';

  @override
  String get notRegisteredBody =>
      'உங்கள் பணியாளர் சுயவிவரம் இன்னும் தயாராகவில்லை. வேலைகளைப் பெற பதிவை முடிக்கவும்.';

  @override
  String get profileLoadFailed => 'சுயவிவரத்தை ஏற்ற முடியவில்லை';

  @override
  String get retry => 'மீண்டும் முயற்சி';

  @override
  String get editProfileTitle => 'சுயவிவரத்தை மாற்று';

  @override
  String get fullNameLabel => 'முழுப் பெயர்';

  @override
  String get districtLabel => 'மாவட்டம்';

  @override
  String get travelRadiusLabel => 'பயண சுற்றளவு (கி.மீ.)';

  @override
  String get upiIdLabel => 'UPI ID';

  @override
  String get servicesLabel => 'நீங்கள் வழங்கும் சேவைகள்';

  @override
  String get save => 'சேமி';

  @override
  String get profileSaved => 'சுயவிவரம் புதுப்பிக்கப்பட்டது';

  @override
  String get nameRequired => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get chooseOneService => 'குறைந்தது ஒரு சேவையைத் தேர்வு செய்யவும்';

  @override
  String get invalidUpi => 'சரியான UPI ID-ஐ உள்ளிடவும், எ.கா. name@bank';

  @override
  String get radiusRange => '1 முதல் 100 கி.மீ. வரை சுற்றளவை உள்ளிடவும்';

  @override
  String get dutyUpdateFailed => 'கிடைக்கும் நிலையைப் புதுப்பிக்க முடியவில்லை';

  @override
  String get dutyTakingOrdersAnywhere => 'வேலை கோரிக்கைகளை ஏற்கிறது';

  @override
  String get availabilityTitle => 'நான் கிடைக்கும் நேரம்';

  @override
  String get workingHoursHeader => 'வேலை நேரம்';

  @override
  String get workingHoursHint =>
      'வாடிக்கையாளர்கள் இந்த நேரத்திற்குள் மட்டுமே உங்களை முன்பதிவு செய்ய முடியும்.';

  @override
  String get dayOff => 'விடுமுறை';

  @override
  String get saveHours => 'நேரத்தைச் சேமி';

  @override
  String get hoursSaved => 'வேலை நேரம் சேமிக்கப்பட்டது';

  @override
  String get endAfterStart =>
      'முடிவு நேரம் தொடக்கத்திற்குப் பிறகு இருக்க வேண்டும்';

  @override
  String get daysOffHeader => 'விடுமுறை நாட்கள்';

  @override
  String get daysOffHint =>
      'இந்த நாட்களில் வாடிக்கையாளர்கள் முன்பதிவு செய்ய முடியாது.';

  @override
  String get addDaysOff => 'விடுமுறை சேர்';

  @override
  String get noDaysOff => 'விடுமுறை எதுவும் திட்டமிடப்படவில்லை';

  @override
  String get reasonLabel => 'காரணம் (விருப்பத்திற்குரியது)';

  @override
  String get reasonHint => 'திருவிழா, பயணம், குடும்பம்…';

  @override
  String get timeOffAdded => 'விடுமுறை சேர்க்கப்பட்டது';

  @override
  String get timeOffRemoved => 'விடுமுறை நீக்கப்பட்டது';

  @override
  String get remove => 'நீக்கு';

  @override
  String get add => 'சேர்';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாட்கள்',
      one: '1 நாள்',
    );
    return '$_temp0';
  }

  @override
  String dateRange(String from, String to) {
    return '$from முதல் $to வரை';
  }
}
