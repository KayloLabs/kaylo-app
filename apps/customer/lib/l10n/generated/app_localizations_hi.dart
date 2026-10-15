// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String sosCallWaiting(String name) {
    return 'अगला: $name। Kaylo में 3 सेकंड बाद कॉल शुरू होगी।';
  }

  @override
  String sosCallProgress(int attempted, int total) {
    return '$total में से $attempted कॉल करने का प्रयास किया';
  }

  @override
  String get sosCallsFinished =>
      'कॉल क्रम पूरा हुआ। कॉल का प्रयास यह पुष्टि नहीं करता कि किसी ने जवाब दिया।';

  @override
  String get sosCallsStopped =>
      'बाकी कॉल रोक दी गई हैं। चल रही कॉल फोन ऐप में समाप्त करें।';

  @override
  String get sosStopCalls => 'बाकी कॉल रोकें';

  @override
  String get sosAndroidOnly => 'SIM कॉलिंग Android फोन पर उपलब्ध है।';

  @override
  String careDosesTaken(int taken, int total) {
    return '$total में से $taken खुराक ली गई';
  }

  @override
  String get hello => 'नमस्ते';

  @override
  String get searchServices => 'सेवाएं खोजें…';

  @override
  String get whatDoYouNeedHelpWith => 'आपको किस मदद की ज़रूरत है?';

  @override
  String get home => 'घर';

  @override
  String get homeSubtitle => 'आपके घर के लिए\nसमाधान।';

  @override
  String get farm => 'खेत';

  @override
  String get farmSubtitle => 'आपके खेत के लिए\nदेखभाल और समर्थन।';

  @override
  String get care => 'देखभाल';

  @override
  String get careSubtitle => 'आपके प्रियजनों के लिए\nमदद।';

  @override
  String get popularServices => 'लोकप्रिय सेवाएं';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String get howCanWeHelp => 'आज हम आपकी कैसे मदद कर सकते हैं?';

  @override
  String get heroCoconutTitle => 'नारियल तोड़ना\nअब हुआ आसान';

  @override
  String get heroCoconutSubtitle =>
      'अपने क्षेत्र के\nविश्वसनीय लोगों को बुक करें';

  @override
  String get heroCleanTitle => 'आज ही अपना\nघर साफ करें';

  @override
  String get heroCleanSubtitle => 'आपके दरवाजे पर\nपेशेवर सेवाएं';

  @override
  String get heroPlumberTitle => 'विशेषज्ञ प्लंबर और\nकिसान तैयार हैं';

  @override
  String get heroPlumberSubtitle => 'हर काम के लिए\nविश्वसनीय सहायक';

  @override
  String get heroBookNow => 'अभी बुक करें';

  @override
  String get heroExplore => 'खोजें';

  @override
  String get heroHireNow => 'अभी काम पर रखें';

  @override
  String get promoTitle => 'महत्वपूर्ण काम कभी न चूकें';

  @override
  String get promoSubtitle => 'रिमाइंडर सेट करें, बाकी\nहम संभाल लेंगे।';

  @override
  String get promoButton => 'रिमाइंडर सेट करें';

  @override
  String get recommendedForYou => 'आपके लिए अनुशंसित';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get appearance => 'दिखावट';

  @override
  String get theme => 'थीम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get language => 'भाषा';

  @override
  String get accessibility => 'सुगम्यता';

  @override
  String get careModeTitle => 'कायलो केयर मोड';

  @override
  String get careModeSubtitle => 'बुज़ुर्गों के लिए बड़े अक्षर और सरल स्क्रीन';

  @override
  String get notifications => 'सूचनाएँ';

  @override
  String get pushNotifications => 'पुश सूचनाएँ';

  @override
  String get pushNotificationsSubtitle => 'बुकिंग अपडेट और ऑफ़र';

  @override
  String get about => 'ऐप के बारे में';

  @override
  String get version => 'संस्करण';

  @override
  String get termsPrivacy => 'नियम और गोपनीयता';

  @override
  String get madeInKerala => 'केरल में ♥ से बनाया गया';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get statBookings => 'बुकिंग';

  @override
  String get statRating => 'रेटिंग';

  @override
  String get statSaved => 'सहेजे गए';

  @override
  String get account => 'खाता';

  @override
  String get myBookings => 'मेरी बुकिंग';

  @override
  String get myBookingsSubtitle => 'अपनी सेवाएँ ट्रैक और प्रबंधित करें';

  @override
  String get savedAddresses => 'सहेजे गए पते';

  @override
  String get paymentMethods => 'भुगतान के तरीके';

  @override
  String get preferences => 'प्राथमिकताएँ';

  @override
  String get settingsSubtitle => 'थीम, भाषा, केयर मोड, सूचनाएँ';

  @override
  String get support => 'सहायता';

  @override
  String get helpSupport => 'मदद और सहायता';

  @override
  String get rateKaylo => 'कायलो को रेट करें';

  @override
  String get rateThanks => 'प्यार के लिए धन्यवाद!';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get logOutConfirmTitle => 'लॉग आउट करें?';

  @override
  String get logOutConfirmMessage =>
      'सेवाएँ बुक करने के लिए आपको फिर से साइन इन करना होगा।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get profileEditSoon => 'साइन-इन के साथ प्रोफ़ाइल संपादन आएगा';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get firstName => 'पहला नाम';

  @override
  String get lastName => 'अंतिम नाम';

  @override
  String get profileUpdated => 'प्रोफ़ाइल अपडेट हो गई';

  @override
  String get statCompleted => 'पूर्ण';

  @override
  String get kayloCare => 'कायलो केयर';

  @override
  String get careHomeGreeting => 'आज हम आपकी देखभाल कैसे करें?';

  @override
  String get medicineReminders => 'दवा रिमाइंडर';

  @override
  String get medicineRemindersSubtitle => 'कोई खुराक न छूटे';

  @override
  String get doctorAppointment => 'डॉक्टर अपॉइंटमेंट';

  @override
  String get doctorAppointmentSubtitle => 'विज़िट या टेलीकंसल्ट बुक करें';

  @override
  String get emergencySos => 'आपातकालीन SOS';

  @override
  String get emergencySosSubtitle => 'परिवार को तुरंत सूचित करें';

  @override
  String get caregiverBooking => 'देखभालकर्ता बुक करें';

  @override
  String get caregiverBookingSubtitle => 'घर पर भरोसेमंद मदद';

  @override
  String get themeCareOverride =>
      'केयर मोड चालू रहने पर थीम उसी के अनुसार रहेगी';

  @override
  String get languageSettings => 'भाषा सेटिंग्स';

  @override
  String get voiceSearch => 'वॉइस खोज';

  @override
  String get voiceListening => 'सुन रहे हैं…';

  @override
  String get voiceTapToSpeak => 'अब बोलिए, किसी भी ऐप भाषा में';

  @override
  String get voiceYouSaid => 'आपने कहा';

  @override
  String get voiceNoMatch => 'कोई मिलती सेवा नहीं मिली। फिर से कोशिश करें?';

  @override
  String get voiceUnavailable => 'इस डिवाइस पर वॉइस खोज उपलब्ध नहीं है';

  @override
  String get voiceTryAgain => 'फिर से कोशिश करें';

  @override
  String get voiceMicDenied =>
      'माइक्रोफ़ोन की अनुमति नहीं मिली। वॉइस खोज के लिए ब्राउज़र या फ़ोन सेटिंग्स में अनुमति दें।';

  @override
  String get homeServices => 'घरेलू सेवाएं';

  @override
  String get allHomeServices => 'सभी घरेलू सेवाएं';

  @override
  String get exploreHomeServices => 'सत्यापित पेशेवरों को खोजें';

  @override
  String get serviceDetails => 'सेवा विवरण';

  @override
  String get professionalAtDoorstep => 'आपके दरवाजे पर पेशेवर सेवाएं';

  @override
  String get popularSubServices => 'लोकप्रिय उप-सेवाएं';

  @override
  String get selectSubServices => 'उप-सेवाएं चुनें';

  @override
  String get startingFrom => 'शुरुआती मूल्य';

  @override
  String get bookNow => 'अभी बुक करें';

  @override
  String get bookService => 'सेवा बुक करें';

  @override
  String get workersAvailable => 'सहायक उपलब्ध हैं';

  @override
  String get availableWorkers => 'उपलब्ध पेशेवर';

  @override
  String get sortAndFilter => 'क्रमबद्ध करें और फ़िल्टर';

  @override
  String get sortBy => 'इसके अनुसार क्रमबद्ध करें';

  @override
  String get rating => 'रेटिंग';

  @override
  String get priceLowToHigh => 'मूल्य: कम से अधिक';

  @override
  String get priceHighToLow => 'मूल्य: अधिक से कम';

  @override
  String get experience => 'अनुभव';

  @override
  String get distance => 'दूरी';

  @override
  String get filter => 'फ़िल्टर';

  @override
  String get priceRange => 'मूल्य सीमा';

  @override
  String get availability => 'उपलब्धता';

  @override
  String get availableToday => 'आज उपलब्ध';

  @override
  String get minRating => 'न्यूनतम रेटिंग';

  @override
  String get verifiedOnly => 'केवल सत्यापित';

  @override
  String get apply => 'लागू करें';

  @override
  String get reset => 'रीसेट';

  @override
  String get noWorkersFound => 'कोई पेशेवर नहीं मिला';

  @override
  String get workerProfile => 'प्रोफ़ाइल';

  @override
  String get completedJobs => 'पूर्ण किए गए कार्य';

  @override
  String get yearsExperience => 'वर्षों का अनुभव';

  @override
  String get trustScore => 'विश्वसनीयता स्कोर';

  @override
  String get responseTime => 'प्रतिक्रिया समय';

  @override
  String get certifications => 'प्रमाणपत्र';

  @override
  String get reviews => 'समीक्षाएं';

  @override
  String get customerReviews => 'ग्राहक समीक्षाएं';

  @override
  String get verifiedProfessional => 'सत्यापित पेशेवर';

  @override
  String get searchServicesOrWorkers => 'सेवाएं या पेशेवर खोजें…';

  @override
  String get recentSearches => 'हाल की खोजें';

  @override
  String get clearAll => 'सभी हटाएं';

  @override
  String get services => 'सेवाएं';

  @override
  String get professionals => 'पेशेवर';

  @override
  String get noResultsFound => 'कोई परिणाम नहीं मिला';

  @override
  String get tryDifferentSearch =>
      'किसी अन्य सेवा या पेशेवर को खोजने का प्रयास करें';

  @override
  String get selectSpecialty => 'विशेषज्ञता चुनें';

  @override
  String get availableDoctors => 'उपलब्ध डॉक्टर्स';

  @override
  String get consultationFee => 'परामर्श शुल्क';

  @override
  String get selectDate => 'तारीख़';

  @override
  String get selectTimeSlot => 'समय';

  @override
  String get morning => 'सुबह';

  @override
  String get afternoon => 'दोपहर';

  @override
  String get evening => 'शाम';

  @override
  String get consultationType => 'परामर्श प्रकार';

  @override
  String get homeVisit => 'होम विज़िट';

  @override
  String get teleconsult => 'वीडियो टेलीकंसल्ट';

  @override
  String get confirmAppointment => 'अपॉइंटमेंट की पुष्टि करें';

  @override
  String get upcomingAppointments => 'आगामी अपॉइंटमेंट्स';

  @override
  String get appointmentConfirmed => 'अपॉइंटमेंट सुनिश्चित हुई!';

  @override
  String get appointmentDetails => 'आपकी अपॉइंटमेंट निर्धारित कर दी गई है।';

  @override
  String get selectCaregiver => 'देखभालकर्ता चुनें';

  @override
  String get hours => 'घंटे';

  @override
  String get selectHours => 'घंटे चुनें';

  @override
  String get careType => 'देखभाल का प्रकार';

  @override
  String get elderlyCare => 'बुजुर्गों की देखभाल';

  @override
  String get postOpCare => 'सर्जरी के बाद की देखभाल';

  @override
  String get companionship => 'साथी';

  @override
  String get mobilityAssistance => 'गतिशीलता सहायता';

  @override
  String get totalAmount => 'कुल राशि';

  @override
  String get caregiverBooked => 'देखभालकर्ता बुक हो गया!';

  @override
  String get caregiverBookingSuccess => 'आपका अनुरोध सफलतापूर्वक जमा हो गया।';

  @override
  String get nearYou => 'आपके निकट';

  @override
  String get farmServices => 'खेती सेवाएँ';

  @override
  String get farmServicesTagline =>
      'सत्यापित पेड़ चढ़ने वाले, कटाई करने वाले और खेत मज़दूर। पेड़ या घंटे के हिसाब से बुक करें।';

  @override
  String get noServicesTitle => 'अभी कोई सेवा नहीं';

  @override
  String get noServicesDescription =>
      'जैसे-जैसे कामगार जुड़ेंगे, खेती सेवाएँ यहाँ दिखेंगी।';

  @override
  String perUnit(String unit) {
    return 'प्रति $unit';
  }

  @override
  String get unitTree => 'पेड़';

  @override
  String get unitHour => 'घंटा';

  @override
  String get unitVisit => 'विज़िट';

  @override
  String unitTreeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पेड़',
      one: '1 पेड़',
    );
    return '$_temp0';
  }

  @override
  String unitHourCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे',
      one: '1 घंटा',
    );
    return '$_temp0';
  }

  @override
  String unitVisitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count विज़िट',
      one: '1 विज़िट',
    );
    return '$_temp0';
  }

  @override
  String get serviceStandards => 'कामगार की गारंटी';

  @override
  String get standardSafetyHarness => 'हर चढ़ाई पर सेफ्टी हार्नेस';

  @override
  String get standardBunchProtection =>
      'गुच्छे रस्सी से उतारे जाते हैं, गिराए नहीं';

  @override
  String get standardDebrisCleared => 'जाने से पहले पत्ते और छिलके साफ़';

  @override
  String get standardGroundNets => 'नीचे की फ़सल बचाने के लिए जाल';

  @override
  String get standardPowerLineGuard => 'बिजली की लाइनों से सुरक्षित दूरी';

  @override
  String get standardWoodChipping => 'कटी डालियाँ छोटी करके रखी जाती हैं';

  @override
  String get standardEcoCompost => 'सिर्फ़ जैविक खाद और मल्च';

  @override
  String get standardPestPrevention => 'हर विज़िट पर कीट जाँच';

  @override
  String get standardBoundaryClearing => 'सीमाएँ और नालियाँ साफ़';

  @override
  String get standardVerifiedWorker => 'आईडी-सत्यापित कामगार';

  @override
  String get standardOnTimeArrival => 'बुक किए समय पर पहुँचता है';

  @override
  String get standardFairPrice => 'काम शुरू होने से पहले दाम तय';

  @override
  String workersNearYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'आपके पास $count सत्यापित कामगार',
      one: 'आपके पास 1 सत्यापित कामगार',
    );
    return '$_temp0';
  }

  @override
  String get noWorkersYet => 'इस सेवा के कामगार जोड़े जा रहे हैं';

  @override
  String get liveTotalNote =>
      'अगले चरण में मात्रा चुनते ही कुल राशि तुरंत बदलेगी।';

  @override
  String get scheduleTitle => 'शेड्यूल';

  @override
  String get change => 'बदलें';

  @override
  String get quantity => 'मात्रा';

  @override
  String priceEach(String price) {
    return '$price प्रति';
  }

  @override
  String get calculation => 'हिसाब';

  @override
  String breakdown(String price, String units) {
    return '$price × $units';
  }

  @override
  String get total => 'कुल';

  @override
  String get farmAddress => 'खेत का पता';

  @override
  String get farmAddressHint => 'घर का नाम, गली, कस्बा';

  @override
  String get addressRequired => 'कृपया खेत का पता भरें';

  @override
  String get serviceAddress => 'सेवा का पता';

  @override
  String get serviceAddressRequired => 'कृपया सेवा का पता भरें';

  @override
  String get worker => 'कामगार';

  @override
  String get popularSearches => 'लोकप्रिय खोजें';

  @override
  String get continueToPayment => 'भुगतान पर जाएँ';

  @override
  String get paymentTitle => 'भुगतान';

  @override
  String get orderSummary => 'ऑर्डर सारांश';

  @override
  String get service => 'सेवा';

  @override
  String get date => 'तारीख़';

  @override
  String get time => 'समय';

  @override
  String get rate => 'दर';

  @override
  String get totalPayable => 'देय राशि';

  @override
  String get paymentMethod => 'भुगतान का तरीका';

  @override
  String get payUpi => 'UPI';

  @override
  String get payUpiSubtitle => 'Google Pay, PhonePe, Paytm';

  @override
  String get payCard => 'क्रेडिट या डेबिट कार्ड';

  @override
  String get payCardSubtitle => 'Visa, Mastercard, RuPay';

  @override
  String get payAfter => 'सेवा के बाद नकद भुगतान';

  @override
  String get payAfterSubtitle => 'काम पूरा होने पर कामगार को नकद दें';

  @override
  String confirmAndPay(String amount) {
    return '$amount चुकाएँ और पक्का करें';
  }

  @override
  String get confirmBooking => 'बुकिंग पक्की करें';

  @override
  String get paymentFailed => 'भुगतान पूरा नहीं हुआ। फिर से कोशिश करें।';

  @override
  String get draftMissing =>
      'इस चरण के लिए एक बुकिंग चालू होनी चाहिए। खेती सेवाओं से दोबारा शुरू करें।';

  @override
  String get bookingConfirmed => 'बुकिंग पक्की हुई';

  @override
  String bookingConfirmedSubtitle(String date, String time) {
    return 'आपका कामगार $date को $time बजे पहुँचेगा';
  }

  @override
  String get bookingId => 'बुकिंग आईडी';

  @override
  String get status => 'स्थिति';

  @override
  String get payment => 'भुगतान';

  @override
  String get viewMyBookings => 'मेरी बुकिंग देखें';

  @override
  String get backToHome => 'होम पर वापस';

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusConfirmed => 'पक्की';

  @override
  String get statusInProgress => 'चल रही है';

  @override
  String get statusCompleted => 'पूरी हुई';

  @override
  String get statusCancelled => 'रद्द';

  @override
  String get noBookingsTitle => 'अभी कोई बुकिंग नहीं';

  @override
  String get noBookingsDescription =>
      'खेती या घर की सेवा बुक करें, वह यहाँ दिखेगी।';

  @override
  String get bookAService => 'सेवा बुक करें';

  @override
  String get upcoming => 'आगामी';

  @override
  String get past => 'पिछली';

  @override
  String get somethingWentWrong => 'कुछ गड़बड़ हो गई';

  @override
  String get messages => 'संदेश';

  @override
  String get messagesSubtitle => 'बुक किए कामगारों से चैट करें';

  @override
  String get noMessagesTitle => 'अभी कोई बातचीत नहीं';

  @override
  String get noMessagesDescription =>
      'कामगार बुक करने के बाद यहाँ उन्हें संदेश भेज सकते हैं।';

  @override
  String get noMessagesInThread => 'बातचीत शुरू करने के लिए नमस्ते कहें';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफ़लाइन';

  @override
  String get typeMessage => 'संदेश लिखें';

  @override
  String get todaysMedicines => 'आज की दवाएँ';

  @override
  String get medicinesSubtitle => 'खुराक लेने के बाद गोले पर टैप करें';

  @override
  String pendingDoses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count खुराक बाकी',
      one: '1 खुराक बाकी',
      zero: 'सभी खुराक ली गईं',
    );
    return '$_temp0';
  }

  @override
  String nextDose(String name, String time) {
    return 'अगली: $time बजे $name';
  }

  @override
  String get addReminder => 'रिमाइंडर जोड़ें';

  @override
  String get medicineName => 'दवा का नाम';

  @override
  String get medicineNameHint => 'जैसे BP की गोली';

  @override
  String get dosage => 'खुराक';

  @override
  String get dosageHint => 'जैसे नाश्ते के बाद 1 गोली';

  @override
  String get reminderTime => 'रिमाइंडर समय';

  @override
  String get save => 'सहेजें';

  @override
  String addedBy(String name) {
    return '$name ने जोड़ा';
  }

  @override
  String markedTaken(String name) {
    return '$name ली गई के रूप में दर्ज';
  }

  @override
  String markedPending(String name) {
    return '$name बाकी के रूप में दर्ज';
  }

  @override
  String get nameRequired => 'कृपया नाम भरें';

  @override
  String get phoneRequired => 'कृपया फ़ोन नंबर भरें';

  @override
  String get noRemindersTitle => 'अभी कोई रिमाइंडर नहीं';

  @override
  String get noRemindersDescription =>
      'अपनी दवाएँ जोड़ें, कायलो सही समय पर याद दिलाएगा।';

  @override
  String get pressAndHold => 'दबाकर रखें';

  @override
  String get holdSeconds => '3 सेकंड दबाए रखें';

  @override
  String secondsShort(int seconds) {
    return '$seconds से';
  }

  @override
  String get sosHoldHint =>
      'अपने SIM से संपर्कों को कॉल करने के लिए 3 सेकंड दबाए रखें। प्राथमिक संपर्क को पहले कॉल किया जाएगा। हर कॉल के बाद आगे बढ़ने के लिए Kaylo में लौटें। सामान्य SIM शुल्क लागू हैं।';

  @override
  String get sosReleasedEarly => 'कॉल शुरू करने के लिए 3 सेकंड दबाए रखें';

  @override
  String get sosSentTitle => 'मदद आ रही है';

  @override
  String sosSentContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count संपर्कों को लोकेशन के साथ अलर्ट भेजा',
      one: '1 संपर्क को लोकेशन के साथ अलर्ट भेजा',
    );
    return '$_temp0';
  }

  @override
  String sosCallingPrimary(String name) {
    return '$name को कॉल किया जा रहा है';
  }

  @override
  String get sosNoContacts =>
      'पहले एक आपातकालीन संपर्क जोड़ें, ताकि अलर्ट किसी को मिले।';

  @override
  String get dismiss => 'बंद करें';

  @override
  String get emergencyContacts => 'आपातकालीन संपर्क';

  @override
  String get addContact => 'संपर्क जोड़ें';

  @override
  String get contactName => 'नाम';

  @override
  String get relationship => 'रिश्ता';

  @override
  String get relationshipHint => 'जैसे बेटी';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get primary => 'मुख्य';

  @override
  String get setAsPrimary => 'मुख्य बनाएँ';

  @override
  String get removeContact => 'हटाएँ';

  @override
  String get sosHistory => 'SOS इतिहास';

  @override
  String alertsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count अलर्ट भेजे',
      one: '1 अलर्ट भेजा',
      zero: 'कोई अलर्ट नहीं भेजा',
    );
    return '$_temp0';
  }

  @override
  String get noSosTitle => 'कोई अलर्ट नहीं भेजा';

  @override
  String get noSosDescription =>
      'भेजे गए अलर्ट और किसे सूचना मिली, यहाँ दिखेगा।';

  @override
  String alertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count संपर्कों को सूचना दी',
      one: '1 संपर्क को सूचना दी',
    );
    return '$_temp0';
  }

  @override
  String get sosStatusOpen => 'खुला';

  @override
  String get sosStatusAcknowledged => 'देखा गया';

  @override
  String get sosStatusResolved => 'सुलझा';

  @override
  String locationShared(String location) {
    return 'लोकेशन साझा: $location';
  }

  @override
  String primaryContact(String name) {
    return 'मुख्य संपर्क: $name';
  }

  @override
  String get unitOrder => 'ऑर्डर';

  @override
  String unitOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ऑर्डर',
      one: '1 ऑर्डर',
    );
    return '$_temp0';
  }

  @override
  String get standardPartsQuoted => 'पुर्ज़े लगाने से पहले दाम बताया जाता है';

  @override
  String get standardCleanupAfter => 'जाने से पहले काम की जगह साफ़';

  @override
  String get standardBackgroundChecked => 'पृष्ठभूमि-जाँचा हुआ केयरगिवर';

  @override
  String get standardPrescriptionChecked =>
      'पर्ची फ़ार्मासिस्ट द्वारा जाँची जाती है';

  @override
  String get careServices => 'केयर सेवाएँ';

  @override
  String get allServices => 'सभी सेवाएँ';

  @override
  String get homeServicesTagline =>
      'प्लंबर, इलेक्ट्रीशियन और सफ़ाईकर्मी जो समय पर आते हैं और काम के बाद सफ़ाई करते हैं।';

  @override
  String get careServicesTagline =>
      'आपके अपनों के लिए प्रशिक्षित केयरगिवर और घर तक दवाएँ।';

  @override
  String get allServicesTagline => 'घर, खेत और केयर में कायलो की हर सेवा।';

  @override
  String get useMyLocation => 'मेरी लोकेशन इस्तेमाल करें';

  @override
  String get locating => 'ढूँढ रहे हैं…';

  @override
  String get locationServicesOff => 'लोकेशन सेवाएँ चालू करके फिर कोशिश करें।';

  @override
  String get locationDenied => 'लोकेशन की अनुमति नहीं मिली।';

  @override
  String get locationDeniedForever =>
      'कायलो के लिए लोकेशन ब्लॉक है। डिवाइस सेटिंग में अनुमति दें।';

  @override
  String get locationTimeout =>
      'GPS नहीं मिला। खुली जगह पर जाकर फिर कोशिश करें।';

  @override
  String get locationUnavailable => 'लोकेशन अभी उपलब्ध नहीं है।';

  @override
  String get markAllRead => 'सभी पढ़ी हुई करें';

  @override
  String get noNotificationsTitle => 'सब देख लिया';

  @override
  String get noNotificationsDescription =>
      'बुकिंग अपडेट, संदेश और रिमाइंडर यहाँ दिखेंगे।';

  @override
  String get today => 'आज';

  @override
  String get earlier => 'पहले';

  @override
  String get justNow => 'अभी';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मिनट पहले',
      one: '1 मिनट पहले',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे पहले',
      one: '1 घंटा पहले',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन पहले',
      one: 'कल',
    );
    return '$_temp0';
  }

  @override
  String get bookingDetails => 'बुकिंग विवरण';

  @override
  String get cancelBookingTitle => 'यह बुकिंग रद्द करें?';

  @override
  String get cancelBookingMessage =>
      'कामगार को छोड़ दिया जाएगा। आप कभी भी दोबारा बुक कर सकते हैं।';

  @override
  String get keepBooking => 'बुकिंग रखें';

  @override
  String get cancelBooking => 'बुकिंग रद्द करें';

  @override
  String get bookingCancelled => 'बुकिंग रद्द हुई';

  @override
  String get bookingCancelledBanner => 'यह बुकिंग रद्द कर दी गई थी।';

  @override
  String get stepRequested => 'अनुरोध';

  @override
  String get stepConfirmed => 'पक्की';

  @override
  String get stepInProgress => 'चल रही';

  @override
  String get stepCompleted => 'पूरी';

  @override
  String get assignedWorker => 'आपका कामगार';

  @override
  String get noWorkerYet => 'विज़िट से पहले कामगार तय किया जाएगा।';

  @override
  String get messageWorker => 'संदेश';

  @override
  String get reschedule => 'समय बदलें';

  @override
  String get bookingRescheduled => 'बुकिंग का समय बदला';

  @override
  String get filters => 'फ़िल्टर';

  @override
  String get category => 'श्रेणी';

  @override
  String get applyFilters => 'लागू करें';

  @override
  String get sortRelevance => 'प्रासंगिकता';

  @override
  String get sortPriceLowHigh => 'दाम: कम से ज़्यादा';

  @override
  String get sortPriceHighLow => 'दाम: ज़्यादा से कम';

  @override
  String get allCategories => 'सभी';

  @override
  String get noResultsTitle => 'कोई सेवा नहीं मिली';

  @override
  String get noResultsDescription =>
      'दूसरा शब्द आज़माएँ, या समस्या बताएँ: \"नल टपक रहा है\" भी चलेगा।';

  @override
  String resultsFor(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '\"$query\" के लिए $count नतीजे',
      one: '\"$query\" के लिए 1 नतीजा',
    );
    return '$_temp0';
  }

  @override
  String get yourLocation => 'आपकी लोकेशन';

  @override
  String get or => 'या';

  @override
  String get townOrCity => 'कस्बा या शहर';

  @override
  String get townHint => 'जैसे कन्नूर';

  @override
  String get saveLocation => 'लोकेशन सहेजें';

  @override
  String get townRequired => 'कृपया कस्बा या शहर भरें';

  @override
  String locationUpdated(String label) {
    return 'लोकेशन $label सेट हुई';
  }

  @override
  String get enableLocation => 'लोकेशन चालू करें';

  @override
  String get enableLocationSubtitle =>
      'कायलो आपकी लोकेशन से पास के कामगार दिखाता है और SOS अलर्ट में उसे साझा करता है।';

  @override
  String get locationWillAppear => 'आपकी लोकेशन यहाँ दिखेगी';

  @override
  String get locateAgain => 'फिर से ढूँढें';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get enterManually => 'खुद भरें';

  @override
  String get notNow => 'अभी नहीं';

  @override
  String get noAddressesTitle => 'कोई सहेजा पता नहीं';

  @override
  String get noAddressesDescription =>
      'घर या खेत का पता एक बार सहेजें, बुकिंग में एक टैप में चुनें।';

  @override
  String get addAddress => 'पता जोड़ें';

  @override
  String get defaultLabel => 'डिफ़ॉल्ट';

  @override
  String get setAsDefault => 'डिफ़ॉल्ट बनाएँ';

  @override
  String get removeAddress => 'हटाएँ';

  @override
  String get addressLabel => 'लेबल';

  @override
  String get labelHome => 'घर';

  @override
  String get labelFarm => 'खेत';

  @override
  String get labelWork => 'काम';

  @override
  String get labelOther => 'अन्य';

  @override
  String get labelOtherHint => 'जैसे माँ का घर';

  @override
  String get addressLine => 'पता';

  @override
  String get addressSaved => 'पता सहेजा गया';

  @override
  String get contactUs => 'संपर्क करें';

  @override
  String get emailUs => 'ईमेल करें';

  @override
  String get reportProblem => 'समस्या बताएँ';

  @override
  String get reportProblemSubtitle => 'बताएँ क्या गड़बड़ हुई';

  @override
  String get reportProblemTemplate => 'क्या हुआ:\nऐप में कहाँ:\nफ़ोन मॉडल:';

  @override
  String get faq => 'अक्सर पूछे जाने वाले सवाल';

  @override
  String get faqBookQ => 'सेवा कैसे बुक करें?';

  @override
  String get faqBookA =>
      'होम स्क्रीन या खोज से सेवा चुनें, तारीख़, समय और मात्रा तय करें, पता जोड़ें और पक्का करें। बुकिंग आईडी तुरंत मिलती है और बुकिंग में ट्रैक कर सकते हैं।';

  @override
  String get faqPayQ => 'भुगतान कैसे करें?';

  @override
  String get faqPayA =>
      'UPI और कार्ड पक्का करते ही कट जाते हैं। काम पूरा होने पर कामगार को सीधे देने के लिए \"सेवा के बाद भुगतान\" चुनें।';

  @override
  String get faqCancelQ => 'क्या रद्द या समय बदल सकते हैं?';

  @override
  String get faqCancelA =>
      'हाँ। बुकिंग में जाकर समय बदलें या रद्द करें। कामगार के निकलने तक दोनों मुफ़्त हैं।';

  @override
  String get faqWorkersQ => 'कामगारों की जाँच कैसे होती है?';

  @override
  String get faqWorkersA =>
      'सूची में आने से पहले हर कामगार की आईडी जाँची जाती है, और रेटिंग सिर्फ़ उन ग्राहकों से आती है जिन्होंने बुकिंग पूरी की।';

  @override
  String get faqCareQ => 'केयर मोड क्या है?';

  @override
  String get faqCareA =>
      'केयर मोड पूरे ऐप को बुज़ुर्गों के लिए बड़े अक्षर और ऊँचे कॉन्ट्रास्ट वाला बना देता है, दवा रिमाइंडर और एक दबाव में SOS के साथ।';

  @override
  String get faqSosQ => 'SOS कैसे काम करता है?';

  @override
  String get faqSosA =>
      'SOS बटन तीन सेकंड दबाकर रखें। हर आपातकालीन संपर्क को आपकी लोकेशन मिलती है और मुख्य संपर्क को कॉल जाता है।';

  @override
  String get helpFooter =>
      'कायलो केरल की एक छोटी टीम बनाती है। हर संदेश पढ़ा जाता है।';

  @override
  String get couldNotOpenEmail => 'ईमेल ऐप नहीं खुल सका।';

  @override
  String get rateTitle => 'कायलो कैसा लग रहा है?';

  @override
  String get rateSubtitle =>
      'आपकी रेटिंग टीम को बताती है कि आगे किस पर ध्यान दें।';

  @override
  String get rateComment => 'कुछ सुधारें? (वैकल्पिक)';

  @override
  String get submitRating => 'भेजें';

  @override
  String get pickAStar => 'पहले स्टार रेटिंग चुनें';

  @override
  String youRated(int stars) {
    return 'आपने कायलो को 5 में से $stars दिए';
  }

  @override
  String get confirmLocation => 'लोकेशन कन्फ़र्म करें';

  @override
  String get moveMapToPlacePin => 'पिन रखने के लिए मैप खिसकाएँ';

  @override
  String get findingAddress => 'पता ढूँढ रहे हैं…';

  @override
  String get selectedLocation => 'चुनी हुई लोकेशन';

  @override
  String get mapUnavailable => 'मैप प्रीव्यू उपलब्ध नहीं';

  @override
  String get searchTownHint => 'कस्बा या शहर खोजें';

  @override
  String workerAbout(String name, String place, int jobs) {
    return '$name $place में $jobs पूरे किए गए कार्यों के साथ कायलो पेशेवर हैं।';
  }

  @override
  String get verificationPending => 'सत्यापन प्रगति पर है';

  @override
  String get certGovtId => 'सरकारी पहचान सत्यापित';

  @override
  String get certGovtIdSub => 'आधार या वोटर आईडी जांची गई';

  @override
  String get certPolice => 'पुलिस क्लीयरेंस सत्यापित';

  @override
  String get certPoliceSub => 'पृष्ठभूमि जांच स्पष्ट';

  @override
  String get certSkill => 'कायलो कौशल प्रमाणित';

  @override
  String get certSkillSub => 'व्यावहारिक कौशल परीक्षित';

  @override
  String get hourlyRate => 'प्रति घंटा दर';

  @override
  String get perHour => 'प्रति घंटा';

  @override
  String get priceOnVisit => 'बुकिंग से पहले कीमत देखें';

  @override
  String get noReviewsYet => 'अभी कोई समीक्षा नहीं';

  @override
  String get newService => 'नया';

  @override
  String get nearbyFirst => 'नज़दीकी पहले';

  @override
  String get tomorrow => 'कल';

  @override
  String inDays(int count) {
    return '$count दिनों में';
  }

  @override
  String get whoIsItFor => 'यह किसके लिए है?';

  @override
  String get appointmentNotes => 'डॉक्टर के लिए नोट्स (वैकल्पिक)';

  @override
  String appointmentConfirmedWith(String doctor) {
    return '$doctor के साथ अपॉइंटमेंट बुक हुआ';
  }

  @override
  String get noUpcomingAppointments => 'अभी कोई आगामी अपॉइंटमेंट नहीं है';

  @override
  String get specGeneral => 'सामान्य चिकित्सक';

  @override
  String get specCardio => 'हृदय रोग विशेषज्ञ';

  @override
  String get specOrtho => 'हड्डी रोग विशेषज्ञ';

  @override
  String get specGeriatric => 'वृद्धावस्था विशेषज्ञ';

  @override
  String get specAyurveda => 'आयुर्वेद';

  @override
  String get incPlumbTap => 'नल मरम्मत';

  @override
  String get incPlumbPipe => 'पाइप रिसाव';

  @override
  String get incPlumbDrain => 'नाली की सफाई';

  @override
  String get incPlumbInstall => 'स्थापना';

  @override
  String get incElecSwitch => 'स्विचबोर्ड मरम्मत';

  @override
  String get incElecWiring => 'वायरिंग ठीक करना';

  @override
  String get incElecFan => 'पंखा लगाना';

  @override
  String get incElecMcb => 'MCB ट्रिपिंग';

  @override
  String get incCleanDeep => 'पूरे घर की डीप क्लीनिंग';

  @override
  String get incCleanKitchen => 'रसोई की सफाई';

  @override
  String get incCleanBath => 'बाथरूम स्क्रब';

  @override
  String get incCleanSofa => 'सोफा शैम्पू';

  @override
  String get incCarpFurniture => 'फर्नीचर मरम्मत';

  @override
  String get incCarpDoor => 'दरवाजे और खिड़कियां';

  @override
  String get incCarpLock => 'ताला लगाना';

  @override
  String get incCarpCustom => 'कस्टम लकड़ी का काम';

  @override
  String get incPaintInterior => 'आंतरिक पेंटिंग';

  @override
  String get incPaintExterior => 'बाहरी पेंटिंग';

  @override
  String get incPaintPutty => 'वॉल पुट्टी और प्राइमर';

  @override
  String get incPaintWaterproof => 'वॉटरप्रूफिंग';

  @override
  String get incAcFilter => 'फ़िल्टर सफाई';

  @override
  String get incAcGas => 'गैस रिफिल';

  @override
  String get incAcCooling => 'कूलिंग समस्या ठीक करना';

  @override
  String get incAcInstall => 'लगाना और हटाना';

  @override
  String get incApplWasher => 'वॉशिंग मशीन';

  @override
  String get incApplFridge => 'रेफ्रिजरेटर';

  @override
  String get incApplMicrowave => 'माइक्रोवेव';

  @override
  String get incApplTv => 'टीवी लगाना और मरम्मत';

  @override
  String get incGenInspect => 'सामान्य निरीक्षण';

  @override
  String get incGenRepair => 'मरम्मत और ठीक करना';

  @override
  String get incGenInstall => 'नया इंस्टॉलेशन';

  @override
  String get incGenMaintain => 'रखरखाव';

  @override
  String get invoiceEmail => 'इनवॉइस के लिए ईमेल';

  @override
  String get invoiceEmailRequired => 'इनवॉइस के लिए एक ईमेल पता भरें';

  @override
  String get confirmationEmail => 'पुष्टि के लिए ईमेल (वैकल्पिक)';

  @override
  String get payNow => 'अभी भुगतान करें';

  @override
  String get payNowSubtitle =>
      'कार्ड, नेटबैंकिंग या UPI, Razorpay द्वारा सुरक्षित';

  @override
  String get prescriptions => 'नुस्खे';

  @override
  String get prescriptionsSubtitle =>
      'अपने स्वास्थ्य रिकॉर्ड स्कैन करें, पढ़ें और सुरक्षित रखें';

  @override
  String get trustedContacts => 'भरोसेमंद संपर्क';

  @override
  String get trustedContactsSubtitle =>
      'SOS कॉल के लिए परिवार और डॉक्टरों को जोड़ें';

  @override
  String get sosStartFailedContacts =>
      'SOS शुरू नहीं हो सका। अपना कनेक्शन और भरोसेमंद संपर्क जांचें।';

  @override
  String get sosStartFailed => 'SOS शुरू नहीं हो सका। कृपया फिर से कोशिश करें।';

  @override
  String get sosModeKaylo => 'कायलो कॉल';

  @override
  String get sosModeSim => 'सिम कॉल';

  @override
  String get manageTrustedContacts => 'भरोसेमंद संपर्क प्रबंधित करें';

  @override
  String get sosKayloHoldHint =>
      'अपने भरोसेमंद कायलो संपर्कों को बुलाने के लिए 3 सेकंड दबाकर रखें। वे एक साथ कॉल में जुड़ सकते हैं। आमंत्रण भेजने का मतलब यह नहीं कि किसी ने जवाब दिया है।';

  @override
  String get contactsOpenFailed => 'फ़ोन संपर्क नहीं खुल सके।';

  @override
  String get chooseFromPhoneContacts => 'फ़ोन संपर्कों से चुनें';

  @override
  String sosContactsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count संपर्क छोड़े गए: उनके नंबर डायल नहीं हो सकते।',
      one: '1 संपर्क छोड़ा गया: उसका नंबर डायल नहीं हो सकता।',
    );
    return '$_temp0';
  }

  @override
  String get incomingSosTitle => 'कायलो SOS आ रहा है';

  @override
  String get incomingSosSubtitle => 'एक भरोसेमंद संपर्क को मदद चाहिए';

  @override
  String get decline => 'अस्वीकार करें';

  @override
  String get joinCall => 'कॉल में जुड़ें';

  @override
  String get signInLiveForContacts =>
      'भरोसेमंद संपर्क जोड़ने के लिए लाइव ऐप में साइन इन करें।';

  @override
  String get couldNotConnectRetry =>
      'कनेक्ट नहीं हो सका। कृपया फिर से कोशिश करें।';

  @override
  String get refreshConnections => 'कनेक्शन रीफ़्रेश करें';

  @override
  String get trustedCircleTitle => 'अपनों को कायलो में लाएं';

  @override
  String get trustedCircleBody =>
      'कायलो इस्तेमाल करने वाले अधिकतम पांच परिजनों या डॉक्टरों को आमंत्रित करें। आपका कोड स्वीकार करने पर उन्हें आपके SOS अलर्ट मिलेंगे और वे उसी वॉइस कॉल में जुड़ सकेंगे।';

  @override
  String get getInviteCode => 'मेरा आमंत्रण कोड पाएं';

  @override
  String get inviteCodeCopied => 'आमंत्रण कोड कॉपी हो गया';

  @override
  String get copyCode => 'कोड कॉपी करें';

  @override
  String get inviteCodeValidity =>
      'सात दिन तक मान्य। केवल भरोसेमंद लोगों के साथ साझा करें।';

  @override
  String get acceptInviteTitle => 'किसी का आमंत्रण स्वीकार करें';

  @override
  String get inviteCode => 'आमंत्रण कोड';

  @override
  String get acceptInvitation => 'आमंत्रण स्वीकार करें';

  @override
  String get invitationAccepted =>
      'आमंत्रण स्वीकार हुआ। अब आप जुड़ गए हैं और उनके SOS अलर्ट पा सकते हैं।';

  @override
  String get yourConnections => 'आपके कनेक्शन';

  @override
  String get noConnectionsYet => 'अभी कोई कनेक्शन नहीं';

  @override
  String get receivesYourSos => 'आपके SOS अलर्ट पाते हैं';

  @override
  String get youReceiveTheirSos => 'आपको उनके SOS अलर्ट मिलते हैं';

  @override
  String get removeConnection => 'कनेक्शन हटाएं';

  @override
  String get removeConnectionTitle => 'कनेक्शन हटाएं?';

  @override
  String get removeConnectionBody =>
      'इस कनेक्शन को अब SOS कॉल के आमंत्रण नहीं मिलेंगे।';

  @override
  String get contactsLoadFailedRetry =>
      'संपर्क लोड नहीं हो सके। फिर कोशिश करें';

  @override
  String get callTitle => 'कायलो SOS कॉल';

  @override
  String get callEnded => 'कॉल समाप्त';

  @override
  String get callYourCircle => 'आपका भरोसेमंद समूह';

  @override
  String get callCouldNotConnect => 'कनेक्ट नहीं हो सका';

  @override
  String get callConnecting => 'कनेक्ट हो रहा है…';

  @override
  String get callKeepOpen => 'कॉल के दौरान कायलो खुला रखें।';

  @override
  String get retryCall => 'कॉल फिर से आज़माएं';

  @override
  String get callErrorRoom =>
      'यह कॉल उपलब्ध नहीं है या समाप्त हो चुकी है। नई कॉल शुरू करने के लिए SOS पर लौटें।';

  @override
  String get callErrorSettings =>
      'कॉल सेटिंग लोड नहीं हो सकीं। अपना कनेक्शन जांचकर फिर कोशिश करें।';

  @override
  String get callErrorMicrophone =>
      'माइक्रोफ़ोन तक पहुंच नहीं हो सकी। कायलो के लिए माइक्रोफ़ोन अनुमति जांचकर फिर कोशिश करें।';

  @override
  String get callErrorJoin =>
      'इस कॉल में जुड़ नहीं सके। फिर कोशिश करें, या कॉल करने वाले से नई SOS कॉल शुरू करने को कहें।';

  @override
  String get callInterrupted => 'कनेक्शन बाधित हुआ। फिर कोशिश हो रही है…';

  @override
  String get callPeerConnected => 'कनेक्ट हो गया';

  @override
  String get callPeerFailed => 'कनेक्शन विफल';

  @override
  String get callPeerReconnecting => 'फिर से कनेक्ट हो रहा है';

  @override
  String get callPeerConnecting => 'कनेक्ट हो रहा है';

  @override
  String get callYou => 'आप';

  @override
  String get callYouMuted => 'आप • म्यूट';

  @override
  String get callInvitedWaiting => 'आमंत्रित • जवाब का इंतज़ार';

  @override
  String get callDeclined => 'अस्वीकार किया';

  @override
  String get callLeft => 'कॉल छोड़ दी';

  @override
  String get mute => 'म्यूट';

  @override
  String get unmute => 'अनम्यूट';

  @override
  String get speaker => 'स्पीकर';

  @override
  String get callAudioOutputFailed =>
      'ऑडियो आउटपुट नहीं बदल सका। कॉल अभी भी चालू है।';

  @override
  String get close => 'बंद करें';

  @override
  String get callEndForEveryone => 'सबके लिए कॉल समाप्त करें';

  @override
  String get callLeave => 'कॉल छोड़ें';

  @override
  String get prescriptionsLoadFailed =>
      'नुस्खे लोड नहीं हो सके। कृपया फिर से कोशिश करें।';

  @override
  String get actionFailed => 'वह कार्रवाई पूरी नहीं हो सकी।';

  @override
  String get prescriptionSaveFailed =>
      'नुस्खा सहेजा नहीं जा सका। कृपया फिर से कोशिश करें।';

  @override
  String get prescriptionsHeadline => 'आपके स्वास्थ्य रिकॉर्ड, एक जगह';

  @override
  String get prescriptionsIntro =>
      'नुस्खा स्कैन करें या पुराना रिकॉर्ड टाइप करें। PDF इस डिवाइस पर निजी रूप से सहेजे जाते हैं।';

  @override
  String get prescriptionsAndroidOnly =>
      'नुस्खा स्कैनिंग और PDF फ़िलहाल Android ऐप में उपलब्ध हैं।';

  @override
  String get scanOrPhotos => 'स्कैन / फ़ोटो';

  @override
  String get typeRecord => 'रिकॉर्ड टाइप करें';

  @override
  String get searchPrescriptions => 'नुस्खे खोजें';

  @override
  String get noPrescriptionsYet => 'अभी कोई नुस्खा नहीं';

  @override
  String get noMatchingPrescriptions => 'कोई मिलता-जुलता नुस्खा नहीं';

  @override
  String get prescriptionNeedsTitleText =>
      'एक शीर्षक और नुस्खे का विवरण जोड़ें।';

  @override
  String get prescriptionRecord => 'नुस्खे का रिकॉर्ड';

  @override
  String get reviewPrescription => 'नुस्खे की जांच करें';

  @override
  String get deletePrescription => 'नुस्खा हटाएं';

  @override
  String get deletePrescriptionTitle => 'नुस्खा हटाएं?';

  @override
  String get deletePrescriptionBody =>
      'PDF और टेक्स्ट इस डिवाइस से हटा दिए जाएंगे।';

  @override
  String get delete => 'हटाएं';

  @override
  String get prescriptionReviewHint =>
      'निकाले गए टेक्स्ट को मूल नुस्खे से मिलाएं। हस्तलेख अधूरा या गलत हो सकता है; दवाओं के नाम और खुराक अपने डॉक्टर से पक्का करें।';

  @override
  String get viewOriginalPdf => 'मूल PDF देखें';

  @override
  String get titleLabel => 'शीर्षक';

  @override
  String get extractedTextNotes => 'निकाला गया टेक्स्ट / नोट्स';

  @override
  String get prescriptionDetails => 'नुस्खे का विवरण';

  @override
  String get prescriptionEditHint =>
      'यह टेक्स्ट बदलने पर भी मूल स्कैन किया गया PDF वैसा ही रहता है।';

  @override
  String get saving => 'सहेजा जा रहा है…';

  @override
  String get savePrescription => 'नुस्खा सहेजें';

  @override
  String get openSavedPdf => 'सहेजा गया PDF खोलें';

  @override
  String get shareSavedPdf => 'सहेजा गया PDF साझा करें';

  @override
  String get deleteAccount => 'खाता हटाएं';

  @override
  String get deleteRequiresLive =>
      'खाता हटाने के लिए साइन इन किया हुआ लाइव खाता चाहिए।';

  @override
  String get deleteNotConfirmed =>
      'हटाने की पुष्टि नहीं हुई। कृपया फिर कोशिश करें।';

  @override
  String get deleteFailed => 'खाता हटाया नहीं जा सका। कृपया फिर से कोशिश करें।';

  @override
  String get deleteAccountHeadline => 'अपना कायलो खाता हमेशा के लिए हटाएं?';

  @override
  String get deleteAccountBody =>
      'इससे आपका साइन-इन, प्रोफ़ाइल, बुकिंग, संदेश, केयर रिकॉर्ड और इस डिवाइस पर रखे नुस्खे हट जाएंगे। इसे वापस नहीं किया जा सकता। पहले चालू बुकिंग पूरी करें या रद्द करें। अटके हुए भुगतान के लिए kayloapp@gmail.com पर संपर्क करें।';

  @override
  String get deleteAccountNote =>
      'भुगतान सेवाएं लेन-देन के रिकॉर्ड रख सकती हैं। आपने पहले जो दस्तावेज़ साझा किए हैं, वे दूसरों के डिवाइस से नहीं हटते।';

  @override
  String get typeDeleteToConfirm => 'पुष्टि के लिए DELETE टाइप करें';

  @override
  String get deleting => 'हटाया जा रहा है…';

  @override
  String get deleteMyAccount => 'मेरा खाता हटाएं';

  @override
  String get paymentVerified =>
      'भुगतान की पुष्टि हुई। आपकी बुकिंग पक्की हो गई।';

  @override
  String get paymentNotCompleted => 'भुगतान पूरा नहीं हुआ।';

  @override
  String get checkoutOpenFailed =>
      'सुरक्षित चेकआउट नहीं खुल सका। कृपया फिर से कोशिश करें।';

  @override
  String get cardsAndUpi => 'कार्ड और UPI';

  @override
  String get paymentMethodsBody =>
      'सुरक्षित Razorpay चेकआउट में कार्ड की जानकारी भरें या UPI चुनें। जहां सुविधा हो, उस कार्ड को दोबारा इस्तेमाल करने के लिए Razorpay का कार्ड सहेजने का विकल्प चुनें। सहेजे गए कार्ड चेकआउट के अंदर ही संभाले जाते हैं।';

  @override
  String get paymentMethodsNote =>
      'कायलो आपका पूरा कार्ड नंबर, CVV या PIN नहीं रखता। मौजूदा भुगतान व्यवस्था में NFC से कार्ड जोड़ना उपलब्ध नहीं है।';

  @override
  String get completePendingPayment => 'बाकी भुगतान पूरा करें';

  @override
  String get noPendingPayments =>
      'आपकी अगली बुकिंग पर चेकआउट खुलेगा, जहां आप कार्ड जोड़ या चुन सकते हैं।';

  @override
  String pendingBookingLine(String id, String date) {
    return 'बुकिंग $id • $date';
  }

  @override
  String get bookingsLoadFailedRetry =>
      'बुकिंग लोड नहीं हो सकीं। फिर कोशिश करें';

  @override
  String get openingPayment => 'भुगतान खुल रहा है…';

  @override
  String get payAndBook => 'भुगतान करके बुक करें';

  @override
  String get appointmentPaymentFailed =>
      'भुगतान पूरा नहीं हो सका। आपकी अपॉइंटमेंट पक्की नहीं हुई है। कृपया फिर से कोशिश करें।';

  @override
  String get visitPaymentFailed =>
      'भुगतान पूरा नहीं हो सका। आपकी विज़िट पक्की नहीं हुई है। कृपया फिर से कोशिश करें।';

  @override
  String get careServiceUnavailable => 'यह केयर सेवा उपलब्ध नहीं है।';

  @override
  String get appointmentNotConfirmed =>
      'भुगतान पूरा नहीं हुआ। आपकी अपॉइंटमेंट पक्की नहीं हुई है।';

  @override
  String get hapticFeedback => 'हैप्टिक प्रतिक्रिया';

  @override
  String get soundEffects => 'ध्वनि प्रभाव';

  @override
  String get voiceStarting => 'माइक्रोफ़ोन शुरू हो रहा है…';

  @override
  String get ocrNeedsReview =>
      'कुछ पाठ पढ़ा नहीं जा सका। मूल स्कैन देखकर नोट्स सही करें।';

  @override
  String get allBookings => 'सभी बुकिंग';

  @override
  String get noCompletedBookings => 'अभी कोई पूरी हुई बुकिंग नहीं है';

  @override
  String get noCompletedBookingsDescription =>
      'काम पूरा होने पर आपकी बुकिंग यहाँ दिखाई देंगी।';

  @override
  String get verificationRecord => 'सत्यापन रिकॉर्ड';

  @override
  String get refreshVerification => 'सत्यापन स्थिति रीफ़्रेश करें';

  @override
  String get verificationLoadError =>
      'वर्तमान सत्यापन स्थिति लोड नहीं हो सकी। फिर से कोशिश करें।';

  @override
  String get kayloVerified => 'Kaylo पर सत्यापित';

  @override
  String get notYetVerified => 'अभी सत्यापित नहीं है';

  @override
  String get viewVerification => 'सत्यापन रिकॉर्ड देखें';

  @override
  String get verificationRecorded =>
      'इस पेशेवर की प्रोफ़ाइल Kaylo में सत्यापित के रूप में दर्ज है।';

  @override
  String get verificationNotRecorded =>
      'इस प्रोफ़ाइल के लिए सत्यापित स्थिति दर्ज नहीं है।';

  @override
  String get listedServices => 'सूचीबद्ध सेवाएँ';

  @override
  String get profileReference => 'प्रोफ़ाइल संदर्भ';

  @override
  String get serviceArea => 'सेवा क्षेत्र';

  @override
  String get verificationScope =>
      'यह रिकॉर्ड प्रोफ़ाइल की वर्तमान स्थिति दिखाता है। सहायक दस्तावेज़ और जाँच के विवरण उपलब्ध नहीं हैं। यह सरकारी लाइसेंस या पेशेवर योग्यता नहीं है।';

  @override
  String get selectOnMap => 'मानचित्र पर चुनें';

  @override
  String get chooseAddress => 'पता चुनें';

  @override
  String get offerFirst100Title => 'आपकी पहली बुकिंग खास है';

  @override
  String get offerFirst100Body =>
      '₹499 या उससे अधिक की पहली बुकिंग पर ₹100 की छूट।';

  @override
  String get offerKaylo150Title => 'बड़े कामों में थोड़ी मदद';

  @override
  String get offerKaylo150Body =>
      '₹1,499 या उससे अधिक की बुकिंग पर ₹150 की छूट। प्रति खाता एक बार।';

  @override
  String get offerWeekend100Title => 'सप्ताहांत का सही इस्तेमाल';

  @override
  String get offerWeekend100Body =>
      'शनिवार और रविवार को ₹999 या उससे अधिक पर ₹100 की छूट। प्रति खाता एक बार।';

  @override
  String get offerWeekday50Title => 'हफ्ते के बीच थोड़ी राहत';

  @override
  String get offerWeekday50Body =>
      'सोमवार से शुक्रवार, ₹599 या उससे अधिक पर ₹50 की छूट। प्रति खाता एक बार।';

  @override
  String get offerHome80Title => 'घर के काम, आसान';

  @override
  String get offerHome80Body =>
      '₹499 या उससे अधिक की होम सेवा पर ₹80 की छूट। प्रति खाता एक बार।';

  @override
  String get offerFarm125Title => 'उस ज़मीन के लिए जो हमें खिलाती है';

  @override
  String get offerFarm125Body =>
      '₹999 या उससे अधिक की फ़ार्म सेवा पर ₹125 की छूट। प्रति खाता एक बार।';

  @override
  String get offerCare60Title => 'देखभाल, थोड़ी और आसान';

  @override
  String get offerCare60Body =>
      '₹399 या उससे अधिक की केयर बुकिंग पर ₹60 की छूट। प्रति खाता एक बार।';

  @override
  String get offerKaylo300Title => 'सचमुच बड़े दिनों के लिए';

  @override
  String get offerKaylo300Body =>
      '₹2,999 या उससे अधिक की बुकिंग पर ₹300 की छूट। प्रति खाता एक बार।';

  @override
  String get offerNext75Title => 'अगली बार के लिए कुछ खास';

  @override
  String get offerNext75Body =>
      '₹799 या उससे अधिक की अगली बुकिंग पर ₹75 की छूट। एक बुकिंग की पुष्टि के बाद मिलता है।';

  @override
  String get offerThanks120Title => 'तीन बुकिंग पूरी। धन्यवाद।';

  @override
  String get offerThanks120Body =>
      '₹999 या उससे अधिक की बुकिंग पर ₹120 की छूट। तीन बुकिंग की पुष्टि के बाद मिलता है।';

  @override
  String get offerReasonFirstOnly => 'केवल आपकी पहली बुकिंग के लिए';

  @override
  String get offerReasonUsed => 'पहले ही इस्तेमाल हो चुका';

  @override
  String get offerReasonRewardUsed => 'रिवॉर्ड इस्तेमाल हो चुका';

  @override
  String get offerReasonWeekend => 'सप्ताहांत में उपलब्ध';

  @override
  String get offerReasonWeekday => 'सोमवार से शुक्रवार उपलब्ध';

  @override
  String get offerReasonNeedsConfirmed => 'पहली बुकिंग की पुष्टि के बाद मिलेगा';

  @override
  String get offerReasonNeedsThree => 'तीन बुकिंग की पुष्टि के बाद मिलेगा';

  @override
  String get offerReasonHomeOnly => 'केवल होम सेवाओं के लिए';

  @override
  String get offerReasonFarmOnly => 'केवल फ़ार्म सेवाओं के लिए';

  @override
  String get offerReasonCareOnly => 'केवल केयर बुकिंग के लिए';

  @override
  String offerReasonAddMore(String amount) {
    return 'यह ऑफ़र इस्तेमाल करने के लिए $amount और जोड़ें';
  }

  @override
  String get offerNotAvailable => 'ऑफ़र उपलब्ध नहीं';

  @override
  String get offersTitle => 'थोड़ा और कायलो';

  @override
  String get offersHeadline => 'रोज़ की मदद।\nथोड़ी और खुशी।';

  @override
  String get offersIntro =>
      'ज़रूरी कामों के लिए सोच-समझकर दी गई बचत। एक बुकिंग पर एक ऑफ़र।';

  @override
  String get offersLoadFailed =>
      'आपके ऑफ़र लोड नहीं हो सके। कृपया फिर से कोशिश करें।';

  @override
  String get tryAgain => 'फिर से कोशिश करें';

  @override
  String get enterCouponCode => 'कूपन कोड डालें';

  @override
  String get couponNotFound => 'वह कोड उपलब्ध नहीं है';

  @override
  String get offersTerms =>
      'छूट आपकी बुकिंग की कुल राशि घटाती है। इन्हें नकद में नहीं बदला जा सकता और न ही जोड़ा जा सकता है। रद्द की गई बुकिंग का ऑफ़र फिर से मिल जाता है। चेकआउट पर पात्रता दोबारा जांची जाती है।';

  @override
  String offerAmountOff(String amount) {
    return '$amount की छूट';
  }

  @override
  String get applyOffer => 'लागू करें';

  @override
  String get removeOffer => 'हटाएं';

  @override
  String offerYouSave(String amount) {
    return 'आप $amount बचाते हैं';
  }

  @override
  String get offersAndRewards => 'ऑफ़र और रिवॉर्ड';

  @override
  String offerCodeApplied(String code) {
    return '$code लागू हुआ';
  }

  @override
  String get offerStampApplied => 'लागू';

  @override
  String offersReadyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ऑफ़र इस्तेमाल के लिए तैयार',
      one: '1 ऑफ़र इस्तेमाल के लिए तैयार',
    );
    return '$_temp0';
  }

  @override
  String get yourRewards => 'आपके रिवॉर्ड';

  @override
  String get allOffers => 'सभी ऑफ़र';

  @override
  String offerLabel(String code) {
    return 'ऑफ़र • $code';
  }

  @override
  String get scratchCoverTitle => 'एक छोटा सा धन्यवाद';

  @override
  String get scratchCoverHint => 'अपना रिवॉर्ड देखने के लिए खुरचें';

  @override
  String get revealReward => 'रिवॉर्ड दिखाएं';

  @override
  String scratchSemantics(String amount) {
    return 'स्क्रैच रिवॉर्ड। एक बुकिंग पर $amount की छूट देखें।';
  }

  @override
  String get bannerWelcomeTitle => 'दिल से स्वागत। ₹100 हमारी ओर से।';

  @override
  String get bannerWelcomeBody => 'आपका पहली बुकिंग का ऑफ़र तैयार है';

  @override
  String get bannerRewardsTitle => 'बहुत बढ़िया। थोड़ी और खुशी।';

  @override
  String get bannerRewardsBody => 'अपने ऑफ़र और स्क्रैच रिवॉर्ड देखें';

  @override
  String get secretTagline => 'थोड़ी सी परवाह बहुत दूर तक जाती है।';

  @override
  String get secretSemantics => 'कायलो। परवाह से बनाया गया।';

  @override
  String get addPaymentMethod => 'भुगतान का तरीका जोड़ें';

  @override
  String get cardExpiry => 'समाप्ति (MM/YY)';

  @override
  String get cardHolderName => 'कार्ड पर नाम';

  @override
  String get cardNumber => 'कार्ड नंबर';

  @override
  String get defaultTag => 'डिफ़ॉल्ट';

  @override
  String get deletePaymentMethodConfirm =>
      'यह भुगतान तरीका हटाएँ? आप इसे कभी भी फिर से जोड़ सकते हैं।';

  @override
  String get noPaymentMethods => 'कोई सहेजा हुआ भुगतान तरीका नहीं';

  @override
  String get noPaymentMethodsSubtitle =>
      'अगली बार तेज़ी से भुगतान के लिए UPI ID या कार्ड सहेजें।';

  @override
  String get paymentMethodAdded => 'भुगतान तरीका सहेजा गया';

  @override
  String get paymentMethodRemoved => 'भुगतान तरीका हटाया गया';

  @override
  String get removeMethod => 'हटाएँ';

  @override
  String get savePaymentMethod => 'भुगतान तरीका सहेजें';

  @override
  String get setDefault => 'डिफ़ॉल्ट बनाएँ';

  @override
  String get upiId => 'UPI ID';

  @override
  String payCashAmount(String amount) {
    return 'काम पूरा होने पर कामगार को $amount नकद दें';
  }

  @override
  String paidCashAmount(String amount) {
    return '$amount नकद में भुगतान किया';
  }

  @override
  String get workerOnTheWay => 'आपका कामगार रास्ते में है';

  @override
  String get workerArrived => 'आपका कामगार पहुँच गया है';

  @override
  String get rateYourWorker => 'अपने कामगार को रेट करें';

  @override
  String get rateWorkerHint =>
      'कैसा रहा? एक-दो पंक्तियाँ दूसरे ग्राहकों की मदद करती हैं।';

  @override
  String get reviewTextHint => 'काम के बारे में थोड़ा लिखें (वैकल्पिक)';

  @override
  String get submitReview => 'समीक्षा भेजें';

  @override
  String get reviewSubmitted => 'धन्यवाद, आपकी समीक्षा मिल गई';

  @override
  String get yourReview => 'आपकी समीक्षा';

  @override
  String get editReview => 'बदलें';

  @override
  String get ratingRequired => 'पहले स्टार रेटिंग चुनें';

  @override
  String starLabel(int count) {
    return '5 में से $count स्टार';
  }

  @override
  String get addOns => 'ऐड-ऑन';

  @override
  String addOnsIncluded(String list) {
    return 'ऐड-ऑन: $list';
  }

  @override
  String get slotBooked => 'बुक हो चुका';

  @override
  String get slotTakenMessage =>
      'यह समय इस कामगार के लिए पहले से बुक है। दूसरा समय चुनें।';

  @override
  String get partnerAccountNotAllowed =>
      'यह Kaylo Partner खाता है। कृपया Kaylo Partner ऐप का उपयोग करें।';

  @override
  String get customerProfileUnavailable =>
      'हम आपकी ग्राहक प्रोफ़ाइल सत्यापित नहीं कर सके। अपना कनेक्शन जाँचें और फिर से साइन इन करें।';

  @override
  String get yourDoctor => 'आपके डॉक्टर';

  @override
  String get yourCaregiver => 'आपके केयरगिवर';

  @override
  String get doctorPending =>
      'Kaylo Care आपके डॉक्टर की पुष्टि कर रहा है। पूरा होते ही हम आपको बता देंगे।';

  @override
  String get caregiverPending =>
      'Kaylo Care आपके केयरगिवर की पुष्टि कर रहा है। पूरा होते ही हम आपको बता देंगे।';

  @override
  String get careRequestHandled => 'Kaylo Care टीम इस अनुरोध को संभाल रही है।';

  @override
  String get patientLabel => 'मरीज़';

  @override
  String get appointmentTime => 'अपॉइंटमेंट का समय';

  @override
  String get startsAt => 'शुरू होगा';

  @override
  String hoursCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे',
      one: '1 घंटा',
    );
    return '$_temp0';
  }

  @override
  String get cancelCareBookingMessage =>
      'यह Care बुकिंग रद्द हो जाएगी। आप कभी भी फिर से बुक कर सकते हैं।';

  @override
  String get bookingNotes => 'नोट्स';

  @override
  String get chatTyping => 'लिख रहे हैं...';

  @override
  String get chatSendFailed =>
      'संदेश नहीं भेजा गया। आपका संदेश यहाँ सुरक्षित है। फिर भेजने के लिए दबाएँ।';

  @override
  String get chatReadOnly =>
      'यह बुकिंग समाप्त हो गई है। आप पुराने संदेश पढ़ सकते हैं।';

  @override
  String get sendMessage => 'संदेश भेजें';

  @override
  String get chatLoadFailed => 'यह बातचीत लोड नहीं हुई। फिर कोशिश करें।';

  @override
  String get partnerOnDuty => 'ड्यूटी पर';

  @override
  String get partnerOffDuty => 'ड्यूटी पर नहीं · बुकिंग शेड्यूल करें';

  @override
  String get bookingRequested => 'बुकिंग का अनुरोध भेजा गया';

  @override
  String get bookingAwaitingPartner =>
      'आपका अनुरोध भेज दिया गया है। बुकिंग के लिए पार्टनर की पुष्टि का इंतज़ार है।';

  @override
  String get hideReviewName => 'मेरा नाम छिपाएँ';

  @override
  String get hideReviewNameHint =>
      '“Verified customer” दिखेगा। पेशेवर फिर भी आपकी बुकिंग पहचान सकते हैं।';

  @override
  String get bookingCallTitle => 'Kaylo कॉल';

  @override
  String get bookingCallConnected => 'बुकिंग कॉल';

  @override
  String get bookingCallIncoming => 'Kaylo कॉल आ रही है';

  @override
  String get bookingCallIncomingBody =>
      'बुकिंग से जुड़ा व्यक्ति कॉल कर रहा है।';

  @override
  String get bookingCallFailed =>
      'कॉल शुरू नहीं हुई। कनेक्शन जाँचें और दोबारा कोशिश करें।';
}
