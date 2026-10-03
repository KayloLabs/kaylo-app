// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String sosCallWaiting(String name) {
    return 'அடுத்து: $name. Kaylo-வில் 3 விநாடிகளுக்குப் பிறகு அழைப்பு தொடங்கும்.';
  }

  @override
  String sosCallProgress(int attempted, int total) {
    return '$total அழைப்புகளில் $attempted முயற்சிக்கப்பட்டன';
  }

  @override
  String get sosCallsFinished =>
      'அழைப்பு வரிசை முடிந்தது. அழைக்க முயன்றது ஒருவர் பதிலளித்ததை உறுதி செய்யாது.';

  @override
  String get sosCallsStopped =>
      'மீதமுள்ள அழைப்புகள் நிறுத்தப்பட்டன. நடப்பு அழைப்பை ஃபோன் செயலியில் முடிக்கலாம்.';

  @override
  String get sosStopCalls => 'மீதமுள்ள அழைப்புகளை நிறுத்து';

  @override
  String get sosAndroidOnly => 'SIM அழைப்பு Android ஃபோன்களில் கிடைக்கும்.';

  @override
  String careDosesTaken(int taken, int total) {
    return '$total அளவுகளில் $taken எடுக்கப்பட்டது';
  }

  @override
  String get hello => 'வணக்கம்';

  @override
  String get searchServices => 'சேவைகளைத் தேடுங்கள்…';

  @override
  String get whatDoYouNeedHelpWith => 'உங்களுக்கு என்ன உதவி வேண்டும்?';

  @override
  String get home => 'வீடு';

  @override
  String get homeSubtitle => 'உங்கள் வீட்டிற்கான\nதீர்வுகள்.';

  @override
  String get farm => 'பண்ணை';

  @override
  String get farmSubtitle => 'உங்கள் பண்ணைக்கு\nபராமரிப்பும் ஆதரவும்.';

  @override
  String get care => 'பராமரிப்பு';

  @override
  String get careSubtitle => 'உங்கள் அன்புக்குரியவர்களுக்கான\nஉதவி.';

  @override
  String get popularServices => 'பிரபலமான சேவைகள்';

  @override
  String get seeAll => 'அனைத்தையும் காண்க';

  @override
  String get comingSoon => 'விரைவில் வருகிறது';

  @override
  String get howCanWeHelp => 'இன்று நாங்கள் உங்களுக்கு எப்படி உதவலாம்?';

  @override
  String get heroCoconutTitle => 'தேங்காய் பறிப்பது\nஇப்போது எளிது';

  @override
  String get heroCoconutSubtitle =>
      'உங்கள் பகுதியில் நம்பகமான\nஏறுபவர்களை புக் செய்யுங்கள்';

  @override
  String get heroCleanTitle => 'இன்றே உங்கள் வீட்டை\nசுத்தம் செய்யுங்கள்';

  @override
  String get heroCleanSubtitle => 'உங்கள் வீட்டு வாசலில்\nதொழில்முறை சேவைகள்';

  @override
  String get heroPlumberTitle => 'திறமையான பிளம்பர்களும்\nவிவசாயிகளும் தயார்';

  @override
  String get heroPlumberSubtitle => 'ஒவ்வொரு வேலைக்கும்\nநம்பகமான உதவியாளர்கள்';

  @override
  String get heroBookNow => 'இப்போதே புக் செய்யுங்கள்';

  @override
  String get heroExplore => 'ஆராயுங்கள்';

  @override
  String get heroHireNow => 'இப்போதே அமர்த்துங்கள்';

  @override
  String get promoTitle => 'முக்கியமான வேலைகளை ஒருபோதும் தவறவிடாதீர்கள்';

  @override
  String get promoSubtitle =>
      'நினைவூட்டல்களை அமைக்கவும், மீதியை\nநாங்கள் பார்த்துக்கொள்கிறோம்.';

  @override
  String get promoButton => 'நினைவூட்டல் அமைக்கவும்';

  @override
  String get recommendedForYou => 'உங்களுக்காக பரிந்துரைக்கப்பட்டவை';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get appearance => 'தோற்றம்';

  @override
  String get theme => 'தீம்';

  @override
  String get themeSystem => 'சிஸ்டம்';

  @override
  String get themeLight => 'லைட்';

  @override
  String get themeDark => 'டார்க்';

  @override
  String get language => 'மொழி';

  @override
  String get accessibility => 'அணுகல்தன்மை';

  @override
  String get careModeTitle => 'கெய்லோ கேர் மோடு';

  @override
  String get careModeSubtitle =>
      'முதியவர்களுக்காக பெரிய எழுத்துக்களும் எளிய திரைகளும்';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get pushNotifications => 'புஷ் அறிவிப்புகள்';

  @override
  String get pushNotificationsSubtitle =>
      'புக்கிங் புதுப்பிப்புகளும் சலுகைகளும்';

  @override
  String get about => 'பயன்பாட்டைப் பற்றி';

  @override
  String get version => 'பதிப்பு';

  @override
  String get termsPrivacy => 'விதிமுறைகளும் தனியுரிமையும்';

  @override
  String get madeInKerala => 'கேரளாவில் ♥ உடன் உருவாக்கப்பட்டது';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get statBookings => 'புக்கிங்குகள்';

  @override
  String get statRating => 'மதிப்பீடு';

  @override
  String get statSaved => 'சேமித்தவை';

  @override
  String get account => 'கணக்கு';

  @override
  String get myBookings => 'என் புக்கிங்குகள்';

  @override
  String get myBookingsSubtitle =>
      'உங்கள் சேவைகளை கண்காணிக்கவும் நிர்வகிக்கவும்';

  @override
  String get savedAddresses => 'சேமித்த முகவரிகள்';

  @override
  String get paymentMethods => 'பணம் செலுத்தும் முறைகள்';

  @override
  String get preferences => 'விருப்பத்தேர்வுகள்';

  @override
  String get settingsSubtitle => 'தீம், மொழி, கேர் மோடு, அறிவிப்புகள்';

  @override
  String get support => 'ஆதரவு';

  @override
  String get helpSupport => 'உதவியும் ஆதரவும்';

  @override
  String get rateKaylo => 'கெய்லோவை மதிப்பிடுங்கள்';

  @override
  String get rateThanks => 'அன்புக்கு நன்றி!';

  @override
  String get logOut => 'வெளியேறு';

  @override
  String get logOutConfirmTitle => 'வெளியேறவா?';

  @override
  String get logOutConfirmMessage =>
      'சேவைகளை புக் செய்ய மீண்டும் உள்நுழைய வேண்டியிருக்கும்.';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get profileEditSoon => 'உள்நுழைவுடன் சுயவிவரத் திருத்தம் வரும்';

  @override
  String get editProfile => 'சுயவிவரத்தைத் திருத்து';

  @override
  String get firstName => 'முதல் பெயர்';

  @override
  String get lastName => 'கடைசி பெயர்';

  @override
  String get profileUpdated => 'சுயவிவரம் புதுப்பிக்கப்பட்டது';

  @override
  String get statCompleted => 'முடிந்தது';

  @override
  String get kayloCare => 'கெய்லோ கேர்';

  @override
  String get careHomeGreeting => 'இன்று நாங்கள் உங்களை எப்படி பராமரிக்கலாம்?';

  @override
  String get medicineReminders => 'மருந்து நினைவூட்டல்கள்';

  @override
  String get medicineRemindersSubtitle => 'எந்த டோஸையும் தவறவிடாதீர்கள்';

  @override
  String get doctorAppointment => 'மருத்துவர் சந்திப்பு';

  @override
  String get doctorAppointmentSubtitle =>
      'நேரில் அல்லது டெலிகன்சல்ட் புக் செய்யுங்கள்';

  @override
  String get emergencySos => 'அவசர SOS';

  @override
  String get emergencySosSubtitle => 'குடும்பத்தினருக்கு உடனடி எச்சரிக்கை';

  @override
  String get caregiverBooking => 'பராமரிப்பாளரை புக் செய்யுங்கள்';

  @override
  String get caregiverBookingSubtitle => 'வீட்டில் நம்பகமான உதவி';

  @override
  String get themeCareOverride =>
      'கேர் மோடு இயக்கத்தில் இருக்கும்போது தீம் அதைப் பின்பற்றும்';

  @override
  String get languageSettings => 'மொழி அமைப்புகள்';

  @override
  String get voiceSearch => 'குரல் தேடல்';

  @override
  String get voiceListening => 'கேட்கிறோம்…';

  @override
  String get voiceTapToSpeak => 'இப்போது பேசுங்கள், எந்த ஆப் மொழியிலும்';

  @override
  String get voiceYouSaid => 'நீங்கள் சொன்னது';

  @override
  String get voiceNoMatch => 'பொருந்தும் சேவை இல்லை. மீண்டும் முயற்சிக்கவா?';

  @override
  String get voiceUnavailable => 'இந்த சாதனத்தில் குரல் தேடல் இல்லை';

  @override
  String get voiceTryAgain => 'மீண்டும் முயற்சி';

  @override
  String get voiceMicDenied =>
      'மைக்ரோஃபோன் அனுமதி மறுக்கப்பட்டது. குரல் தேடலுக்கு உலாவி அல்லது ஃபோன் அமைப்புகளில் அனுமதிக்கவும்.';

  @override
  String get homeServices => 'வீட்டு சேவைகள்';

  @override
  String get allHomeServices => 'அனைத்து வீட்டு சேவைகள்';

  @override
  String get exploreHomeServices =>
      'சரிபார்க்கப்பட்ட வீட்டு சேவை நிபுணர்களை ஆராயுங்கள்';

  @override
  String get serviceDetails => 'சேவை விவரங்கள்';

  @override
  String get professionalAtDoorstep =>
      'உங்கள் வீட்டு வாசலில் தொழில்முறை சேவைகள்';

  @override
  String get popularSubServices => 'பிரபலமான துணை சேவைகள்';

  @override
  String get selectSubServices => 'துணை சேவைகளைத் தேர்ந்தெடுக்கவும்';

  @override
  String get startingFrom => 'தொடக்க விலை';

  @override
  String get bookNow => 'இப்போது புக் செய்';

  @override
  String get bookService => 'சேவை புக் செய்க';

  @override
  String get workersAvailable => 'பணியாளர்கள் உள்ளனர்';

  @override
  String get availableWorkers => 'கிடைக்கும் பணியாளர்கள்';

  @override
  String get sortAndFilter => 'வரிசைப்படுத்து & வடிகட்டு';

  @override
  String get sortBy => 'இதன்படி வரிசைப்படுத்து';

  @override
  String get rating => 'மதிப்பீடு';

  @override
  String get priceLowToHigh => 'விலை: குறைவிலிருந்து அதிகம்';

  @override
  String get priceHighToLow => 'விலை: அதிகத்திலிருந்து குறைவு';

  @override
  String get experience => 'அனுபவம்';

  @override
  String get distance => 'தூரம்';

  @override
  String get filter => 'வடிகட்டி';

  @override
  String get priceRange => 'விலை வரம்பு';

  @override
  String get availability => 'இருப்பு';

  @override
  String get availableToday => 'இன்று கிடைக்கும்';

  @override
  String get minRating => 'குறைந்தபட்ச மதிப்பீடு';

  @override
  String get verifiedOnly => 'சரிபார்க்கப்பட்டவர்கள் மட்டும்';

  @override
  String get apply => 'பயன்படுத்து';

  @override
  String get reset => 'மீட்டமை';

  @override
  String get noWorkersFound => 'பணியாளர்கள் யாரும் கிடைக்கவில்லை';

  @override
  String get workerProfile => 'சுயவிவரம்';

  @override
  String get completedJobs => 'முடித்த வேலைகள்';

  @override
  String get yearsExperience => 'ஆண்டுகள் அனுபவம்';

  @override
  String get trustScore => 'நம்பகத்தன்மை மதிப்பெண்';

  @override
  String get responseTime => 'பதில் நேரம்';

  @override
  String get certifications => 'சான்றிதழ்கள்';

  @override
  String get reviews => 'மதிப்புரைகள்';

  @override
  String get customerReviews => 'வாடிக்கையாளர் மதிப்புரைகள்';

  @override
  String get verifiedProfessional => 'சரிபார்க்கப்பட்ட நிபுணர்';

  @override
  String get searchServicesOrWorkers =>
      'சேவைகள் அல்லது நிபுணர்களைத் தேடுங்கள்…';

  @override
  String get recentSearches => 'சமீபத்திய தேடல்கள்';

  @override
  String get clearAll => 'அனைத்தையும் அழி';

  @override
  String get services => 'சேவைகள்';

  @override
  String get professionals => 'நிபுணர்கள்';

  @override
  String get noResultsFound => 'முடிவுகள் எதுவும் இல்லை';

  @override
  String get tryDifferentSearch =>
      'வேறு சேவை அல்லது நிபுணரைத் தேட முயற்சிக்கவும்';

  @override
  String get selectSpecialty => 'சிறப்புத் துறையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get availableDoctors => 'கிடைக்கும் மருத்துவர்கள்';

  @override
  String get consultationFee => 'ஆலோசனைக் கட்டணம்';

  @override
  String get selectDate => 'தேதி';

  @override
  String get selectTimeSlot => 'நேரம்';

  @override
  String get morning => 'காலை';

  @override
  String get afternoon => 'மதியம்';

  @override
  String get evening => 'மாலை';

  @override
  String get consultationType => 'ஆலோசனை வகை';

  @override
  String get homeVisit => 'வீட்டு வருகை';

  @override
  String get teleconsult => 'வீடியோ டெலிகன்சல்ட்';

  @override
  String get confirmAppointment => 'சந்திப்பை உறுதிப்படுத்தவும்';

  @override
  String get upcomingAppointments => 'வரவிருக்கும் சந்திப்புகள்';

  @override
  String get appointmentConfirmed => 'சந்திப்பு உறுதி செய்யப்பட்டது!';

  @override
  String get appointmentDetails => 'உங்கள் சந்திப்பு திட்டமிடப்பட்டுள்ளது.';

  @override
  String get selectCaregiver => 'பராமரிப்பாளரைத் தேர்ந்தெடுக்கவும்';

  @override
  String get hours => 'மணிநேரம்';

  @override
  String get selectHours => 'மணிநேரங்களைத் தேர்ந்தெடுக்கவும்';

  @override
  String get careType => 'பராமரிப்பு வகை';

  @override
  String get elderlyCare => 'முதியோர் பராமரிப்பு';

  @override
  String get postOpCare => 'அறுவை சிகிச்சைக்குப் பின் பராமரிப்பு';

  @override
  String get companionship => 'துணை';

  @override
  String get mobilityAssistance => 'இயக்க உதவி';

  @override
  String get totalAmount => 'மொத்த தொகை';

  @override
  String get caregiverBooked => 'பராமரிப்பாளர் புக் செய்யப்பட்டார்!';

  @override
  String get caregiverBookingSuccess => 'உங்கள் கோரிக்கை சமர்ப்பிக்கப்பட்டது.';

  @override
  String get nearYou => 'உங்கள் அருகில்';

  @override
  String get farmServices => 'விவசாய சேவைகள்';

  @override
  String get farmServicesTagline =>
      'சரிபார்க்கப்பட்ட மரம் ஏறுபவர்கள், அறுவடையாளர்கள், பண்ணைப் பணியாளர்கள். மரம் அல்லது மணிநேர அடிப்படையில் புக் செய்யலாம்.';

  @override
  String get noServicesTitle => 'இன்னும் சேவைகள் இல்லை';

  @override
  String get noServicesDescription =>
      'பணியாளர்கள் சேரும்போது விவசாய சேவைகள் இங்கே தோன்றும்.';

  @override
  String perUnit(String unit) {
    return 'ஒரு $unitக்கு';
  }

  @override
  String get unitTree => 'மரம்';

  @override
  String get unitHour => 'மணிநேரம்';

  @override
  String get unitVisit => 'வருகை';

  @override
  String unitTreeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மரங்கள்',
      one: '1 மரம்',
    );
    return '$_temp0';
  }

  @override
  String unitHourCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மணிநேரம்',
      one: '1 மணிநேரம்',
    );
    return '$_temp0';
  }

  @override
  String unitVisitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count வருகைகள்',
      one: '1 வருகை',
    );
    return '$_temp0';
  }

  @override
  String get serviceStandards => 'பணியாளரின் உறுதிமொழி';

  @override
  String get standardSafetyHarness => 'ஒவ்வொரு ஏற்றத்திலும் பாதுகாப்பு ஹார்னஸ்';

  @override
  String get standardBunchProtection =>
      'குலைகள் கயிற்றில் இறக்கப்படும், கீழே போடப்படாது';

  @override
  String get standardDebrisCleared =>
      'செல்லும் முன் ஓலை, மட்டைகள் அகற்றப்படும்';

  @override
  String get standardGroundNets => 'கீழுள்ள பயிர்களைக் காக்க வலைகள்';

  @override
  String get standardPowerLineGuard =>
      'மின் கம்பிகளிலிருந்து பாதுகாப்பான இடைவெளி';

  @override
  String get standardWoodChipping => 'வெட்டிய கிளைகள் சிறிதாக்கி அடுக்கப்படும்';

  @override
  String get standardEcoCompost => 'இயற்கை உரமும் மூடாக்கும் மட்டுமே';

  @override
  String get standardPestPrevention => 'ஒவ்வொரு வருகையிலும் பூச்சி சோதனை';

  @override
  String get standardBoundaryClearing => 'எல்லைகளும் வடிகால்களும் சுத்தம்';

  @override
  String get standardVerifiedWorker => 'அடையாளம் சரிபார்க்கப்பட்ட பணியாளர்';

  @override
  String get standardOnTimeArrival => 'புக் செய்த நேரத்தில் வருவார்';

  @override
  String get standardFairPrice => 'வேலை தொடங்கும் முன் விலை உறுதி';

  @override
  String workersNearYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'உங்கள் அருகில் $count சரிபார்க்கப்பட்ட பணியாளர்கள்',
      one: 'உங்கள் அருகில் 1 சரிபார்க்கப்பட்ட பணியாளர்',
    );
    return '$_temp0';
  }

  @override
  String get noWorkersYet =>
      'இந்த சேவைக்கான பணியாளர்கள் சேர்க்கப்பட்டு வருகிறார்கள்';

  @override
  String get liveTotalNote =>
      'அடுத்த படியில் எண்ணிக்கையைத் தேர்வு செய்யும்போது மொத்தம் உடனே மாறும்.';

  @override
  String get scheduleTitle => 'அட்டவணை';

  @override
  String get change => 'மாற்று';

  @override
  String get quantity => 'எண்ணிக்கை';

  @override
  String priceEach(String price) {
    return 'ஒன்றுக்கு $price';
  }

  @override
  String get calculation => 'கணக்கு';

  @override
  String breakdown(String price, String units) {
    return '$price × $units';
  }

  @override
  String get total => 'மொத்தம்';

  @override
  String get farmAddress => 'பண்ணை முகவரி';

  @override
  String get farmAddressHint => 'வீட்டின் பெயர், தெரு, ஊர்';

  @override
  String get addressRequired => 'பண்ணை முகவரியை உள்ளிடவும்';

  @override
  String get serviceAddress => 'சேவை முகவரி';

  @override
  String get serviceAddressRequired => 'சேவை முகவரியை உள்ளிடவும்';

  @override
  String get worker => 'தொழிலாளி';

  @override
  String get popularSearches => 'பிரபலமான தேடல்கள்';

  @override
  String get continueToPayment => 'பணம் செலுத்த';

  @override
  String get paymentTitle => 'பணம் செலுத்துதல்';

  @override
  String get orderSummary => 'ஆர்டர் சுருக்கம்';

  @override
  String get service => 'சேவை';

  @override
  String get date => 'தேதி';

  @override
  String get time => 'நேரம்';

  @override
  String get rate => 'கட்டணம்';

  @override
  String get totalPayable => 'செலுத்த வேண்டிய தொகை';

  @override
  String get paymentMethod => 'பணம் செலுத்தும் முறை';

  @override
  String get payUpi => 'UPI';

  @override
  String get payUpiSubtitle => 'Google Pay, PhonePe, Paytm';

  @override
  String get payCard => 'கிரெடிட் அல்லது டெபிட் கார்டு';

  @override
  String get payCardSubtitle => 'Visa, Mastercard, RuPay';

  @override
  String get payAfter => 'சேவைக்குப் பிறகு செலுத்து';

  @override
  String get payAfterSubtitle => 'வேலை முடிந்ததும் பணியாளரிடம் கொடுக்கலாம்';

  @override
  String confirmAndPay(String amount) {
    return '$amount செலுத்தி உறுதி செய்';
  }

  @override
  String get confirmBooking => 'புக்கிங்கை உறுதி செய்';

  @override
  String get paymentFailed =>
      'பணம் செலுத்துதல் முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get draftMissing =>
      'இந்தப் படிக்கு ஒரு புக்கிங் நடந்துகொண்டிருக்க வேண்டும். விவசாய சேவைகளிலிருந்து மீண்டும் தொடங்கவும்.';

  @override
  String get bookingConfirmed => 'புக்கிங் உறுதியானது';

  @override
  String bookingConfirmedSubtitle(String date, String time) {
    return '$date அன்று $time மணிக்கு பணியாளர் வருவார்';
  }

  @override
  String get bookingId => 'புக்கிங் ஐடி';

  @override
  String get status => 'நிலை';

  @override
  String get payment => 'பணம்';

  @override
  String get viewMyBookings => 'என் புக்கிங்குகளைப் பார்';

  @override
  String get backToHome => 'முகப்புக்குத் திரும்பு';

  @override
  String get statusPending => 'நிலுவையில்';

  @override
  String get statusConfirmed => 'உறுதியானது';

  @override
  String get statusInProgress => 'நடந்துகொண்டிருக்கிறது';

  @override
  String get statusCompleted => 'முடிந்தது';

  @override
  String get statusCancelled => 'ரத்தானது';

  @override
  String get noBookingsTitle => 'இன்னும் புக்கிங் இல்லை';

  @override
  String get noBookingsDescription =>
      'விவசாய அல்லது வீட்டு சேவையை புக் செய்தால் இங்கே தோன்றும்.';

  @override
  String get bookAService => 'சேவையை புக் செய்';

  @override
  String get upcoming => 'வரவிருப்பவை';

  @override
  String get past => 'முடிந்தவை';

  @override
  String get somethingWentWrong => 'ஏதோ தவறு நடந்தது';

  @override
  String get messages => 'செய்திகள்';

  @override
  String get messagesSubtitle => 'புக் செய்த பணியாளர்களுடன் அரட்டையடிக்கவும்';

  @override
  String get noMessagesTitle => 'இன்னும் உரையாடல்கள் இல்லை';

  @override
  String get noMessagesDescription =>
      'பணியாளரை புக் செய்த பிறகு இங்கே செய்தி அனுப்பலாம்.';

  @override
  String get noMessagesInThread => 'உரையாடலைத் தொடங்க வணக்கம் சொல்லுங்கள்';

  @override
  String get online => 'ஆன்லைன்';

  @override
  String get offline => 'ஆஃப்லைன்';

  @override
  String get typeMessage => 'செய்தியை எழுதுங்கள்';

  @override
  String get todaysMedicines => 'இன்றைய மருந்துகள்';

  @override
  String get medicinesSubtitle => 'மருந்து எடுத்த பிறகு வட்டத்தைத் தொடவும்';

  @override
  String pendingDoses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count டோஸ் மீதம்',
      one: '1 டோஸ் மீதம்',
      zero: 'எல்லா மருந்தும் எடுத்தாயிற்று',
    );
    return '$_temp0';
  }

  @override
  String nextDose(String name, String time) {
    return 'அடுத்தது: $time மணிக்கு $name';
  }

  @override
  String get addReminder => 'நினைவூட்டல் சேர்';

  @override
  String get medicineName => 'மருந்தின் பெயர்';

  @override
  String get medicineNameHint => 'எ.கா. BP மாத்திரை';

  @override
  String get dosage => 'அளவு';

  @override
  String get dosageHint => 'எ.கா. காலை உணவுக்குப் பின் 1 மாத்திரை';

  @override
  String get reminderTime => 'நினைவூட்டல் நேரம்';

  @override
  String get save => 'சேமி';

  @override
  String addedBy(String name) {
    return 'சேர்த்தவர்: $name';
  }

  @override
  String markedTaken(String name) {
    return '$name எடுத்ததாகக் குறிக்கப்பட்டது';
  }

  @override
  String markedPending(String name) {
    return '$name மீதம் எனக் குறிக்கப்பட்டது';
  }

  @override
  String get nameRequired => 'பெயரை உள்ளிடவும்';

  @override
  String get phoneRequired => 'தொலைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get noRemindersTitle => 'இன்னும் நினைவூட்டல்கள் இல்லை';

  @override
  String get noRemindersDescription =>
      'மருந்துகளைச் சேர்க்கவும், சரியான நேரத்தில் கெய்லோ நினைவூட்டும்.';

  @override
  String get pressAndHold => 'அழுத்திப் பிடிக்கவும்';

  @override
  String get holdSeconds => '3 விநாடிகள் பிடிக்கவும்';

  @override
  String secondsShort(int seconds) {
    return '$seconds வி';
  }

  @override
  String get sosHoldHint =>
      'SIM மூலம் தொடர்புகளை அழைக்க 3 விநாடிகள் பிடிக்கவும். முதன்மைத் தொடர்பு முதலில் அழைக்கப்படும். ஒவ்வொரு அழைப்பின் பின்னரும் தொடர Kaylo-க்கு திரும்பவும். வழக்கமான SIM கட்டணங்கள் பொருந்தும்.';

  @override
  String get sosReleasedEarly => 'அழைக்க 3 விநாடிகள் பிடிக்கவும்';

  @override
  String get sosSentTitle => 'உதவி வந்துகொண்டிருக்கிறது';

  @override
  String sosSentContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count தொடர்புகளுக்கு இருப்பிடத்துடன் அலர்ட் அனுப்பப்பட்டது',
      one: '1 தொடர்புக்கு இருப்பிடத்துடன் அலர்ட் அனுப்பப்பட்டது',
    );
    return '$_temp0';
  }

  @override
  String sosCallingPrimary(String name) {
    return '$nameஐ அழைக்கிறது';
  }

  @override
  String get sosNoContacts =>
      'அலர்ட் யாருக்காவது கிடைக்க, முதலில் ஒரு அவசரத் தொடர்பைச் சேர்க்கவும்.';

  @override
  String get dismiss => 'மூடு';

  @override
  String get emergencyContacts => 'அவசரத் தொடர்புகள்';

  @override
  String get addContact => 'தொடர்பைச் சேர்';

  @override
  String get contactName => 'பெயர்';

  @override
  String get relationship => 'உறவு';

  @override
  String get relationshipHint => 'எ.கா. மகள்';

  @override
  String get phoneNumber => 'தொலைபேசி எண்';

  @override
  String get primary => 'முதன்மை';

  @override
  String get setAsPrimary => 'முதன்மையாக்கு';

  @override
  String get removeContact => 'நீக்கு';

  @override
  String get sosHistory => 'SOS வரலாறு';

  @override
  String alertsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count அலர்ட்கள் அனுப்பப்பட்டன',
      one: '1 அலர்ட் அனுப்பப்பட்டது',
      zero: 'அலர்ட் எதுவும் அனுப்பவில்லை',
    );
    return '$_temp0';
  }

  @override
  String get noSosTitle => 'அலர்ட் எதுவும் அனுப்பவில்லை';

  @override
  String get noSosDescription =>
      'நீங்கள் அனுப்பும் அலர்ட்களும் யாருக்குத் தெரிவிக்கப்பட்டது என்பதும் இங்கே தோன்றும்.';

  @override
  String alertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count தொடர்புகளுக்குத் தெரிவிக்கப்பட்டது',
      one: '1 தொடர்புக்குத் தெரிவிக்கப்பட்டது',
    );
    return '$_temp0';
  }

  @override
  String get sosStatusOpen => 'திறந்தது';

  @override
  String get sosStatusAcknowledged => 'பார்க்கப்பட்டது';

  @override
  String get sosStatusResolved => 'தீர்க்கப்பட்டது';

  @override
  String locationShared(String location) {
    return 'இருப்பிடம் பகிரப்பட்டது: $location';
  }

  @override
  String primaryContact(String name) {
    return 'முதன்மைத் தொடர்பு: $name';
  }

  @override
  String get unitOrder => 'ஆர்டர்';

  @override
  String unitOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ஆர்டர்கள்',
      one: '1 ஆர்டர்',
    );
    return '$_temp0';
  }

  @override
  String get standardPartsQuoted =>
      'உதிரி பாகங்களின் விலை பொருத்தும் முன் தெரிவிக்கப்படும்';

  @override
  String get standardCleanupAfter => 'செல்லும் முன் வேலை இடம் சுத்தம்';

  @override
  String get standardBackgroundChecked =>
      'பின்னணி சரிபார்க்கப்பட்ட பராமரிப்பாளர்';

  @override
  String get standardPrescriptionChecked =>
      'மருந்துச்சீட்டு மருந்தாளுநரால் சரிபார்க்கப்படும்';

  @override
  String get careServices => 'கேர் சேவைகள்';

  @override
  String get allServices => 'அனைத்து சேவைகளும்';

  @override
  String get homeServicesTagline =>
      'நேரத்திற்கு வந்து வேலை முடிந்ததும் சுத்தம் செய்யும் பிளம்பர்கள், எலக்ட்ரீஷியன்கள், துப்புரவாளர்கள்.';

  @override
  String get careServicesTagline =>
      'நீங்கள் பராமரிப்பவர்களுக்கு பயிற்சி பெற்ற பராமரிப்பாளர்களும் வீட்டு வாசலில் மருந்துகளும்.';

  @override
  String get allServicesTagline =>
      'வீடு, விவசாயம், கேர் என கெய்லோ வழங்கும் எல்லாமும்.';

  @override
  String get useMyLocation => 'என் இருப்பிடத்தைப் பயன்படுத்து';

  @override
  String get locating => 'தேடுகிறது…';

  @override
  String get locationServicesOff =>
      'இருப்பிட சேவைகளை இயக்கி மீண்டும் முயற்சிக்கவும்.';

  @override
  String get locationDenied => 'இருப்பிட அனுமதி வழங்கப்படவில்லை.';

  @override
  String get locationDeniedForever =>
      'கெய்லோவுக்கு இருப்பிடம் தடுக்கப்பட்டுள்ளது. சாதன அமைப்புகளில் அனுமதிக்கவும்.';

  @override
  String get locationTimeout =>
      'GPS கிடைக்கவில்லை. திறந்த இடத்திற்குச் சென்று மீண்டும் முயற்சிக்கவும்.';

  @override
  String get locationUnavailable => 'இருப்பிடம் இப்போது கிடைக்கவில்லை.';

  @override
  String get markAllRead => 'அனைத்தையும் படித்ததாகக் குறி';

  @override
  String get noNotificationsTitle => 'எல்லாம் பார்த்தாயிற்று';

  @override
  String get noNotificationsDescription =>
      'புக்கிங் புதுப்பிப்புகள், செய்திகள், நினைவூட்டல்கள் இங்கே தோன்றும்.';

  @override
  String get today => 'இன்று';

  @override
  String get earlier => 'முன்பு';

  @override
  String get justNow => 'இப்போது';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நிமிடங்கள் முன்',
      one: '1 நிமிடம் முன்',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மணிநேரம் முன்',
      one: '1 மணிநேரம் முன்',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாட்கள் முன்',
      one: 'நேற்று',
    );
    return '$_temp0';
  }

  @override
  String get bookingDetails => 'புக்கிங் விவரங்கள்';

  @override
  String get cancelBookingTitle => 'இந்த புக்கிங்கை ரத்து செய்யவா?';

  @override
  String get cancelBookingMessage =>
      'பணியாளர் விடுவிக்கப்படுவார். எப்போது வேண்டுமானாலும் மீண்டும் புக் செய்யலாம்.';

  @override
  String get keepBooking => 'புக்கிங்கை வைத்திரு';

  @override
  String get cancelBooking => 'புக்கிங்கை ரத்து செய்';

  @override
  String get bookingCancelled => 'புக்கிங் ரத்தானது';

  @override
  String get bookingCancelledBanner => 'இந்த புக்கிங் ரத்து செய்யப்பட்டது.';

  @override
  String get stepRequested => 'கோரப்பட்டது';

  @override
  String get stepConfirmed => 'உறுதி';

  @override
  String get stepInProgress => 'நடக்கிறது';

  @override
  String get stepCompleted => 'முடிந்தது';

  @override
  String get assignedWorker => 'உங்கள் பணியாளர்';

  @override
  String get noWorkerYet => 'வருகைக்கு முன் ஒரு பணியாளர் நியமிக்கப்படுவார்.';

  @override
  String get messageWorker => 'செய்தி';

  @override
  String get reschedule => 'நேரத்தை மாற்று';

  @override
  String get bookingRescheduled => 'புக்கிங் நேரம் மாற்றப்பட்டது';

  @override
  String get filters => 'வடிகட்டிகள்';

  @override
  String get category => 'வகை';

  @override
  String get applyFilters => 'பயன்படுத்து';

  @override
  String get sortRelevance => 'பொருத்தம்';

  @override
  String get sortPriceLowHigh => 'விலை: குறைவு முதல்';

  @override
  String get sortPriceHighLow => 'விலை: அதிகம் முதல்';

  @override
  String get allCategories => 'அனைத்தும்';

  @override
  String get noResultsTitle => 'சேவைகள் எதுவும் பொருந்தவில்லை';

  @override
  String get noResultsDescription =>
      'வேறு சொல்லை முயற்சிக்கவும், அல்லது பிரச்சினையைச் சொல்லுங்கள்: \"குழாய் ஒழுகுது\" என்றும் தேடலாம்.';

  @override
  String resultsFor(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '\"$query\" க்கு $count முடிவுகள்',
      one: '\"$query\" க்கு 1 முடிவு',
    );
    return '$_temp0';
  }

  @override
  String get yourLocation => 'உங்கள் இருப்பிடம்';

  @override
  String get or => 'அல்லது';

  @override
  String get townOrCity => 'ஊர் அல்லது நகரம்';

  @override
  String get townHint => 'எ.கா. கண்ணூர்';

  @override
  String get saveLocation => 'இருப்பிடத்தைச் சேமி';

  @override
  String get townRequired => 'ஊர் அல்லது நகரத்தை உள்ளிடவும்';

  @override
  String locationUpdated(String label) {
    return 'இருப்பிடம் $label என அமைக்கப்பட்டது';
  }

  @override
  String get enableLocation => 'இருப்பிடத்தை இயக்கு';

  @override
  String get enableLocationSubtitle =>
      'அருகிலுள்ள பணியாளர்களைக் காட்டவும் SOS அலர்ட்டில் பகிரவும் கெய்லோ உங்கள் இருப்பிடத்தைப் பயன்படுத்துகிறது.';

  @override
  String get locationWillAppear => 'உங்கள் இருப்பிடம் இங்கே தோன்றும்';

  @override
  String get locateAgain => 'மீண்டும் தேடு';

  @override
  String get continueLabel => 'தொடரவும்';

  @override
  String get enterManually => 'கைமுறையாக உள்ளிடு';

  @override
  String get notNow => 'இப்போது வேண்டாம்';

  @override
  String get noAddressesTitle => 'சேமித்த முகவரிகள் இல்லை';

  @override
  String get noAddressesDescription =>
      'வீடு அல்லது பண்ணையை ஒருமுறை சேமித்தால் புக் செய்யும்போது ஒரே தட்டலில் தேர்வு செய்யலாம்.';

  @override
  String get addAddress => 'முகவரியைச் சேர்';

  @override
  String get defaultLabel => 'இயல்பு';

  @override
  String get setAsDefault => 'இயல்பாக்கு';

  @override
  String get removeAddress => 'நீக்கு';

  @override
  String get addressLabel => 'லேபிள்';

  @override
  String get labelHome => 'வீடு';

  @override
  String get labelFarm => 'பண்ணை';

  @override
  String get labelWork => 'வேலை';

  @override
  String get labelOther => 'மற்றவை';

  @override
  String get labelOtherHint => 'எ.கா. அம்மா வீடு';

  @override
  String get addressLine => 'முகவரி';

  @override
  String get addressSaved => 'முகவரி சேமிக்கப்பட்டது';

  @override
  String get contactUs => 'எங்களைத் தொடர்பு கொள்ள';

  @override
  String get emailUs => 'மின்னஞ்சல் அனுப்பு';

  @override
  String get reportProblem => 'பிரச்சினையைத் தெரிவி';

  @override
  String get reportProblemSubtitle => 'என்ன தவறு நடந்தது என்று சொல்லுங்கள்';

  @override
  String get reportProblemTemplate =>
      'என்ன நடந்தது:\nஆப்பில் எங்கே:\nபோன் மாடல்:';

  @override
  String get faq => 'அடிக்கடி கேட்கப்படும் கேள்விகள்';

  @override
  String get faqBookQ => 'சேவையை எப்படி புக் செய்வது?';

  @override
  String get faqBookA =>
      'முகப்புத் திரை அல்லது தேடலில் சேவையைத் தேர்வு செய்து, தேதி, நேரம், எண்ணிக்கையைத் தேர்ந்து, முகவரியைச் சேர்த்து உறுதி செய்யுங்கள். புக்கிங் ஐடி உடனே கிடைக்கும்; புக்கிங்குகளில் கண்காணிக்கலாம்.';

  @override
  String get faqPayQ => 'எப்படி பணம் செலுத்துவது?';

  @override
  String get faqPayA =>
      'UPI, கார்டு உறுதி செய்யும்போதே வசூலிக்கப்படும். வேலை முடிந்ததும் பணியாளரிடம் நேரடியாகக் கொடுக்க \"சேவைக்குப் பிறகு செலுத்து\" என்பதைத் தேர்வு செய்யுங்கள்.';

  @override
  String get faqCancelQ => 'ரத்து செய்யவோ நேரத்தை மாற்றவோ முடியுமா?';

  @override
  String get faqCancelA =>
      'முடியும். புக்கிங்குகளில் புக்கிங்கைத் திறந்து நேரத்தை மாற்று அல்லது ரத்து செய் என்பதைப் பயன்படுத்துங்கள். பணியாளர் புறப்படும் வரை இரண்டும் இலவசம்.';

  @override
  String get faqWorkersQ => 'பணியாளர்கள் எப்படி சரிபார்க்கப்படுகிறார்கள்?';

  @override
  String get faqWorkersA =>
      'பட்டியலிடும் முன் ஒவ்வொரு பணியாளரின் அடையாளமும் சரிபார்க்கப்படும்; புக்கிங்கை முடித்த வாடிக்கையாளர்களிடமிருந்து மட்டுமே மதிப்பீடுகள்.';

  @override
  String get faqCareQ => 'கேர் மோட் என்றால் என்ன?';

  @override
  String get faqCareA =>
      'மூத்தவர்களுக்காக பெரிய எழுத்து, அதிக மாறுபாடு கொண்ட தோற்றத்திற்கு ஆப்பை மாற்றுகிறது; மருந்து நினைவூட்டல்களும் ஒரே அழுத்தத்தில் SOS உம் உண்டு.';

  @override
  String get faqSosQ => 'SOS எப்படி வேலை செய்கிறது?';

  @override
  String get faqSosA =>
      'SOS பொத்தானை மூன்று விநாடிகள் அழுத்திப் பிடிக்கவும். ஒவ்வொரு அவசரத் தொடர்புக்கும் உங்கள் இருப்பிடம் கிடைக்கும்; முதன்மைத் தொடர்பு அழைக்கப்படும்.';

  @override
  String get helpFooter =>
      'கேரளாவின் சிறிய குழு கெய்லோவை உருவாக்குகிறது. ஒவ்வொரு செய்தியும் படிக்கப்படும்.';

  @override
  String get couldNotOpenEmail => 'மின்னஞ்சல் ஆப்பைத் திறக்க முடியவில்லை.';

  @override
  String get rateTitle => 'கெய்லோ எப்படி இருக்கிறது?';

  @override
  String get rateSubtitle =>
      'உங்கள் மதிப்பீடு குழு அடுத்து எதில் கவனம் செலுத்த வேண்டும் என்று சொல்கிறது.';

  @override
  String get rateComment => 'மேம்படுத்த வேண்டியது ஏதேனும்? (விருப்பம்)';

  @override
  String get submitRating => 'சமர்ப்பி';

  @override
  String get pickAStar =>
      'முதலில் ஒரு நட்சத்திர மதிப்பீட்டைத் தேர்வு செய்யுங்கள்';

  @override
  String youRated(int stars) {
    return 'நீங்கள் கெய்லோவுக்கு 5ல் $stars கொடுத்தீர்கள்';
  }

  @override
  String get confirmLocation => 'இருப்பிடத்தை உறுதிப்படுத்து';

  @override
  String get moveMapToPlacePin => 'பின்னை வைக்க வரைபடத்தை நகர்த்தவும்';

  @override
  String get findingAddress => 'முகவரியைத் தேடுகிறது…';

  @override
  String get selectedLocation => 'தேர்ந்தெடுத்த இருப்பிடம்';

  @override
  String get mapUnavailable => 'வரைபட முன்னோட்டம் இல்லை';

  @override
  String get searchTownHint => 'ஊர் அல்லது நகரத்தைத் தேடுங்கள்';

  @override
  String workerAbout(String name, String place, int jobs) {
    return '$name $place-ல் $jobs வேலைகளை முடித்த கெய்லோ நிபுணர் ஆவார்.';
  }

  @override
  String get verificationPending => 'சரிபார்ப்பு செயல்பாட்டில் உள்ளது';

  @override
  String get certGovtId => 'அரசு அடையாளச் சான்று சரிபார்க்கப்பட்டது';

  @override
  String get certGovtIdSub => 'ஆதார் அல்லது வாக்காளர் அட்டை சரிபார்க்கப்பட்டது';

  @override
  String get certPolice => 'காவல்துறை சான்றிதழ் சரிபார்க்கப்பட்டது';

  @override
  String get certPoliceSub => 'பின்னணி சரிபார்ப்பு முடிந்தது';

  @override
  String get certSkill => 'கெய்லோ திறன் சான்றிதழ் பெற்றது';

  @override
  String get certSkillSub => 'நடைமுறைத் திறன்கள் சோதிக்கப்பட்டன';

  @override
  String get hourlyRate => 'மணிநேரக் கட்டணம்';

  @override
  String get perHour => 'மணிக்கு';

  @override
  String get priceOnVisit => 'நேரில் பார்த்து கட்டணம் கூறப்படும்';

  @override
  String get noReviewsYet => 'இன்னும் மதிப்புரைகள் இல்லை';

  @override
  String get newService => 'புதியது';

  @override
  String get nearbyFirst => 'அருகிலுள்ளவர்கள் முதலில்';

  @override
  String get tomorrow => 'நாளை';

  @override
  String inDays(int count) {
    return '$count நாட்களில்';
  }

  @override
  String get whoIsItFor => 'இது யாருக்காக?';

  @override
  String get appointmentNotes =>
      'மருத்துவருக்கான குறிப்புகள் (விருப்பத்தேர்வு)';

  @override
  String appointmentConfirmedWith(String doctor) {
    return '$doctor உடன் சந்திப்பு புக் செய்யப்பட்டது';
  }

  @override
  String get noUpcomingAppointments =>
      'வரவிருக்கும் சந்திப்புகள் எதுவும் இல்லை';

  @override
  String get specGeneral => 'பொது மருத்துவர்';

  @override
  String get specCardio => 'இதய நோய் நிபுணர்';

  @override
  String get specOrtho => 'எலும்பியல் நிபுணர்';

  @override
  String get specGeriatric => 'முதியோர் நல மருத்துவர்';

  @override
  String get specAyurveda => 'ஆயுர்வேதம்';

  @override
  String get incPlumbTap => 'குழாய் பழுதுநீக்கம்';

  @override
  String get incPlumbPipe => 'பைப் கசிவு';

  @override
  String get incPlumbDrain => 'வடிகால் சுத்தம்';

  @override
  String get incPlumbInstall => 'பொருத்துதல்';

  @override
  String get incElecSwitch => 'சுவிட்ச்போர்டு பழுதுநீக்கம்';

  @override
  String get incElecWiring => 'வயரிங் சரிசெய்தல்';

  @override
  String get incElecFan => 'மின்விசிறி பொருத்துதல்';

  @override
  String get incElecMcb => 'MCB ட்ரிப்பிங்';

  @override
  String get incCleanDeep => 'முழு வீடு ஆழ்ந்த தூய்மை';

  @override
  String get incCleanKitchen => 'சமையலறை சுத்தம்';

  @override
  String get incCleanBath => 'குளியலறை தேய்த்தல்';

  @override
  String get incCleanSofa => 'சோஃபா ஷாம்பூ';

  @override
  String get incCarpFurniture => 'மரச்சாமான்கள் பழுது';

  @override
  String get incCarpDoor => 'கதவுகள் மற்றும் ஜன்னல்கள்';

  @override
  String get incCarpLock => 'பூட்டு பொருத்துதல்';

  @override
  String get incCarpCustom => 'தனிப்பயன் மரவேலை';

  @override
  String get incPaintInterior => 'உட்புற பெயிண்டிங்';

  @override
  String get incPaintExterior => 'வெளிப்புற பெயிண்டிங்';

  @override
  String get incPaintPutty => 'சுவர் புட்டி மற்றும் ப்ரைமர்';

  @override
  String get incPaintWaterproof => 'நீர்ப்புகாப்பு';

  @override
  String get incAcFilter => 'ஃபில்டர் சுத்தம்';

  @override
  String get incAcGas => 'கேஸ் நிரப்புதல்';

  @override
  String get incAcCooling => 'குளிர்ச்சி பிரச்சனை சரிசெய்தல்';

  @override
  String get incAcInstall => 'பொருத்துதல் மற்றும் அகற்றுதல்';

  @override
  String get incApplWasher => 'சலவை இயந்திரம்';

  @override
  String get incApplFridge => 'குளிர்சாதன பெட்டி';

  @override
  String get incApplMicrowave => 'மைக்ரோவேவ்';

  @override
  String get incApplTv => 'டிவி பொருத்துதல் மற்றும் பழுது';

  @override
  String get incGenInspect => 'பொது ஆய்வு';

  @override
  String get incGenRepair => 'பழுது மற்றும் சரிசெய்தல்';

  @override
  String get incGenInstall => 'புதிய பொருத்துதல்';

  @override
  String get incGenMaintain => 'பராமரிப்பு';

  @override
  String get invoiceEmail => 'இன்வாய்ஸிற்கான மின்னஞ்சல்';

  @override
  String get invoiceEmailRequired =>
      'இன்வாய்ஸிற்கு ஒரு மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get confirmationEmail =>
      'உறுதிப்படுத்தலுக்கான மின்னஞ்சல் (விருப்பத்தேர்வு)';

  @override
  String get payNow => 'இப்போது செலுத்து';

  @override
  String get payNowSubtitle =>
      'கார்டு, நெட்பேங்கிங் அல்லது UPI, Razorpay மூலம் பாதுகாப்பானது';

  @override
  String get prescriptions => 'மருந்துச் சீட்டுகள்';

  @override
  String get prescriptionsSubtitle =>
      'உங்கள் உடல்நலப் பதிவுகளை ஸ்கேன் செய்து, படித்து, பாதுகாக்கவும்';

  @override
  String get trustedContacts => 'நம்பகமான தொடர்புகள்';

  @override
  String get trustedContactsSubtitle =>
      'SOS அழைப்புகளுக்கு குடும்பத்தினரையும் மருத்துவர்களையும் இணைக்கவும்';

  @override
  String get sosStartFailedContacts =>
      'SOS தொடங்க முடியவில்லை. உங்கள் இணைப்பையும் நம்பகமான தொடர்புகளையும் சரிபார்க்கவும்.';

  @override
  String get sosStartFailed =>
      'SOS தொடங்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get sosModeKaylo => 'கெய்லோ அழைப்பு';

  @override
  String get sosModeSim => 'சிம் அழைப்பு';

  @override
  String get manageTrustedContacts => 'நம்பகமான தொடர்புகளை நிர்வகிக்கவும்';

  @override
  String get sosKayloHoldHint =>
      'உங்கள் நம்பகமான கெய்லோ தொடர்புகளை அழைக்க 3 விநாடிகள் அழுத்திப் பிடிக்கவும். அவர்கள் ஒன்றாக அழைப்பில் சேரலாம். அழைப்பிதழ் அனுப்பியதால் யாரோ பதிலளித்தார்கள் என்று பொருள் அல்ல.';

  @override
  String get contactsOpenFailed => 'தொலைபேசி தொடர்புகளைத் திறக்க முடியவில்லை.';

  @override
  String get chooseFromPhoneContacts =>
      'தொலைபேசி தொடர்புகளிலிருந்து தேர்வுசெய்க';

  @override
  String sosContactsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count தொடர்புகள் தவிர்க்கப்பட்டன: அந்த எண்களை அழைக்க முடியாது.',
      one: '1 தொடர்பு தவிர்க்கப்பட்டது: அந்த எண்ணை அழைக்க முடியாது.',
    );
    return '$_temp0';
  }

  @override
  String get incomingSosTitle => 'கெய்லோ SOS வருகிறது';

  @override
  String get incomingSosSubtitle => 'நம்பகமான தொடர்பு ஒருவருக்கு உதவி தேவை';

  @override
  String get decline => 'நிராகரி';

  @override
  String get joinCall => 'அழைப்பில் சேர்';

  @override
  String get signInLiveForContacts =>
      'நம்பகமான தொடர்புகளை இணைக்க நேரடி செயலியில் உள்நுழையவும்.';

  @override
  String get couldNotConnectRetry =>
      'இணைக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get refreshConnections => 'இணைப்புகளைப் புதுப்பி';

  @override
  String get trustedCircleTitle =>
      'உங்கள் அன்புக்குரியவர்களை கெய்லோவிற்குக் கொண்டு வாருங்கள்';

  @override
  String get trustedCircleBody =>
      'கெய்லோ பயன்படுத்தும் ஐந்து குடும்பத்தினர் அல்லது மருத்துவர்கள் வரை அழைக்கலாம். அவர்கள் உங்கள் குறியீட்டை ஏற்றால், உங்கள் SOS எச்சரிக்கைகளைப் பெற்று அதே குரல் அழைப்பில் சேர முடியும்.';

  @override
  String get getInviteCode => 'என் அழைப்புக் குறியீட்டைப் பெறு';

  @override
  String get inviteCodeCopied => 'அழைப்புக் குறியீடு நகலெடுக்கப்பட்டது';

  @override
  String get copyCode => 'குறியீட்டை நகலெடு';

  @override
  String get inviteCodeValidity =>
      'ஏழு நாட்களுக்குச் செல்லுபடியாகும். நீங்கள் நம்புபவர்களுடன் மட்டும் பகிரவும்.';

  @override
  String get acceptInviteTitle => 'ஒருவரின் அழைப்பை ஏற்கவும்';

  @override
  String get inviteCode => 'அழைப்புக் குறியீடு';

  @override
  String get acceptInvitation => 'அழைப்பை ஏற்கவும்';

  @override
  String get invitationAccepted =>
      'அழைப்பு ஏற்கப்பட்டது. இப்போது நீங்கள் இணைக்கப்பட்டுள்ளீர்கள்; அவர்களின் SOS எச்சரிக்கைகளைப் பெறலாம்.';

  @override
  String get yourConnections => 'உங்கள் இணைப்புகள்';

  @override
  String get noConnectionsYet => 'இதுவரை இணைப்புகள் இல்லை';

  @override
  String get receivesYourSos => 'உங்கள் SOS எச்சரிக்கைகளைப் பெறுகிறார்';

  @override
  String get youReceiveTheirSos =>
      'அவர்களின் SOS எச்சரிக்கைகளை நீங்கள் பெறுகிறீர்கள்';

  @override
  String get removeConnection => 'இணைப்பை அகற்று';

  @override
  String get removeConnectionTitle => 'இணைப்பை அகற்றவா?';

  @override
  String get removeConnectionBody =>
      'இந்த இணைப்புக்கு இனி SOS அழைப்பு அழைப்பிதழ்கள் வராது.';

  @override
  String get contactsLoadFailedRetry =>
      'தொடர்புகளை ஏற்ற முடியவில்லை. மீண்டும் முயற்சி';

  @override
  String get callTitle => 'கெய்லோ SOS அழைப்பு';

  @override
  String get callEnded => 'அழைப்பு முடிந்தது';

  @override
  String get callYourCircle => 'உங்கள் நம்பகமான வட்டம்';

  @override
  String get callCouldNotConnect => 'இணைக்க முடியவில்லை';

  @override
  String get callConnecting => 'இணைக்கிறது…';

  @override
  String get callKeepOpen =>
      'அழைப்பின் போது கெய்லோவைத் திறந்தே வைத்திருக்கவும்.';

  @override
  String get retryCall => 'அழைப்பை மீண்டும் முயற்சி';

  @override
  String get callErrorRoom =>
      'இந்த அழைப்பு கிடைக்கவில்லை அல்லது முடிந்துவிட்டது. புதிய அழைப்பைத் தொடங்க SOS-க்குத் திரும்பவும்.';

  @override
  String get callErrorSettings =>
      'அழைப்பு அமைப்புகளை ஏற்ற முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get callErrorMicrophone =>
      'மைக்ரோஃபோனை அணுக முடியவில்லை. கெய்லோவிற்கான மைக்ரோஃபோன் அனுமதியைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get callErrorJoin =>
      'இந்த அழைப்பில் சேர முடியவில்லை. மீண்டும் முயற்சிக்கவும், அல்லது அழைத்தவரிடம் புதிய SOS அழைப்பைத் தொடங்கச் சொல்லவும்.';

  @override
  String get callInterrupted => 'இணைப்பு தடைபட்டது. மீண்டும் முயற்சிக்கிறது…';

  @override
  String get callPeerConnected => 'இணைக்கப்பட்டது';

  @override
  String get callPeerFailed => 'இணைப்பு தோல்வி';

  @override
  String get callPeerReconnecting => 'மீண்டும் இணைக்கிறது';

  @override
  String get callPeerConnecting => 'இணைக்கிறது';

  @override
  String get callYou => 'நீங்கள்';

  @override
  String get callYouMuted => 'நீங்கள் • ஒலியடக்கப்பட்டது';

  @override
  String get callInvitedWaiting =>
      'அழைக்கப்பட்டார் • பதிலுக்காகக் காத்திருக்கிறது';

  @override
  String get callDeclined => 'நிராகரித்தார்';

  @override
  String get callLeft => 'அழைப்பிலிருந்து வெளியேறினார்';

  @override
  String get mute => 'ஒலியடக்கு';

  @override
  String get unmute => 'ஒலி இயக்கு';

  @override
  String get speaker => 'ஸ்பீக்கர்';

  @override
  String get callAudioOutputFailed =>
      'ஒலி வெளியீட்டை மாற்ற முடியவில்லை. அழைப்பு இன்னும் செயலில் உள்ளது.';

  @override
  String get close => 'மூடு';

  @override
  String get callEndForEveryone => 'அனைவருக்கும் அழைப்பை முடி';

  @override
  String get callLeave => 'அழைப்பிலிருந்து வெளியேறு';

  @override
  String get prescriptionsLoadFailed =>
      'மருந்துச் சீட்டுகளை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get actionFailed => 'அந்தச் செயலை முடிக்க முடியவில்லை.';

  @override
  String get prescriptionSaveFailed =>
      'மருந்துச் சீட்டைச் சேமிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get prescriptionsHeadline => 'உங்கள் உடல்நலப் பதிவுகள், ஒரே இடத்தில்';

  @override
  String get prescriptionsIntro =>
      'மருந்துச் சீட்டை ஸ்கேன் செய்யவும் அல்லது பழைய பதிவைத் தட்டச்சு செய்யவும். PDF-கள் இந்தச் சாதனத்தில் தனிப்பட்ட முறையில் சேமிக்கப்படும்.';

  @override
  String get prescriptionsAndroidOnly =>
      'மருந்துச் சீட்டு ஸ்கேனிங்கும் PDF-களும் தற்போது Android செயலியில் கிடைக்கின்றன.';

  @override
  String get scanOrPhotos => 'ஸ்கேன் / படங்கள்';

  @override
  String get typeRecord => 'பதிவைத் தட்டச்சு செய்';

  @override
  String get searchPrescriptions => 'மருந்துச் சீட்டுகளைத் தேடு';

  @override
  String get noPrescriptionsYet => 'இதுவரை மருந்துச் சீட்டுகள் இல்லை';

  @override
  String get noMatchingPrescriptions => 'பொருந்தும் மருந்துச் சீட்டுகள் இல்லை';

  @override
  String get prescriptionNeedsTitleText =>
      'ஒரு தலைப்பையும் மருந்துச் சீட்டு விவரத்தையும் சேர்க்கவும்.';

  @override
  String get prescriptionRecord => 'மருந்துச் சீட்டுப் பதிவு';

  @override
  String get reviewPrescription => 'மருந்துச் சீட்டைச் சரிபார்';

  @override
  String get deletePrescription => 'மருந்துச் சீட்டை நீக்கு';

  @override
  String get deletePrescriptionTitle => 'மருந்துச் சீட்டை நீக்கவா?';

  @override
  String get deletePrescriptionBody =>
      'PDF மற்றும் உரை இந்தச் சாதனத்திலிருந்து அகற்றப்படும்.';

  @override
  String get delete => 'நீக்கு';

  @override
  String get prescriptionReviewHint =>
      'பிரித்தெடுக்கப்பட்ட உரையை அசல் சீட்டுடன் ஒப்பிட்டுப் பாருங்கள். கையெழுத்து முழுமையற்றதாகவோ தவறாகவோ இருக்கலாம்; மருந்துப் பெயர்களையும் அளவுகளையும் உங்கள் மருத்துவரிடம் உறுதிப்படுத்தவும்.';

  @override
  String get viewOriginalPdf => 'அசல் PDF-ஐப் பார்';

  @override
  String get titleLabel => 'தலைப்பு';

  @override
  String get extractedTextNotes => 'பிரித்தெடுத்த உரை / குறிப்புகள்';

  @override
  String get prescriptionDetails => 'மருந்துச் சீட்டு விவரங்கள்';

  @override
  String get prescriptionEditHint =>
      'இந்த உரையைத் திருத்தினாலும் அசல் ஸ்கேன் செய்த PDF மாறாது.';

  @override
  String get saving => 'சேமிக்கிறது…';

  @override
  String get savePrescription => 'மருந்துச் சீட்டைச் சேமி';

  @override
  String get openSavedPdf => 'சேமித்த PDF-ஐத் திற';

  @override
  String get shareSavedPdf => 'சேமித்த PDF-ஐப் பகிர்';

  @override
  String get deleteAccount => 'கணக்கை நீக்கு';

  @override
  String get deleteRequiresLive =>
      'கணக்கை நீக்க, உள்நுழைந்த நேரடி கணக்கு தேவை.';

  @override
  String get deleteNotConfirmed =>
      'நீக்கம் உறுதிப்படுத்தப்படவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get deleteFailed =>
      'கணக்கை நீக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get deleteAccountHeadline =>
      'உங்கள் கெய்லோ கணக்கை நிரந்தரமாக நீக்கவா?';

  @override
  String get deleteAccountBody =>
      'இது உங்கள் உள்நுழைவு, சுயவிவரம், முன்பதிவுகள், செய்திகள், பராமரிப்புப் பதிவுகள் மற்றும் இந்தச் சாதனத்தில் உள்ள மருந்துச் சீட்டுகளை அகற்றும். இதைத் திரும்பப் பெற முடியாது. செயலில் உள்ள முன்பதிவுகளை முதலில் முடிக்கவும் அல்லது ரத்து செய்யவும். தீர்க்கப்படாத கட்டணங்களுக்கு kayloapp@gmail.com-ஐத் தொடர்பு கொள்ளவும்.';

  @override
  String get deleteAccountNote =>
      'கட்டணச் சேவை நிறுவனங்கள் பரிவர்த்தனைப் பதிவுகளை வைத்திருக்கலாம். நீங்கள் முன்பு பகிர்ந்த ஆவணங்கள் பிறரின் சாதனங்களிலிருந்து அகற்றப்படாது.';

  @override
  String get typeDeleteToConfirm =>
      'உறுதிப்படுத்த DELETE எனத் தட்டச்சு செய்யவும்';

  @override
  String get deleting => 'நீக்குகிறது…';

  @override
  String get deleteMyAccount => 'என் கணக்கை நீக்கு';

  @override
  String get paymentVerified =>
      'கட்டணம் சரிபார்க்கப்பட்டது. உங்கள் முன்பதிவு உறுதியானது.';

  @override
  String get paymentNotCompleted => 'கட்டணம் நிறைவடையவில்லை.';

  @override
  String get checkoutOpenFailed =>
      'பாதுகாப்பான செக்அவுட்டைத் திறக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get cardsAndUpi => 'கார்டுகள் மற்றும் UPI';

  @override
  String get paymentMethodsBody =>
      'பாதுகாப்பான Razorpay செக்அவுட்டில் கார்டு விவரங்களை உள்ளிடவும் அல்லது UPI-ஐத் தேர்ந்தெடுக்கவும். வசதி இருந்தால், அந்தக் கார்டை மீண்டும் பயன்படுத்த Razorpay-இன் கார்டு சேமிப்பு விருப்பத்தைத் தேர்ந்தெடுக்கவும். சேமித்த கார்டுகள் செக்அவுட்டிலேயே நிர்வகிக்கப்படும்.';

  @override
  String get paymentMethodsNote =>
      'கெய்லோ உங்கள் முழு கார்டு எண், CVV அல்லது PIN-ஐச் சேமிப்பதில்லை. தற்போதைய கட்டண அமைப்பில் NFC மூலம் கார்டு சேர்க்கும் வசதி இல்லை.';

  @override
  String get completePendingPayment => 'நிலுவையில் உள்ள கட்டணத்தை முடிக்கவும்';

  @override
  String get noPendingPayments =>
      'உங்கள் அடுத்த முன்பதிவில் செக்அவுட் திறக்கும்; அங்கே கார்டைச் சேர்க்கலாம் அல்லது தேர்ந்தெடுக்கலாம்.';

  @override
  String pendingBookingLine(String id, String date) {
    return 'முன்பதிவு $id • $date';
  }

  @override
  String get bookingsLoadFailedRetry =>
      'முன்பதிவுகளை ஏற்ற முடியவில்லை. மீண்டும் முயற்சி';

  @override
  String get openingPayment => 'கட்டணப் பக்கம் திறக்கிறது…';

  @override
  String get payAndBook => 'பணம் செலுத்தி முன்பதிவு செய்';

  @override
  String get appointmentPaymentFailed =>
      'கட்டணத்தை முடிக்க முடியவில்லை. உங்கள் சந்திப்பு உறுதியாகவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get visitPaymentFailed =>
      'கட்டணத்தை முடிக்க முடியவில்லை. உங்கள் வருகை உறுதியாகவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get careServiceUnavailable =>
      'இந்தப் பராமரிப்புச் சேவை கிடைக்கவில்லை.';

  @override
  String get appointmentNotConfirmed =>
      'கட்டணம் நிறைவடையவில்லை. உங்கள் சந்திப்பு உறுதியாகவில்லை.';

  @override
  String get hapticFeedback => 'தொடு உணர்வு';

  @override
  String get soundEffects => 'ஒலி விளைவுகள்';

  @override
  String get voiceStarting => 'மைக்ரோஃபோன் தொடங்குகிறது…';

  @override
  String get ocrNeedsReview =>
      'சில எழுத்துகளைப் படிக்க முடியவில்லை. அசல் ஸ்கேனைப் பார்த்து குறிப்புகளைத் திருத்தவும்.';

  @override
  String get allBookings => 'அனைத்து முன்பதிவுகளும்';

  @override
  String get noCompletedBookings => 'முடிந்த முன்பதிவுகள் இன்னும் இல்லை';

  @override
  String get noCompletedBookingsDescription =>
      'வேலை முடிந்ததும் உங்கள் முன்பதிவுகள் இங்கே தோன்றும்.';

  @override
  String get verificationRecord => 'சரிபார்ப்பு பதிவு';

  @override
  String get refreshVerification => 'சரிபார்ப்பு நிலையைப் புதுப்பிக்கவும்';

  @override
  String get verificationLoadError =>
      'தற்போதைய சரிபார்ப்பு நிலையை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get kayloVerified => 'Kaylo-வில் சரிபார்க்கப்பட்டது';

  @override
  String get notYetVerified => 'இன்னும் சரிபார்க்கப்படவில்லை';

  @override
  String get viewVerification => 'சரிபார்ப்பு பதிவைப் பார்க்கவும்';

  @override
  String get verificationRecorded =>
      'இந்த நிபுணரின் சுயவிவரம் Kaylo-வில் சரிபார்க்கப்பட்டதாகப் பதிவாகியுள்ளது.';

  @override
  String get verificationNotRecorded =>
      'இந்தச் சுயவிவரத்தில் சரிபார்க்கப்பட்ட நிலை பதிவாகவில்லை.';

  @override
  String get listedServices => 'பட்டியலிடப்பட்ட சேவைகள்';

  @override
  String get profileReference => 'சுயவிவரக் குறிப்பு';

  @override
  String get serviceArea => 'சேவைப் பகுதி';

  @override
  String get verificationScope =>
      'இந்தப் பதிவு சுயவிவரத்தின் தற்போதைய நிலையைக் காட்டுகிறது. ஆதார ஆவணங்களும் சரிபார்ப்பு விவரங்களும் கிடைக்கவில்லை. இது அரசு உரிமமோ தொழில்முறைத் தகுதியோ அல்ல.';

  @override
  String get selectOnMap => 'வரைபடத்தில் தேர்ந்தெடுக்கவும்';

  @override
  String get chooseAddress => 'முகவரியைத் தேர்ந்தெடுக்கவும்';
}
