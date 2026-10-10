// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Kaylo Partner';

  @override
  String get refreshJobsTooltip => 'नौकरियों को रिफ्रेश करें';

  @override
  String get tabJobs => 'नौकरियां';

  @override
  String get tabEarnings => 'कमाई';

  @override
  String get tabProfile => 'प्रोफ़ाइल';

  @override
  String get dutyOnline => 'आप ऑनलाइन हैं';

  @override
  String get dutyOffline => 'आप ऑफ़लाइन हैं';

  @override
  String dutyTakingOrders(String district) {
    return '$district में ऑर्डर ले रहे हैं';
  }

  @override
  String get dutyNotReceivingRequests => 'अनुरोध प्राप्त नहीं कर रहे हैं';

  @override
  String get todaysPay => 'आज की कमाई';

  @override
  String get jobsToday => 'आज की नौकरियां';

  @override
  String get rating => 'रेटिंग';

  @override
  String get activeJob => 'सक्रिय नौकरी';

  @override
  String get offlineTitle => 'आप ऑफ़लाइन हैं';

  @override
  String get offlineDescription =>
      'आस-पास के ग्राहकों से नौकरी के अनुरोध प्राप्त करने के लिए अपनी ड्यूटी स्थिति को ऑनलाइन में बदलें।';

  @override
  String newRequests(int count) {
    return 'नए अनुरोध ($count)';
  }

  @override
  String get searchingForRequests => 'अनुरोधों की खोज कर रहे हैं...';

  @override
  String get searchingForRequestsSubtitle =>
      'जब कोई आस-पास का ग्राहक बुक करेगा तो आपको एक पिंग सुनाई देगी।';

  @override
  String get payout => 'भुगतान';

  @override
  String get decline => 'अस्वीकार करें';

  @override
  String get acceptJob => 'नौकरी स्वीकार करें';

  @override
  String get stageRequested => 'अनुरोध किया गया';

  @override
  String get stageAccepted => 'स्वीकार किया गया';

  @override
  String get stageOnTheWay => 'रास्ते में';

  @override
  String get stageArrived => 'पहुंच गए';

  @override
  String get stageInProgress => 'प्रगति पर';

  @override
  String get stageCompleted => 'पूरा हुआ';

  @override
  String get stageCancelled => 'रद्द किया गया';

  @override
  String get actionAccept => 'स्वीकार करें';

  @override
  String get actionStartTravel => 'यात्रा शुरू करें';

  @override
  String get actionArrived => 'मैं पहुंच गया हूं';

  @override
  String get actionStartJob => 'नौकरी शुरू करें';

  @override
  String get actionCompleteJob => 'नौकरी पूरी करें';

  @override
  String get languageSettings => 'भाषा सेटिंग्स';

  @override
  String get profileLanguageTile => 'भाषा';

  @override
  String get appSettingsHeader => 'ऐप सेटिंग्स';

  @override
  String get profileTitle => 'पार्टनर प्रोफ़ाइल';

  @override
  String get editProfile => 'प्रोफ़ाइल बदलें';

  @override
  String get verifiedPartner => 'सत्यापित पार्टनर';

  @override
  String get verificationUnderReview => 'सत्यापन जारी है';

  @override
  String get verificationRejected => 'सत्यापन अस्वीकृत';

  @override
  String get verificationNotStarted => 'अभी सत्यापित नहीं';

  @override
  String get performanceHeader => 'प्रदर्शन और रेटिंग';

  @override
  String get totalJobs => 'कुल काम';

  @override
  String reviewsCount(int count) {
    return '$count समीक्षाएँ';
  }

  @override
  String memberSince(String date) {
    return '$date से';
  }

  @override
  String get offeredServicesHeader => 'आपकी सेवाएँ';

  @override
  String get noServicesYet => 'अभी कोई सेवा नहीं जोड़ी गई';

  @override
  String get payoutHeader => 'भुगतान खाता';

  @override
  String upiLabel(String upi) {
    return 'UPI ID: $upi';
  }

  @override
  String get noPayoutYet => 'अभी कोई भुगतान खाता नहीं';

  @override
  String get bankChangeNote =>
      'बैंक खाते में बदलाव सहायता टीम के ज़रिए होते हैं';

  @override
  String get verificationHeader => 'KYC और सत्यापन';

  @override
  String get documentAadhaar => 'आधार कार्ड';

  @override
  String get documentPoliceCertificate => 'पुलिस क्लीयरेंस प्रमाणपत्र';

  @override
  String get statusVerified => 'सत्यापित';

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusRejected => 'अस्वीकृत';

  @override
  String get statusNotSubmitted => 'जमा नहीं किया';

  @override
  String get areaScheduleHeader => 'सेवा क्षेत्र और समय';

  @override
  String travelRadius(String km) {
    return '$km किमी के दायरे में';
  }

  @override
  String get noDistrictYet => 'सेवा क्षेत्र तय नहीं';

  @override
  String get hoursNotSet => 'काम के घंटे तय नहीं';

  @override
  String get customHours => 'अलग-अलग दिनों में अलग घंटे';

  @override
  String get manageAvailability => 'उपलब्धता बदलें';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get logOutTitle => 'लॉग आउट करें?';

  @override
  String get logOutBody =>
      'काम पाने के लिए आपको अपने फ़ोन नंबर से फिर से साइन इन करना होगा।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get notRegisteredTitle => 'अपना पंजीकरण पूरा करें';

  @override
  String get notRegisteredBody =>
      'आपकी वर्कर प्रोफ़ाइल अभी तैयार नहीं है। काम पाने के लिए पंजीकरण पूरा करें।';

  @override
  String get profileLoadFailed => 'आपकी प्रोफ़ाइल लोड नहीं हो सकी';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get editProfileTitle => 'प्रोफ़ाइल बदलें';

  @override
  String get fullNameLabel => 'पूरा नाम';

  @override
  String get districtLabel => 'ज़िला';

  @override
  String get travelRadiusLabel => 'यात्रा दायरा (किमी)';

  @override
  String get upiIdLabel => 'UPI ID';

  @override
  String get servicesLabel => 'आपकी सेवाएँ';

  @override
  String get save => 'सहेजें';

  @override
  String get profileSaved => 'प्रोफ़ाइल अपडेट हो गई';

  @override
  String get nameRequired => 'अपना नाम लिखें';

  @override
  String get chooseOneService => 'कम से कम एक सेवा चुनें';

  @override
  String get invalidUpi => 'सही UPI ID लिखें, जैसे name@bank';

  @override
  String get radiusRange => '1 से 100 किमी के बीच दायरा लिखें';

  @override
  String get dutyUpdateFailed => 'आपकी उपलब्धता अपडेट नहीं हो सकी';

  @override
  String get dutyTakingOrdersAnywhere => 'काम के अनुरोध ले रहे हैं';

  @override
  String get availabilityTitle => 'मेरी उपलब्धता';

  @override
  String get workingHoursHeader => 'काम के घंटे';

  @override
  String get workingHoursHint =>
      'ग्राहक आपको केवल इन घंटों में बुक कर सकते हैं।';

  @override
  String get dayOff => 'छुट्टी';

  @override
  String get saveHours => 'घंटे सहेजें';

  @override
  String get hoursSaved => 'काम के घंटे सहेज लिए गए';

  @override
  String get endAfterStart => 'समाप्ति समय शुरुआत के बाद होना चाहिए';

  @override
  String get daysOffHeader => 'छुट्टी के दिन';

  @override
  String get daysOffHint => 'इन दिनों ग्राहक आपको बुक नहीं कर सकते।';

  @override
  String get addDaysOff => 'छुट्टी जोड़ें';

  @override
  String get noDaysOff => 'कोई छुट्टी तय नहीं';

  @override
  String get reasonLabel => 'कारण (वैकल्पिक)';

  @override
  String get reasonHint => 'त्योहार, यात्रा, परिवार…';

  @override
  String get timeOffAdded => 'छुट्टी जोड़ दी गई';

  @override
  String get timeOffRemoved => 'छुट्टी हटा दी गई';

  @override
  String get remove => 'हटाएँ';

  @override
  String get add => 'जोड़ें';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String dateRange(String from, String to) {
    return '$from से $to';
  }
}
