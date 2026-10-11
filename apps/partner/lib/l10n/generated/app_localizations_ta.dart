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
      'மீண்டும் உள்நுழைய பார்ட்னர் ஐடியும் கடவுச்சொல்லும் தேவை.';

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

  @override
  String get authSubtitle => 'Kaylo வழங்கிய பார்ட்னர் ஐடியுடன் உள்நுழையவும்.';

  @override
  String get authSignIn => 'உள்நுழைக';

  @override
  String get authPartnerId => 'பார்ட்னர் ஐடி';

  @override
  String get authPassword => 'கடவுச்சொல்';

  @override
  String get authShowPassword => 'கடவுச்சொல்லைக் காட்டு';

  @override
  String get authHidePassword => 'கடவுச்சொல்லை மறை';

  @override
  String get authForgotPassword =>
      'கடவுச்சொல் மறந்துவிட்டதா? Kaylo-வைத் தொடர்புகொள்ளுங்கள்';

  @override
  String get authSupport => 'Kaylo உதவியைத் தொடர்புகொள்ளுங்கள்';

  @override
  String get authApply => 'பார்ட்னராக விண்ணப்பிக்கவும்';

  @override
  String get authCheckStatus => 'விண்ணப்ப நிலையைச் சரிபார்க்கவும்';

  @override
  String get authDemoCredentials => 'மாதிரி: KP-000123 / kaylo123';

  @override
  String get authInvalidId =>
      'KP-000123 போன்ற செல்லுபடியான பார்ட்னர் ஐடியை உள்ளிடவும்.';

  @override
  String get authInvalidCredentials =>
      'பார்ட்னர் ஐடி அல்லது கடவுச்சொல் தவறானது.';

  @override
  String get authTooManyAttempts =>
      'அதிக முயற்சிகள். சிறிது நேரம் கழித்து மீண்டும் முயலவும்.';

  @override
  String get authNetworkError =>
      'இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get authUnavailableTitle => 'கணக்கைச் சரிபார்க்க முடியவில்லை';

  @override
  String get authUnavailable =>
      'உங்கள் பார்ட்னர் அணுகலைச் சரிபார்க்க முடியவில்லை. மீண்டும் முயலவும் அல்லது Kaylo உதவியைத் தொடர்புகொள்ளவும்.';

  @override
  String get authPasswordRule =>
      'புதிய கடவுச்சொல்லில் குறைந்தது 12 எழுத்துகளைப் பயன்படுத்தவும்.';

  @override
  String get authDifferentPassword =>
      'தற்காலிக கடவுச்சொல்லிலிருந்து வேறுபட்ட ஒன்றைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get authSessionExpired =>
      'அமர்வு காலாவதியானது. வெளியேறி மீண்டும் உள்நுழையவும்.';

  @override
  String get authPasswordConfirmation =>
      'கடவுச்சொல் மாற்றத்தை உறுதிசெய்ய வேண்டும். மீண்டும் முயல கடவுச்சொல்லைச் சேமி என்பதை அழுத்தவும்.';

  @override
  String get authIdentityNotAllowed =>
      'Kaylo வழங்கிய பார்ட்னர் ஐடியையும் கடவுச்சொல்லையும் பயன்படுத்தவும். வாடிக்கையாளர் கணக்குகளால் இங்கு உள்நுழைய முடியாது.';

  @override
  String get authChangePassword => 'உங்கள் கடவுச்சொல்லை அமைக்கவும்';

  @override
  String get authChangePasswordBody =>
      'பார்ட்னர் கணக்கைத் திறப்பதற்கு முன் தற்காலிக கடவுச்சொல்லை மாற்றவும்.';

  @override
  String get authNewPassword => 'புதிய கடவுச்சொல்';

  @override
  String get authConfirmPassword => 'புதிய கடவுச்சொல்லை உறுதிசெய்யவும்';

  @override
  String get authSavePassword => 'கடவுச்சொல்லைச் சேமி';

  @override
  String get authPasswordMismatch => 'கடவுச்சொற்கள் பொருந்தவில்லை.';

  @override
  String get authNotIssuedBody =>
      'இந்தக் கணக்கிற்கு பணியாளர் சுயவிவரம் வழங்கப்படவில்லை. Kaylo-வில் விண்ணப்பிக்கவும் அல்லது உங்கள் விண்ணப்பம் குறித்து உதவியைத் தொடர்புகொள்ளவும்.';

  @override
  String get authVerificationBody =>
      'Kaylo உங்கள் சரிபார்ப்பை அங்கீகரித்த பிறகு வேலைகள் கிடைக்கும். சுயவிவரத்தைப் பார்க்கலாம் அல்லது உதவியைத் தொடர்புகொள்ளலாம்.';

  @override
  String get partnerJobNotifications => 'வேலை கோரிக்கைகள்';

  @override
  String get partnerNewJobRequest => 'புதிய வேலை கோரிக்கை';

  @override
  String get partnerOpenJobRequest =>
      'கோரிக்கையைப் பார்க்க Kaylo Partner-ஐத் திறக்கவும்.';

  @override
  String get applicationTitle => 'Kaylo-விற்கு விண்ணப்பிக்கவும்';

  @override
  String get applicationPersonal => 'உங்களைப் பற்றி';

  @override
  String get applicationSkills => 'உங்கள் பணி மற்றும் சேவைப் பகுதி';

  @override
  String get applicationDocuments => 'உங்கள் ஆவணங்கள்';

  @override
  String get applicationPayout => 'பணம் பெறுதல் மற்றும் ஒப்புதல்';

  @override
  String applicationStep(int current, int total) {
    return 'படி $current / $total';
  }

  @override
  String get applicationIntro =>
      'கணக்கு இல்லாமல் விண்ணப்பிக்கலாம். கூட்டாளர் உள்நுழைவை வழங்கும் முன் Kaylo உங்கள் விவரங்களையும் ஆவணங்களையும் மதிப்பாய்வு செய்யும்.';

  @override
  String get applicationPhone => 'தொலைபேசி எண்';

  @override
  String get applicationEmail => 'தகவல் பெறும் மின்னஞ்சல்';

  @override
  String get applicationEmailHint =>
      'நீங்கள் அணுகக்கூடிய மின்னஞ்சலை வழங்கவும். ஒப்புதலுக்குப் பிறகு கூட்டாளர் ID மற்றும் தற்காலிக கடவுச்சொல்லை Kaylo இங்கு அனுப்பும்.';

  @override
  String get applicationInvalidPhone =>
      'நாட்டுக் குறியீட்டுடன் சரியான தொலைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get applicationInvalidEmail => 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get applicationProfession => 'தொழில்';

  @override
  String get applicationProfessionRequired => 'உங்கள் தொழிலை உள்ளிடவும்';

  @override
  String get applicationExperience => 'அனுபவம் (ஆண்டுகள்)';

  @override
  String get applicationInvalidExperience =>
      '0 முதல் 60 ஆண்டுகள் வரை அனுபவத்தை உள்ளிடவும்';

  @override
  String get applicationChooseDistrict =>
      'உங்கள் மாவட்டத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get applicationNoServices =>
      'சேவைப் பட்டியல் இன்னும் கிடைக்கவில்லை. பின்னர் மீண்டும் முயற்சிக்கவும்.';

  @override
  String get applicationDocumentsHint =>
      'ஐந்து ஆவணங்களையும் சேர்க்கவும். புகைப்படங்களுக்கு JPG அல்லது PNG; மற்ற ஆவணங்களுக்கு JPG, PNG அல்லது PDF. ஒவ்வொரு கோப்பும் அதிகபட்சம் 10 MB.';

  @override
  String get applicationDocumentsPrivacy =>
      'Kaylo விண்ணப்ப மதிப்பாய்விற்காக ஆவணங்கள் தனிப்பட்ட முறையில் பதிவேற்றப்படும். பொது நிலை தேடலில் அவை காட்டப்படாது.';

  @override
  String get applicationPhoto => 'சுயவிவரப் புகைப்படம்';

  @override
  String get applicationAadhaarFront => 'ஆதார் முன்பக்கம்';

  @override
  String get applicationAadhaarBack => 'ஆதார் பின்பக்கம்';

  @override
  String get applicationSelfie => 'செல்ஃபி';

  @override
  String get applicationChooseFile => 'கோப்பைத் தேர்ந்தெடுக்கவும்';

  @override
  String get applicationAllDocuments => 'தொடர ஐந்து ஆவணங்களையும் சேர்க்கவும்';

  @override
  String get applicationUpi => 'UPI';

  @override
  String get applicationBank => 'வங்கிக் கணக்கு';

  @override
  String get applicationAccountHolder => 'கணக்கு வைத்திருப்பவர் பெயர்';

  @override
  String get applicationBankName => 'வங்கியின் பெயர்';

  @override
  String get applicationAccountNumber => 'கணக்கு எண்';

  @override
  String get applicationConfirmAccount => 'கணக்கு எண்ணை உறுதிப்படுத்தவும்';

  @override
  String get applicationIfsc => 'IFSC குறியீடு';

  @override
  String get applicationBankRequired => 'வங்கி விவரங்களை உள்ளிடவும்';

  @override
  String get applicationInvalidAccount =>
      '9 முதல் 18 இலக்க கணக்கு எண்ணை உள்ளிடவும்';

  @override
  String get applicationAccountMismatch => 'கணக்கு எண்கள் பொருந்தவில்லை';

  @override
  String get applicationInvalidIfsc =>
      'சரியான 11 எழுத்து IFSC குறியீட்டை உள்ளிடவும்';

  @override
  String get applicationReviewHint =>
      'அனுப்பும் முன் உங்கள் விவரங்களைச் சரிபார்க்கவும்.';

  @override
  String get applicationConsent =>
      'இந்த விவரங்கள் என்னுடையவை மற்றும் சரியானவை என உறுதிப்படுத்துகிறேன். கூட்டாளர் சரிபார்ப்பிற்காக எனது விவரங்களையும் ஆவணங்களையும் Kaylo சேமித்து மதிப்பாய்வு செய்ய ஒப்புக்கொள்கிறேன்.';

  @override
  String get applicationConsentRequired =>
      'சமர்ப்பிக்கும் முன் ஒப்புதல் வழங்கவும்';

  @override
  String get applicationKeepOpen =>
      'அனைத்து ஆவணங்களும் பதிவேற்றப்படும் வரை Kaylo-வைத் திறந்து வைத்திருக்கவும். இணைப்பு துண்டிக்கப்பட்டால் புதிய விண்ணப்பம் உருவாக்காமல் இங்கே மீண்டும் முயற்சிக்கவும்.';

  @override
  String get applicationBack => 'பின்னால்';

  @override
  String get applicationContinue => 'தொடரவும்';

  @override
  String get applicationSubmit => 'விண்ணப்பத்தைச் சமர்ப்பிக்கவும்';

  @override
  String get applicationSending => 'விண்ணப்பத்தை அனுப்பி முடிக்கவும்';

  @override
  String get applicationRecoveryHint =>
      'ஐந்து ஆவணங்களும் கிடைத்த பிறகே விண்ணப்பம் மதிப்பாய்விற்குத் தயாராகும். மீண்டும் முயற்சிப்பது அதே விண்ணப்பத்தைத் தொடரும். முடியும் முன் செயலியை மூடினால் குறிப்பெண்ணுடன் Kaylo-வைத் தொடர்புகொள்ளவும்.';

  @override
  String get applicationReference => 'விண்ணப்பக் குறிப்பெண்';

  @override
  String applicationUploadProgress(int count, int total) {
    return '$total ஆவணங்களில் $count பெறப்பட்டன';
  }

  @override
  String get applicationCheckStatus => 'விண்ணப்ப நிலையைப் பார்க்கவும்';

  @override
  String get applicationBackToSignIn => 'உள்நுழைவுக்குத் திரும்பவும்';

  @override
  String get applicationStatusHint =>
      'நிலையைப் பார்க்க உங்கள் விண்ணப்பக் குறிப்பெண்ணை உள்ளிடவும். தனிப்பட்ட விவரங்களும் ஆவணங்களும் இங்கு காட்டப்படாது.';

  @override
  String get applicationInvalidReference =>
      'உங்கள் விண்ணப்பத்தின் குறிப்பெண்ணை உள்ளிடவும்';

  @override
  String get applicationUnderReview => 'விண்ணப்பம் மதிப்பாய்வில் உள்ளது';

  @override
  String get applicationUnderReviewHint =>
      'உங்கள் விவரங்களும் ஐந்து ஆவணங்களும் பெறப்பட்டன. முடிவெடுக்கும் முன் Kaylo அவற்றை மதிப்பாய்வு செய்யும். இந்தக் குறிப்பெண் கூட்டாளர் உள்நுழைவு அல்ல.';

  @override
  String get applicationIncomplete => 'ஆவணங்கள் இன்னும் தேவை';

  @override
  String get applicationIncompleteHint =>
      'உங்கள் விவரங்கள் பெறப்பட்டன, ஆனால் ஆவணப் பதிவேற்றம் முடியவில்லை. இந்தச் செயலி அமர்விலிருந்து தொடரவும் அல்லது குறிப்பெண்ணுடன் Kaylo உதவியை நாடவும்.';

  @override
  String get applicationApproved => 'விண்ணப்பம் ஏற்கப்பட்டது';

  @override
  String get applicationApprovedHint =>
      'ஒப்புதலுக்குப் பிறகு கூட்டாளர் ID மற்றும் தற்காலிக கடவுச்சொல்லை Kaylo மின்னஞ்சலில் அனுப்பும். கிடைக்கவில்லை என்றால் ஆதரவைத் தொடர்புகொள்ளவும். முதல் உள்நுழைவில் புதிய கடவுச்சொல் அமைக்க வேண்டும்.';

  @override
  String get applicationRejected => 'விண்ணப்பம் ஏற்கப்படவில்லை';

  @override
  String get applicationRejectedHint =>
      'இந்த விண்ணப்பத்தை Kaylo ஏற்கவில்லை. இதற்குக் கூட்டாளர் உள்நுழைவு கிடையாது. மேலும் உதவிக்கு குறிப்பெண்ணுடன் ஆதரவைத் தொடர்புகொள்ளவும்.';

  @override
  String get applicationCopyReference => 'குறிப்பெண்ணை நகலெடுக்கவும்';

  @override
  String get applicationReferenceCopied => 'குறிப்பெண் நகலெடுக்கப்பட்டது';

  @override
  String get applicationResumeUpload => 'ஆவணப் பதிவேற்றத்தைத் தொடரவும்';

  @override
  String get applicationContactSupport => 'Kaylo ஆதரவைத் தொடர்புகொள்ளவும்';

  @override
  String applicationSupportSubject(String reference) {
    return 'கூட்டாளர் விண்ணப்ப உதவி: $reference';
  }

  @override
  String get applicationSupportHint =>
      'உங்கள் விண்ணப்பக் குறிப்பெண்ணுடன் kayloapp@gmail.com-க்கு மின்னஞ்சல் அனுப்பவும்.';

  @override
  String get applicationDemoNotice =>
      'மாதிரி முறை: இந்த விண்ணப்பம் இந்தச் செயலி அமர்வில் மட்டுமே இருக்கும்; Kaylo-விற்கு அனுப்பப்படாது.';

  @override
  String get applicationConnectionError =>
      'இணைக்க முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get applicationAlreadyOpen =>
      'இந்தத் தொலைபேசி எண்ணிற்கு ஏற்கனவே விண்ணப்பம் உள்ளது. அதன் நிலையைப் பார்க்கவும் அல்லது Kaylo ஆதரவைத் தொடர்புகொள்ளவும்.';

  @override
  String get applicationInvalidDetails =>
      'உங்கள் விண்ணப்ப விவரங்களைச் சரிபார்க்கவும்.';

  @override
  String get applicationInvalidDocument =>
      '10 MB வரையிலான சரியான JPG, PNG அல்லது PDF கோப்பைத் தேர்ந்தெடுக்கவும். சுயவிவரப் புகைப்படமும் செல்ஃபியும் படங்களாக இருக்க வேண்டும்.';

  @override
  String get applicationUploadExpired =>
      'பதிவேற்ற அமர்வு இனி கிடைக்கவில்லை. விண்ணப்பத்தை முடிக்க குறிப்பெண்ணுடன் Kaylo-வைத் தொடர்புகொள்ளவும்.';

  @override
  String get applicationNotFound =>
      'இந்தக் குறிப்பெண்ணிற்கு விண்ணப்பம் இல்லை. குறிப்பெண்ணைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get applicationUnavailable =>
      'விண்ணப்ப சேவை தற்போது கிடைக்கவில்லை. பின்னர் முயற்சிக்கவும் அல்லது Kaylo ஆதரவைத் தொடர்புகொள்ளவும்.';

  @override
  String get applicationIdentityInUse =>
      'இந்தத் தொலைபேசி அல்லது மின்னஞ்சல் ஏற்கனவே Kaylo கணக்கில் பயன்படுத்தப்படுகிறது. இந்த விவரங்களுடன் விண்ணப்பிக்கும் முன் ஆதரவைத் தொடர்புகொள்ளவும்.';

  @override
  String get liveJobsPending =>
      'நேரடி வேலைக் கோரிக்கைகளும் வருமானமும் இன்னும் கிடைக்கவில்லை. உங்கள் சுயவிவரத்தையும் கிடைக்கும் நேரங்களையும் பயன்படுத்தலாம்.';

  @override
  String get applicationChangesRequested => 'மாற்றங்கள் கோரப்பட்டுள்ளன';

  @override
  String get applicationChangesRequestedHint =>
      'உங்கள் விண்ணப்பத்தை மீண்டும் மதிப்பாய்வு செய்ய Kaylo-க்கு புதுப்பிக்கப்பட்ட ஆவணங்கள் தேவை. வழிமுறைகளைப் பார்க்கவும் மாற்று ஆவணங்களைச் சமர்ப்பிக்கவும் உங்கள் மின்னஞ்சலில் அனுப்பப்பட்ட பாதுகாப்பான இணைப்பைத் திறக்கவும்.';

  @override
  String get chatMessages => 'செய்திகள்';

  @override
  String get chatTitle => 'அரட்டை';

  @override
  String chatUnread(int count) {
    return 'அரட்டை ($count)';
  }

  @override
  String get chatViewConversation => 'உரையாடலைக் காண்க';

  @override
  String get chatNoMessages => 'உங்கள் உரையாடல்கள் இங்கே தொடங்கும்';

  @override
  String get chatNoMessagesBody =>
      'வேலையை ஏற்ற பிறகு, வாடிக்கையாளருக்குச் செய்தி அனுப்ப அரட்டையைத் திறக்கவும்.';

  @override
  String get chatStartConversation =>
      'இந்த முன்பதிவைப் பற்றிச் செய்தி அனுப்பவும்.';

  @override
  String get chatLoadFailed =>
      'உரையாடலை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get chatMessageHint => 'வாடிக்கையாளருக்குச் செய்தி';

  @override
  String get chatSend => 'செய்தி அனுப்பவும்';

  @override
  String get chatSendFailed => 'செய்தி அனுப்பப்படவில்லை. மீண்டும் அனுப்பவும்.';

  @override
  String get chatTyping => 'வாடிக்கையாளர் தட்டச்சு செய்கிறார்…';

  @override
  String get chatRead => 'படிக்கப்பட்டது';

  @override
  String get chatSent => 'அனுப்பப்பட்டது';

  @override
  String get chatReadOnly =>
      'இந்த முன்பதிவு முடிந்துவிட்டது. உரையாடலைத் தொடர்ந்து படிக்கலாம்.';

  @override
  String get chatOnMyWay => 'வழியில் வருகிறேன்';

  @override
  String get chatReached => 'வந்துவிட்டேன்';

  @override
  String get chatLate => '10 நிமிடம் தாமதமாகும்';

  @override
  String get chatExactLocation => 'சரியான இடத்தைப் பகிரவும்';

  @override
  String get chatMockBackGate => 'பின்புற வாசலுக்கு வாருங்கள்.';

  @override
  String get chatMockWaiting => 'சரி, காத்திருக்கிறேன்.';

  @override
  String get chatMockCall => 'வந்ததும் அழைக்கவும்.';

  @override
  String get chatMockTenMinutes => '10 நிமிடம் சரியா?';

  @override
  String get chatMockThanks => 'நன்றி!';

  @override
  String get chatMockDog => 'நாய் சாதுவானது, கவலை வேண்டாம்.';

  @override
  String get alertsTitle => 'அறிவிப்புகள்';

  @override
  String get alertsMarkAllRead => 'அனைத்தையும் படித்ததாகக் குறிக்கவும்';

  @override
  String get alertsToday => 'இன்று';

  @override
  String get alertsEarlier => 'முந்தையவை';

  @override
  String get alertsEmpty => 'புதிய அறிவிப்புகள் இல்லை';

  @override
  String get alertsEmptyBody =>
      'புதிய கோரிக்கைகளும் வேலை விவரங்களும் இங்கே தோன்றும்.';

  @override
  String get alertsLoadFailed =>
      'அறிவிப்புகளை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get alertsUpdateFailed =>
      'அறிவிப்பைப் புதுப்பிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get alertNewRequest => 'புதிய வேலைக் கோரிக்கை';

  @override
  String get alertAccepted => 'வேலை ஏற்கப்பட்டது';

  @override
  String get alertOnTheWay =>
      'நீங்கள் வரும் தகவல் வாடிக்கையாளருக்குத் தெரிவிக்கப்பட்டது';

  @override
  String get alertArrived => 'வருகை உறுதிசெய்யப்பட்டது';

  @override
  String get alertInProgress => 'வேலை தொடங்கியது';

  @override
  String get alertCompleted => 'வேலை முடிந்தது';

  @override
  String get alertCancelled => 'வேலை ரத்தானது';

  @override
  String alertRequestBody(String service, String distance) {
    return '$service · $distance கி.மீ. தொலைவில்';
  }

  @override
  String alertJobBody(String service) {
    return '$service · முன்பதிவு விவரங்களைக் காண்க';
  }

  @override
  String get reviewsTitle => 'மதிப்புரைகள்';

  @override
  String get reviewsSeeAll => 'அனைத்தையும் காண்க';

  @override
  String get reviewsCustomerRating => 'வாடிக்கையாளர் மதிப்பீடு';

  @override
  String reviewsDistribution(int stars, int count) {
    return '$stars நட்சத்திரங்கள்: $count மதிப்புரைகள்';
  }

  @override
  String get reviewsAll => 'அனைத்தும்';

  @override
  String get reviewsFive => '5 நட்சத்திரங்கள்';

  @override
  String get reviewsFour => '4 நட்சத்திரங்கள்';

  @override
  String get reviewsThreeBelow => '3 நட்சத்திரங்கள் மற்றும் கீழ்';

  @override
  String get reviewsEmpty => 'இன்னும் மதிப்புரைகள் இல்லை';

  @override
  String get reviewsEmptyBody =>
      'வேலை முடிந்த பிறகு வாடிக்கையாளர் மதிப்புரைகள் இங்கே தோன்றும்.';

  @override
  String get reviewsLoadFailed =>
      'மதிப்புரைகளை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get reviewSample1 =>
      'கசிந்த குழாயை நன்றாகச் சரிசெய்து, பழுது நீக்கியதை விளக்கினார்.';

  @override
  String get reviewSample2 => 'நேரத்திற்கு வந்து மிகவும் உதவினார்.';

  @override
  String get reviewSample3 => 'நல்ல வேலை. இடத்தைச் சுத்தமாக விட்டுச் சென்றார்.';

  @override
  String get reviewSample4 =>
      'கவனமாக வேலை செய்து, அனைத்தையும் தெளிவாகத் தெரிவித்தார்.';

  @override
  String get reviewSample5 =>
      'பழுது நன்றாகச் சரியானது, ஆனால் தகவல் தெரிவிக்காமல் அரை மணி நேரம் தாமதமாக வந்தார்.';

  @override
  String get reviewSample6 => 'மீண்டும் முன்பதிவு செய்வேன்.';

  @override
  String get reviewSample7 =>
      'பிரச்சினையைத் தீர்த்து, எங்கள் கேள்விகளுக்குப் பதிலளித்தார்.';

  @override
  String get reviewSample8 =>
      'பொறுமையாகவும் மரியாதையாகவும் முழுமையாகவும் செய்தார். நன்றி.';

  @override
  String get chatCallCustomer => 'வாடிக்கையாளரை அழைக்கவும்';

  @override
  String get chatNavigate => 'வழிகாட்டல்';

  @override
  String get partnerJobReadOnly =>
      'வேலையைப் பார்த்து வாடிக்கையாளரைத் தொடர்புகொள்ளலாம். வேலை நிலையைப் புதுப்பிக்கும் வசதி இன்னும் இல்லை.';

  @override
  String get alertCashCollected => 'பணம் பெறப்பட்டது';

  @override
  String get alertPaymentReceived => 'கட்டணம் பெறப்பட்டது';

  @override
  String get alertSettlement => 'தீர்வுத் தொகை பதிவானது';
}
