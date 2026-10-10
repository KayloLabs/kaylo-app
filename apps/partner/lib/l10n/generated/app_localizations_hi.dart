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
      'फिर साइन इन करने के लिए पार्टनर आईडी और पासवर्ड चाहिए।';

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

  @override
  String get authSubtitle => 'Kaylo से मिले पार्टनर आईडी से साइन इन करें।';

  @override
  String get authSignIn => 'साइन इन करें';

  @override
  String get authPartnerId => 'पार्टनर आईडी';

  @override
  String get authPassword => 'पासवर्ड';

  @override
  String get authShowPassword => 'पासवर्ड दिखाएँ';

  @override
  String get authHidePassword => 'पासवर्ड छिपाएँ';

  @override
  String get authForgotPassword => 'पासवर्ड भूल गए? Kaylo से संपर्क करें';

  @override
  String get authSupport => 'Kaylo सहायता से संपर्क करें';

  @override
  String get authApply => 'पार्टनर बनने के लिए आवेदन करें';

  @override
  String get authCheckStatus => 'आवेदन की स्थिति देखें';

  @override
  String get authDemoCredentials => 'डेमो: KP-000123 / kaylo123';

  @override
  String get authInvalidId => 'KP-000123 जैसी मान्य पार्टनर आईडी दर्ज करें।';

  @override
  String get authInvalidCredentials => 'पार्टनर आईडी या पासवर्ड गलत है।';

  @override
  String get authTooManyAttempts =>
      'बहुत अधिक प्रयास हुए। थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get authNetworkError => 'इंटरनेट कनेक्शन जाँचकर फिर कोशिश करें।';

  @override
  String get authUnavailableTitle => 'खाते की जाँच नहीं हो सकी';

  @override
  String get authUnavailable =>
      'आपके पार्टनर एक्सेस की जाँच नहीं हो सकी। फिर कोशिश करें या Kaylo सहायता से संपर्क करें।';

  @override
  String get authPasswordRule => 'नए पासवर्ड में कम से कम 12 अक्षर रखें।';

  @override
  String get authDifferentPassword => 'अस्थायी पासवर्ड से अलग पासवर्ड चुनें।';

  @override
  String get authSessionExpired =>
      'सत्र समाप्त हो गया। लॉग आउट करके फिर साइन इन करें।';

  @override
  String get authPasswordConfirmation =>
      'पासवर्ड बदलाव की पुष्टि बाकी है। सुरक्षित रूप से फिर प्रयास करने के लिए पासवर्ड सहेजें दबाएँ।';

  @override
  String get authIdentityNotAllowed =>
      'Kaylo से मिली पार्टनर आईडी और पासवर्ड का उपयोग करें। ग्राहक खाते यहाँ साइन इन नहीं कर सकते।';

  @override
  String get authChangePassword => 'अपना पासवर्ड बनाएँ';

  @override
  String get authChangePasswordBody =>
      'पार्टनर खाता खोलने से पहले अस्थायी पासवर्ड बदलें।';

  @override
  String get authNewPassword => 'नया पासवर्ड';

  @override
  String get authConfirmPassword => 'नए पासवर्ड की पुष्टि करें';

  @override
  String get authSavePassword => 'पासवर्ड सहेजें';

  @override
  String get authPasswordMismatch => 'पासवर्ड मेल नहीं खाते।';

  @override
  String get authNotIssuedBody =>
      'इस खाते के लिए वर्कर प्रोफ़ाइल जारी नहीं हुई है। Kaylo में आवेदन करें या अपने आवेदन के बारे में सहायता लें।';

  @override
  String get authVerificationBody =>
      'Kaylo द्वारा सत्यापन मंज़ूर होने के बाद काम मिलेंगे। आप प्रोफ़ाइल देख सकते हैं या सहायता ले सकते हैं।';

  @override
  String get partnerJobNotifications => 'काम के अनुरोध';

  @override
  String get partnerNewJobRequest => 'नया काम अनुरोध';

  @override
  String get partnerOpenJobRequest =>
      'अनुरोध देखने के लिए Kaylo Partner खोलें।';

  @override
  String get applicationTitle => 'Kaylo में आवेदन करें';

  @override
  String get applicationPersonal => 'आपके बारे में';

  @override
  String get applicationSkills => 'आपका काम और सेवा क्षेत्र';

  @override
  String get applicationDocuments => 'आपके दस्तावेज़';

  @override
  String get applicationPayout => 'भुगतान और सहमति';

  @override
  String applicationStep(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get applicationIntro =>
      'बिना खाते के आवेदन करें। पार्टनर लॉगिन देने से पहले Kaylo आपके विवरण और दस्तावेज़ों की समीक्षा करेगा।';

  @override
  String get applicationPhone => 'फ़ोन नंबर';

  @override
  String get applicationEmail => 'ईमेल पता';

  @override
  String get applicationEmailHint =>
      'ऐसा ईमेल दें जिसे आप खोल सकें। स्वीकृति के बाद Kaylo आपकी पार्टनर ID और अस्थायी पासवर्ड यहाँ भेजेगा।';

  @override
  String get applicationInvalidPhone => 'देश कोड के साथ सही फ़ोन नंबर दें';

  @override
  String get applicationInvalidEmail => 'सही ईमेल पता दें';

  @override
  String get applicationProfession => 'पेशा';

  @override
  String get applicationProfessionRequired => 'अपना पेशा बताएं';

  @override
  String get applicationExperience => 'अनुभव (वर्ष)';

  @override
  String get applicationInvalidExperience =>
      '0 से 60 वर्ष के बीच अनुभव दर्ज करें';

  @override
  String get applicationChooseDistrict => 'अपना ज़िला चुनें';

  @override
  String get applicationNoServices =>
      'सेवा सूची अभी उपलब्ध नहीं है। कृपया बाद में फिर प्रयास करें।';

  @override
  String get applicationDocumentsHint =>
      'पाँचों दस्तावेज़ जोड़ें। फ़ोटो के लिए JPG या PNG; अन्य दस्तावेज़ों के लिए JPG, PNG या PDF। प्रति फ़ाइल अधिकतम 10 MB।';

  @override
  String get applicationDocumentsPrivacy =>
      'दस्तावेज़ Kaylo की समीक्षा के लिए निजी रूप से अपलोड होते हैं। सार्वजनिक स्थिति खोज में वे नहीं दिखते।';

  @override
  String get applicationPhoto => 'प्रोफ़ाइल फ़ोटो';

  @override
  String get applicationAadhaarFront => 'आधार का अगला भाग';

  @override
  String get applicationAadhaarBack => 'आधार का पिछला भाग';

  @override
  String get applicationSelfie => 'सेल्फ़ी';

  @override
  String get applicationChooseFile => 'फ़ाइल चुनें';

  @override
  String get applicationAllDocuments =>
      'आगे बढ़ने के लिए पाँचों दस्तावेज़ जोड़ें';

  @override
  String get applicationUpi => 'UPI';

  @override
  String get applicationBank => 'बैंक खाता';

  @override
  String get applicationAccountHolder => 'खाताधारक का नाम';

  @override
  String get applicationBankName => 'बैंक का नाम';

  @override
  String get applicationAccountNumber => 'खाता नंबर';

  @override
  String get applicationConfirmAccount => 'खाता नंबर फिर दर्ज करें';

  @override
  String get applicationIfsc => 'IFSC कोड';

  @override
  String get applicationBankRequired => 'बैंक विवरण दर्ज करें';

  @override
  String get applicationInvalidAccount => '9 से 18 अंकों का खाता नंबर दें';

  @override
  String get applicationAccountMismatch => 'खाता नंबर मेल नहीं खाते';

  @override
  String get applicationInvalidIfsc => '11 अक्षरों का सही IFSC कोड दें';

  @override
  String get applicationReviewHint => 'भेजने से पहले अपने विवरण जाँच लें।';

  @override
  String get applicationConsent =>
      'मैं पुष्टि करता/करती हूँ कि ये विवरण मेरे और सही हैं। पार्टनर सत्यापन के लिए Kaylo द्वारा मेरे विवरण और दस्तावेज़ों को सहेजने और जाँचने की सहमति देता/देती हूँ।';

  @override
  String get applicationConsentRequired => 'जमा करने से पहले सहमति दें';

  @override
  String get applicationKeepOpen =>
      'सभी दस्तावेज़ अपलोड होने तक Kaylo खुला रखें। कनेक्शन टूटे तो नया आवेदन बनाने के बजाय यहीं फिर प्रयास करें।';

  @override
  String get applicationBack => 'पीछे';

  @override
  String get applicationContinue => 'आगे बढ़ें';

  @override
  String get applicationSubmit => 'आवेदन जमा करें';

  @override
  String get applicationSending => 'अपना आवेदन भेजना पूरा करें';

  @override
  String get applicationRecoveryHint =>
      'पाँचों दस्तावेज़ मिलने पर ही आवेदन समीक्षा के लिए तैयार होता है। फिर प्रयास करने पर वही आवेदन जारी रहेगा। पूरा होने से पहले ऐप बंद कर दें तो संदर्भ नंबर के साथ Kaylo से संपर्क करें।';

  @override
  String get applicationReference => 'आवेदन संदर्भ';

  @override
  String applicationUploadProgress(int count, int total) {
    return '$total में से $count दस्तावेज़ प्राप्त';
  }

  @override
  String get applicationCheckStatus => 'आवेदन की स्थिति देखें';

  @override
  String get applicationBackToSignIn => 'साइन इन पर वापस जाएँ';

  @override
  String get applicationStatusHint =>
      'स्थिति देखने के लिए आवेदन संदर्भ दर्ज करें। यहाँ निजी विवरण और दस्तावेज़ कभी नहीं दिखाए जाते।';

  @override
  String get applicationInvalidReference => 'अपने आवेदन का संदर्भ दर्ज करें';

  @override
  String get applicationUnderReview => 'आवेदन की समीक्षा जारी है';

  @override
  String get applicationUnderReviewHint =>
      'आपके विवरण और पाँचों दस्तावेज़ मिल गए हैं। निर्णय से पहले Kaylo उनकी समीक्षा करेगा। यह संदर्भ पार्टनर लॉगिन नहीं है।';

  @override
  String get applicationIncomplete => 'दस्तावेज़ अभी बाकी हैं';

  @override
  String get applicationIncompleteHint =>
      'आपके विवरण मिल गए हैं, लेकिन दस्तावेज़ अपलोड पूरे नहीं हुए। इसी ऐप सत्र से जारी रखें या संदर्भ के साथ Kaylo से सहायता लें।';

  @override
  String get applicationApproved => 'आवेदन स्वीकृत';

  @override
  String get applicationApprovedHint =>
      'स्वीकृति के बाद Kaylo आपके ईमेल पर पार्टनर ID और अस्थायी पासवर्ड भेजता है। वे न मिले हों तो सहायता से संपर्क करें। पहली बार साइन इन पर नया पासवर्ड बनाना होगा।';

  @override
  String get applicationRejected => 'आवेदन स्वीकृत नहीं हुआ';

  @override
  String get applicationRejectedHint =>
      'Kaylo ने इस आवेदन को स्वीकृत नहीं किया है। इसके लिए पार्टनर लॉगिन उपलब्ध नहीं है। सहायता के लिए संदर्भ के साथ संपर्क करें।';

  @override
  String get applicationCopyReference => 'संदर्भ कॉपी करें';

  @override
  String get applicationReferenceCopied => 'संदर्भ कॉपी हो गया';

  @override
  String get applicationResumeUpload => 'दस्तावेज़ अपलोड जारी रखें';

  @override
  String get applicationContactSupport => 'Kaylo सहायता से संपर्क करें';

  @override
  String applicationSupportSubject(String reference) {
    return 'पार्टनर आवेदन सहायता: $reference';
  }

  @override
  String get applicationSupportHint =>
      'अपने आवेदन संदर्भ के साथ kayloapp@gmail.com पर ईमेल करें।';

  @override
  String get applicationDemoNotice =>
      'नमूना मोड: यह आवेदन इसी ऐप सत्र में रहता है, Kaylo को नहीं भेजा जाता।';

  @override
  String get applicationConnectionError =>
      'कनेक्ट नहीं हो सका। इंटरनेट जाँचकर फिर प्रयास करें।';

  @override
  String get applicationAlreadyOpen =>
      'इस फ़ोन नंबर का आवेदन पहले से खुला है। उसकी स्थिति देखें या Kaylo सहायता से संपर्क करें।';

  @override
  String get applicationInvalidDetails => 'कृपया अपने आवेदन विवरण जाँचें।';

  @override
  String get applicationInvalidDocument =>
      '10 MB तक की सही JPG, PNG या PDF फ़ाइल चुनें। प्रोफ़ाइल फ़ोटो और सेल्फ़ी चित्र होने चाहिए।';

  @override
  String get applicationUploadExpired =>
      'अपलोड सत्र अब उपलब्ध नहीं है। आवेदन पूरा करने के लिए संदर्भ के साथ Kaylo से संपर्क करें।';

  @override
  String get applicationNotFound =>
      'इस संदर्भ का आवेदन नहीं मिला। संदर्भ जाँचकर फिर प्रयास करें।';

  @override
  String get applicationUnavailable =>
      'आवेदन सेवा अभी उपलब्ध नहीं है। बाद में प्रयास करें या Kaylo सहायता से संपर्क करें।';

  @override
  String get applicationIdentityInUse =>
      'यह फ़ोन या ईमेल पहले से किसी Kaylo खाते में उपयोग हो रहा है। इस पहचान से आवेदन करने से पहले सहायता से संपर्क करें।';

  @override
  String get liveJobsPending =>
      'लाइव काम के अनुरोध और कमाई अभी उपलब्ध नहीं हैं। आपकी प्रोफ़ाइल और उपलब्धता उपयोग के लिए तैयार हैं।';
}
