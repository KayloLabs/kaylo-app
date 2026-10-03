// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String sosCallWaiting(String name) {
    return 'അടുത്തത്: $name. Kaylo-യിൽ 3 സെക്കൻഡിന് ശേഷം വിളിക്കും.';
  }

  @override
  String sosCallProgress(int attempted, int total) {
    return '$total കോളുകളിൽ $attempted വിളിക്കാൻ ശ്രമിച്ചു';
  }

  @override
  String get sosCallsFinished =>
      'വിളിക്കുന്ന ക്രമം പൂർത്തിയായി. വിളിക്കാൻ ശ്രമിച്ചത് മറുപടി ലഭിച്ചതായി സ്ഥിരീകരിക്കുന്നില്ല.';

  @override
  String get sosCallsStopped =>
      'ശേഷിക്കുന്ന കോളുകൾ നിർത്തി. നിലവിലെ കോൾ ഫോൺ ആപ്പിൽ അവസാനിപ്പിക്കാം.';

  @override
  String get sosStopCalls => 'ശേഷിക്കുന്ന കോളുകൾ നിർത്തുക';

  @override
  String get sosAndroidOnly => 'SIM കോളുകൾ Android ഫോണുകളിൽ ലഭ്യമാണ്.';

  @override
  String careDosesTaken(int taken, int total) {
    return '$total ഡോസുകളിൽ $taken എടുത്തു';
  }

  @override
  String get hello => 'നമസ്കാരം';

  @override
  String get searchServices => 'സേവനങ്ങൾ തിരയുക…';

  @override
  String get whatDoYouNeedHelpWith => 'നിങ്ങൾക്ക് എന്ത് സഹായമാണ് വേണ്ടത്?';

  @override
  String get home => 'വീട്';

  @override
  String get homeSubtitle => 'നിങ്ങളുടെ വീടിനുള്ള\nപരിഹാരങ്ങൾ.';

  @override
  String get farm => 'കൃഷി';

  @override
  String get farmSubtitle => 'നിങ്ങളുടെ കൃഷിയിടത്തിന്\nപരിചരണവും പിന്തുണയും.';

  @override
  String get care => 'പരിചരണം';

  @override
  String get careSubtitle => 'നിങ്ങളുടെ പ്രിയപ്പെട്ടവർക്കുള്ള\nസഹായം.';

  @override
  String get popularServices => 'ജനപ്രിയ സേവനങ്ങൾ';

  @override
  String get seeAll => 'എല്ലാം കാണുക';

  @override
  String get comingSoon => 'ഉടൻ വരുന്നു';

  @override
  String get howCanWeHelp => 'ഇന്ന് ഞങ്ങൾ നിങ്ങളെ എങ്ങനെ സഹായിക്കും?';

  @override
  String get heroCoconutTitle => 'തേങ്ങ പറിക്കുന്നത്\nഎളുപ്പമായി';

  @override
  String get heroCoconutSubtitle =>
      'നിങ്ങളുടെ പ്രദേശത്തെ\nവിശ്വസ്തരെ ബുക്ക് ചെയ്യുക';

  @override
  String get heroCleanTitle => 'നിങ്ങളുടെ വീട്\nവൃത്തിയാക്കാം';

  @override
  String get heroCleanSubtitle => 'പ്രൊഫഷണൽ സേവനങ്ങൾ\nനിങ്ങളുടെ പടിവാതിൽക്കൽ';

  @override
  String get heroPlumberTitle => 'വിദഗ്ദ്ധരായ പ്ലംബർമാരും\nകർഷകരും തയ്യാർ';

  @override
  String get heroPlumberSubtitle => 'എല്ലാ ജോലികൾക്കും\nവിശ്വസ്തരായ സഹായികൾ';

  @override
  String get heroBookNow => 'ഇപ്പോൾ ബുക്ക് ചെയ്യുക';

  @override
  String get heroExplore => 'അന്വേഷിക്കുക';

  @override
  String get heroHireNow => 'ഇപ്പോൾ വാടകയ്ക്കെടുക്കുക';

  @override
  String get promoTitle => 'പ്രധാനപ്പെട്ട ജോലികൾ ഒരിക്കലും നഷ്ടപ്പെടുത്തരുത്';

  @override
  String get promoSubtitle =>
      'റിമൈൻഡറുകൾ സജ്ജമാക്കുക, ബാക്കി\nകാര്യങ്ങൾ ഞങ്ങൾ നോക്കാം.';

  @override
  String get promoButton => 'റിമൈൻഡർ സജ്ജമാക്കുക';

  @override
  String get recommendedForYou => 'നിങ്ങൾക്കായി ശുപാർശ ചെയ്യുന്നവ';

  @override
  String get settings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get appearance => 'രൂപം';

  @override
  String get theme => 'തീം';

  @override
  String get themeSystem => 'സിസ്റ്റം';

  @override
  String get themeLight => 'ലൈറ്റ്';

  @override
  String get themeDark => 'ഡാർക്ക്';

  @override
  String get language => 'ഭാഷ';

  @override
  String get accessibility => 'പ്രാപ്യത';

  @override
  String get careModeTitle => 'കെയ്‌ലോ കെയർ മോഡ്';

  @override
  String get careModeSubtitle =>
      'മുതിർന്നവർക്കായി വലിയ അക്ഷരങ്ങളും ലളിതമായ സ്ക്രീനുകളും';

  @override
  String get notifications => 'അറിയിപ്പുകൾ';

  @override
  String get pushNotifications => 'പുഷ് അറിയിപ്പുകൾ';

  @override
  String get pushNotificationsSubtitle => 'ബുക്കിംഗ് വിവരങ്ങളും ഓഫറുകളും';

  @override
  String get about => 'ആപ്പിനെക്കുറിച്ച്';

  @override
  String get version => 'പതിപ്പ്';

  @override
  String get termsPrivacy => 'നിബന്ധനകളും സ്വകാര്യതയും';

  @override
  String get madeInKerala => 'കേരളത്തിൽ ♥ത്തോടെ നിർമ്മിച്ചത്';

  @override
  String get profile => 'പ്രൊഫൈൽ';

  @override
  String get statBookings => 'ബുക്കിംഗുകൾ';

  @override
  String get statRating => 'റേറ്റിംഗ്';

  @override
  String get statSaved => 'സേവ് ചെയ്തവ';

  @override
  String get account => 'അക്കൗണ്ട്';

  @override
  String get myBookings => 'എന്റെ ബുക്കിംഗുകൾ';

  @override
  String get myBookingsSubtitle => 'നിങ്ങളുടെ സേവനങ്ങൾ ട്രാക്ക് ചെയ്യുക';

  @override
  String get savedAddresses => 'സേവ് ചെയ്ത വിലാസങ്ങൾ';

  @override
  String get paymentMethods => 'പേയ്മെന്റ് രീതികൾ';

  @override
  String get preferences => 'മുൻഗണനകൾ';

  @override
  String get settingsSubtitle => 'തീം, ഭാഷ, കെയർ മോഡ്, അറിയിപ്പുകൾ';

  @override
  String get support => 'സഹായം';

  @override
  String get helpSupport => 'സഹായവും പിന്തുണയും';

  @override
  String get rateKaylo => 'കെയ്‌ലോയെ റേറ്റ് ചെയ്യുക';

  @override
  String get rateThanks => 'സ്നേഹത്തിന് നന്ദി!';

  @override
  String get logOut => 'ലോഗൗട്ട്';

  @override
  String get logOutConfirmTitle => 'ലോഗൗട്ട് ചെയ്യണോ?';

  @override
  String get logOutConfirmMessage =>
      'സേവനങ്ങൾ ബുക്ക് ചെയ്യാൻ വീണ്ടും സൈൻ ഇൻ ചെയ്യേണ്ടിവരും.';

  @override
  String get cancel => 'റദ്ദാക്കുക';

  @override
  String get profileEditSoon => 'സൈൻ-ഇനോടൊപ്പം പ്രൊഫൈൽ എഡിറ്റിംഗ് വരും';

  @override
  String get editProfile => 'പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യുക';

  @override
  String get firstName => 'പേര്';

  @override
  String get lastName => 'കുടുംബപ്പേര്';

  @override
  String get profileUpdated => 'പ്രൊഫൈൽ പുതുക്കി';

  @override
  String get statCompleted => 'പൂർത്തിയായി';

  @override
  String get kayloCare => 'കെയ്‌ലോ കെയർ';

  @override
  String get careHomeGreeting => 'ഇന്ന് ഞങ്ങൾക്ക് നിങ്ങളെ എങ്ങനെ സഹായിക്കാം?';

  @override
  String get medicineReminders => 'മരുന്ന് ഓർമ്മപ്പെടുത്തലുകൾ';

  @override
  String get medicineRemindersSubtitle => 'ഒരു ഡോസും നഷ്ടപ്പെടുത്തരുത്';

  @override
  String get doctorAppointment => 'ഡോക്ടർ അപ്പോയിന്റ്മെന്റ്';

  @override
  String get doctorAppointmentSubtitle =>
      'സന്ദർശനമോ ടെലികൺസൾട്ടോ ബുക്ക് ചെയ്യുക';

  @override
  String get emergencySos => 'അടിയന്തര SOS';

  @override
  String get emergencySosSubtitle => 'കുടുംബത്തെ ഉടൻ അറിയിക്കുക';

  @override
  String get caregiverBooking => 'പരിചാരകനെ ബുക്ക് ചെയ്യുക';

  @override
  String get caregiverBookingSubtitle => 'വീട്ടിൽ വിശ്വസ്ത സഹായം';

  @override
  String get themeCareOverride =>
      'കെയർ മോഡ് ഓണായിരിക്കുമ്പോൾ തീം അതിനെ പിന്തുടരും';

  @override
  String get languageSettings => 'ഭാഷാ ക്രമീകരണങ്ങൾ';

  @override
  String get voiceSearch => 'വോയ്സ് തിരയൽ';

  @override
  String get voiceListening => 'കേൾക്കുന്നു…';

  @override
  String get voiceTapToSpeak => 'ഇപ്പോൾ സംസാരിക്കൂ, ഏത് ആപ്പ് ഭാഷയിലും';

  @override
  String get voiceYouSaid => 'നിങ്ങൾ പറഞ്ഞത്';

  @override
  String get voiceNoMatch =>
      'അനുയോജ്യമായ സേവനം കണ്ടെത്തിയില്ല. വീണ്ടും ശ്രമിക്കണോ?';

  @override
  String get voiceUnavailable => 'ഈ ഉപകരണത്തിൽ വോയ്സ് തിരയൽ ലഭ്യമല്ല';

  @override
  String get voiceTryAgain => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get voiceMicDenied =>
      'മൈക്രോഫോൺ അനുമതി നിരസിച്ചു. വോയ്സ് തിരയലിന് ബ്രൗസറിലോ ഫോൺ ക്രമീകരണങ്ങളിലോ അനുവദിക്കുക.';

  @override
  String get homeServices => 'വീട്ടു സേവനങ്ങൾ';

  @override
  String get allHomeServices => 'എല്ലാ വീട്ടു സേവനങ്ങളും';

  @override
  String get exploreHomeServices =>
      'പരിശോധിച്ചുറപ്പിച്ച പ്രൊഫഷണലുകളെ കണ്ടെത്തുക';

  @override
  String get serviceDetails => 'സേവന വിവരങ്ങൾ';

  @override
  String get professionalAtDoorstep =>
      'പ്രൊഫഷണൽ സേവനങ്ങൾ നിങ്ങളുടെ പടിവാതിൽക്കൽ';

  @override
  String get popularSubServices => 'ജനപ്രിയ ഉപസേവനങ്ങൾ';

  @override
  String get selectSubServices => 'ഉപസേവനങ്ങൾ തിരഞ്ഞെടുക്കുക';

  @override
  String get startingFrom => 'തുടങ്ങുന്നത്';

  @override
  String get bookNow => 'ഇപ്പോൾ ബുക്ക് ചെയ്യുക';

  @override
  String get bookService => 'സേവനം ബുക്ക് ചെയ്യുക';

  @override
  String get workersAvailable => 'സഹായികൾ ലഭ്യമാണ്';

  @override
  String get availableWorkers => 'ലഭ്യമായ സഹായികൾ';

  @override
  String get sortAndFilter => 'ക്രമീകരിക്കുക & ഫിൽട്ടർ';

  @override
  String get sortBy => 'ഇതുപ്രകാരം ക്രമീകരിക്കുക';

  @override
  String get rating => 'റേറ്റിംഗ്';

  @override
  String get priceLowToHigh => 'വില: കുറഞ്ഞതിൽ നിന്ന് കൂടിയതിലേക്ക്';

  @override
  String get priceHighToLow => 'വില: കൂടിയതിൽ നിന്ന് കുറഞ്ഞതിലേക്ക്';

  @override
  String get experience => 'പരിചയം';

  @override
  String get distance => 'ദൂരം';

  @override
  String get filter => 'ഫിൽട്ടർ';

  @override
  String get priceRange => 'വില പരിധി';

  @override
  String get availability => 'ലഭ്യത';

  @override
  String get availableToday => 'ഇന്ന് ലഭ്യമാണ്';

  @override
  String get minRating => 'കുറഞ്ഞ റേറ്റിംഗ്';

  @override
  String get verifiedOnly => 'പരിശോധിച്ചുറപ്പിച്ചവർ മാത്രം';

  @override
  String get apply => 'പ്രയോഗിക്കുക';

  @override
  String get reset => 'റീസെറ്റ്';

  @override
  String get noWorkersFound => 'സഹായികളെ കണ്ടെത്താനായില്ല';

  @override
  String get workerProfile => 'പ്രൊഫൈൽ';

  @override
  String get completedJobs => 'പൂർത്തിയാക്കിയ ജോലികൾ';

  @override
  String get yearsExperience => 'വർഷത്തെ പരിചയം';

  @override
  String get trustScore => 'വിശ്വാസ്യത സ്കോർ';

  @override
  String get responseTime => 'പ്രതികരണ സമയം';

  @override
  String get certifications => 'സർട്ടിഫിക്കേഷനുകൾ';

  @override
  String get reviews => 'അവലോകനങ്ങൾ';

  @override
  String get customerReviews => 'ഉപഭോക്തൃ അവലോകനങ്ങൾ';

  @override
  String get verifiedProfessional => 'പരിശോധിച്ചുറപ്പിച്ച സഹായി';

  @override
  String get searchServicesOrWorkers => 'സേവനങ്ങളോ സഹായികളെയോ തിരയുക…';

  @override
  String get recentSearches => 'സമീപകാല തിരയലുകൾ';

  @override
  String get clearAll => 'എല്ലാം മായ്ക്കുക';

  @override
  String get services => 'സേവനങ്ങൾ';

  @override
  String get professionals => 'പ്രൊഫഷണലുകൾ';

  @override
  String get noResultsFound => 'ഫലങ്ങളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get tryDifferentSearch => 'മറ്റൊരു സേവനമോ സഹായിയെയോ തിരയാൻ ശ്രമിക്കുക';

  @override
  String get selectSpecialty => 'വിഭാഗം തിരഞ്ഞെടുക്കുക';

  @override
  String get availableDoctors => 'ലഭ്യമായ ഡോക്ടർമാർ';

  @override
  String get consultationFee => 'കൺസൾട്ടേഷൻ ഫീസ്';

  @override
  String get selectDate => 'തീയതി';

  @override
  String get selectTimeSlot => 'സമയം';

  @override
  String get morning => 'രാവിലെ';

  @override
  String get afternoon => 'ഉച്ചയ്ക്ക്';

  @override
  String get evening => 'വൈകുന്നേരം';

  @override
  String get consultationType => 'കൺസൾട്ടേഷൻ തരം';

  @override
  String get homeVisit => 'ഹോം വിസിറ്റ്';

  @override
  String get teleconsult => 'വീഡിയോ ടെലികൺസൾട്ട്';

  @override
  String get confirmAppointment => 'അപ്പോയിന്റ്മെന്റ് ഉറപ്പാക്കുക';

  @override
  String get upcomingAppointments => 'വരാനിരിക്കുന്ന അപ്പോയിന്റ്മെന്റുകൾ';

  @override
  String get appointmentConfirmed => 'അപ്പോയിന്റ്മെന്റ് സ്ഥിരീകരിച്ചു!';

  @override
  String get appointmentDetails =>
      'നിങ്ങളുടെ അപ്പോയിന്റ്മെന്റ് നിശ്ചയിച്ചിരിക്കുന്നു.';

  @override
  String get selectCaregiver => 'പരിചാരകനെ തിരഞ്ഞെടുക്കുക';

  @override
  String get hours => 'മണിക്കൂർ';

  @override
  String get selectHours => 'മണിക്കൂറുകൾ തിരഞ്ഞെടുക്കുക';

  @override
  String get careType => 'പരിചരണ തരം';

  @override
  String get elderlyCare => 'മുതിർന്നവരുടെ പരിചരണം';

  @override
  String get postOpCare => 'ചികിത്സാനന്തര പരിചരണം';

  @override
  String get companionship => 'സഹവാസം';

  @override
  String get mobilityAssistance => 'സഞ്ചാര സഹായം';

  @override
  String get totalAmount => 'ആകെ തുക';

  @override
  String get caregiverBooked => 'പരിചാരകനെ ബുക്ക് ചെയ്തു!';

  @override
  String get caregiverBookingSuccess => 'നിങ്ങളുടെ അഭ്യർത്ഥന സമർപ്പിച്ചു.';

  @override
  String get nearYou => 'നിങ്ങൾക്ക് സമീപം';

  @override
  String get farmServices => 'കൃഷി സേവനങ്ങൾ';

  @override
  String get farmServicesTagline =>
      'പരിശോധിച്ച തെങ്ങുകയറ്റക്കാരും വിളവെടുപ്പുകാരും കർഷകത്തൊഴിലാളികളും. മരത്തിനോ മണിക്കൂറിനോ ബുക്ക് ചെയ്യാം.';

  @override
  String get noServicesTitle => 'സേവനങ്ങൾ ഇതുവരെയില്ല';

  @override
  String get noServicesDescription =>
      'തൊഴിലാളികൾ ചേരുന്നതനുസരിച്ച് കൃഷി സേവനങ്ങൾ ഇവിടെ കാണാം.';

  @override
  String perUnit(String unit) {
    return '$unit ഒന്നിന്';
  }

  @override
  String get unitTree => 'മരം';

  @override
  String get unitHour => 'മണിക്കൂർ';

  @override
  String get unitVisit => 'സന്ദർശനം';

  @override
  String unitTreeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മരങ്ങൾ',
      one: '1 മരം',
    );
    return '$_temp0';
  }

  @override
  String unitHourCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മണിക്കൂർ',
      one: '1 മണിക്കൂർ',
    );
    return '$_temp0';
  }

  @override
  String unitVisitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count സന്ദർശനങ്ങൾ',
      one: '1 സന്ദർശനം',
    );
    return '$_temp0';
  }

  @override
  String get serviceStandards => 'തൊഴിലാളി ഉറപ്പുനൽകുന്നത്';

  @override
  String get standardSafetyHarness => 'ഓരോ കയറ്റത്തിലും സുരക്ഷാ ഹാർനെസ്';

  @override
  String get standardBunchProtection => 'കുലകൾ കയറിൽ ഇറക്കും, താഴേക്കിടില്ല';

  @override
  String get standardDebrisCleared => 'പോകുംമുമ്പ് ഓലയും ചകിരിയും നീക്കും';

  @override
  String get standardGroundNets => 'താഴെയുള്ള വിളകൾ സംരക്ഷിക്കാൻ വലകൾ';

  @override
  String get standardPowerLineGuard => 'വൈദ്യുതി ലൈനുകളിൽ നിന്ന് സുരക്ഷിത അകലം';

  @override
  String get standardWoodChipping =>
      'മുറിച്ച ചില്ലകൾ ചെറുതാക്കി അടുക്കിവയ്ക്കും';

  @override
  String get standardEcoCompost => 'ജൈവ വളവും പുതയും മാത്രം';

  @override
  String get standardPestPrevention => 'ഓരോ സന്ദർശനത്തിലും കീട പരിശോധന';

  @override
  String get standardBoundaryClearing => 'അതിരുകളും ചാലുകളും വൃത്തിയാക്കും';

  @override
  String get standardVerifiedWorker => 'ഐഡി പരിശോധിച്ച തൊഴിലാളി';

  @override
  String get standardOnTimeArrival => 'ബുക്ക് ചെയ്ത സമയത്ത് എത്തും';

  @override
  String get standardFairPrice => 'ജോലി തുടങ്ങുംമുമ്പ് വില ഉറപ്പിക്കും';

  @override
  String workersNearYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'നിങ്ങളുടെ അടുത്ത് $count പരിശോധിച്ച തൊഴിലാളികൾ',
      one: 'നിങ്ങളുടെ അടുത്ത് 1 പരിശോധിച്ച തൊഴിലാളി',
    );
    return '$_temp0';
  }

  @override
  String get noWorkersYet =>
      'ഈ സേവനത്തിനുള്ള തൊഴിലാളികളെ ചേർത്തുകൊണ്ടിരിക്കുന്നു';

  @override
  String get liveTotalNote =>
      'അടുത്ത ഘട്ടത്തിൽ എണ്ണം തിരഞ്ഞെടുക്കുമ്പോൾ ആകെ തുക തത്സമയം മാറും.';

  @override
  String get scheduleTitle => 'ഷെഡ്യൂൾ';

  @override
  String get change => 'മാറ്റുക';

  @override
  String get quantity => 'എണ്ണം';

  @override
  String priceEach(String price) {
    return 'ഒന്നിന് $price';
  }

  @override
  String get calculation => 'കണക്ക്';

  @override
  String breakdown(String price, String units) {
    return '$price × $units';
  }

  @override
  String get total => 'ആകെ';

  @override
  String get farmAddress => 'കൃഷിയിടത്തിന്റെ വിലാസം';

  @override
  String get farmAddressHint => 'വീട്ടുപേര്, തെരുവ്, സ്ഥലം';

  @override
  String get addressRequired => 'കൃഷിയിടത്തിന്റെ വിലാസം നൽകുക';

  @override
  String get serviceAddress => 'സേവന വിലാസം';

  @override
  String get serviceAddressRequired => 'സേവന വിലാസം നൽകുക';

  @override
  String get worker => 'തൊഴിലാളി';

  @override
  String get popularSearches => 'ജനപ്രിയ തിരയലുകൾ';

  @override
  String get continueToPayment => 'പേയ്‌മെന്റിലേക്ക്';

  @override
  String get paymentTitle => 'പേയ്‌മെന്റ്';

  @override
  String get orderSummary => 'ഓർഡർ വിവരം';

  @override
  String get service => 'സേവനം';

  @override
  String get date => 'തീയതി';

  @override
  String get time => 'സമയം';

  @override
  String get rate => 'നിരക്ക്';

  @override
  String get totalPayable => 'അടയ്ക്കേണ്ട തുക';

  @override
  String get paymentMethod => 'പേയ്‌മെന്റ് രീതി';

  @override
  String get payUpi => 'UPI';

  @override
  String get payUpiSubtitle => 'Google Pay, PhonePe, Paytm';

  @override
  String get payCard => 'ക്രെഡിറ്റ് അല്ലെങ്കിൽ ഡെബിറ്റ് കാർഡ്';

  @override
  String get payCardSubtitle => 'Visa, Mastercard, RuPay';

  @override
  String get payAfter => 'സേവനത്തിന് ശേഷം അടയ്ക്കാം';

  @override
  String get payAfterSubtitle => 'ജോലി കഴിഞ്ഞ് തൊഴിലാളിക്ക് നേരിട്ട് നൽകാം';

  @override
  String confirmAndPay(String amount) {
    return '$amount അടച്ച് ഉറപ്പിക്കുക';
  }

  @override
  String get confirmBooking => 'ബുക്കിംഗ് ഉറപ്പിക്കുക';

  @override
  String get paymentFailed => 'പേയ്‌മെന്റ് പൂർത്തിയായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get draftMissing =>
      'ഈ ഘട്ടത്തിന് ഒരു ബുക്കിംഗ് പുരോഗമിക്കണം. കൃഷി സേവനങ്ങളിൽ നിന്ന് വീണ്ടും തുടങ്ങുക.';

  @override
  String get bookingConfirmed => 'ബുക്കിംഗ് ഉറപ്പായി';

  @override
  String bookingConfirmedSubtitle(String date, String time) {
    return '$date, $timeന് തൊഴിലാളി എത്തും';
  }

  @override
  String get bookingId => 'ബുക്കിംഗ് ഐഡി';

  @override
  String get status => 'നില';

  @override
  String get payment => 'പേയ്‌മെന്റ്';

  @override
  String get viewMyBookings => 'എന്റെ ബുക്കിംഗുകൾ കാണുക';

  @override
  String get backToHome => 'ഹോമിലേക്ക് മടങ്ങുക';

  @override
  String get statusPending => 'കാത്തിരിക്കുന്നു';

  @override
  String get statusConfirmed => 'ഉറപ്പായി';

  @override
  String get statusInProgress => 'നടന്നുകൊണ്ടിരിക്കുന്നു';

  @override
  String get statusCompleted => 'പൂർത്തിയായി';

  @override
  String get statusCancelled => 'റദ്ദാക്കി';

  @override
  String get noBookingsTitle => 'ബുക്കിംഗുകൾ ഇതുവരെയില്ല';

  @override
  String get noBookingsDescription =>
      'കൃഷിയോ വീട്ടുസേവനമോ ബുക്ക് ചെയ്താൽ ഇവിടെ കാണാം.';

  @override
  String get bookAService => 'സേവനം ബുക്ക് ചെയ്യുക';

  @override
  String get upcoming => 'വരാനുള്ളവ';

  @override
  String get past => 'കഴിഞ്ഞവ';

  @override
  String get somethingWentWrong => 'എന്തോ പിഴവ് സംഭവിച്ചു';

  @override
  String get messages => 'സന്ദേശങ്ങൾ';

  @override
  String get messagesSubtitle => 'ബുക്ക് ചെയ്ത തൊഴിലാളികളുമായി ചാറ്റ് ചെയ്യുക';

  @override
  String get noMessagesTitle => 'സംഭാഷണങ്ങൾ ഇതുവരെയില്ല';

  @override
  String get noMessagesDescription =>
      'ഒരു തൊഴിലാളിയെ ബുക്ക് ചെയ്താൽ ഇവിടെ സന്ദേശം അയയ്ക്കാം.';

  @override
  String get noMessagesInThread => 'സംഭാഷണം തുടങ്ങാൻ ഹലോ പറയൂ';

  @override
  String get online => 'ഓൺലൈൻ';

  @override
  String get offline => 'ഓഫ്‌ലൈൻ';

  @override
  String get typeMessage => 'സന്ദേശം എഴുതുക';

  @override
  String get todaysMedicines => 'ഇന്നത്തെ മരുന്നുകൾ';

  @override
  String get medicinesSubtitle => 'മരുന്ന് കഴിച്ച ശേഷം വൃത്തത്തിൽ തൊടുക';

  @override
  String pendingDoses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഡോസ് ബാക്കി',
      one: '1 ഡോസ് ബാക്കി',
      zero: 'എല്ലാ മരുന്നും കഴിച്ചു',
    );
    return '$_temp0';
  }

  @override
  String nextDose(String name, String time) {
    return 'അടുത്തത്: $timeന് $name';
  }

  @override
  String get addReminder => 'ഓർമ്മപ്പെടുത്തൽ ചേർക്കുക';

  @override
  String get medicineName => 'മരുന്നിന്റെ പേര്';

  @override
  String get medicineNameHint => 'ഉദാ. BP ഗുളിക';

  @override
  String get dosage => 'അളവ്';

  @override
  String get dosageHint => 'ഉദാ. പ്രഭാതഭക്ഷണത്തിന് ശേഷം 1 ഗുളിക';

  @override
  String get reminderTime => 'ഓർമ്മപ്പെടുത്തൽ സമയം';

  @override
  String get save => 'സേവ് ചെയ്യുക';

  @override
  String addedBy(String name) {
    return 'ചേർത്തത്: $name';
  }

  @override
  String markedTaken(String name) {
    return '$name കഴിച്ചതായി അടയാളപ്പെടുത്തി';
  }

  @override
  String markedPending(String name) {
    return '$name ബാക്കിയായി അടയാളപ്പെടുത്തി';
  }

  @override
  String get nameRequired => 'പേര് നൽകുക';

  @override
  String get phoneRequired => 'ഫോൺ നമ്പർ നൽകുക';

  @override
  String get noRemindersTitle => 'ഓർമ്മപ്പെടുത്തലുകൾ ഇതുവരെയില്ല';

  @override
  String get noRemindersDescription =>
      'മരുന്നുകൾ ചേർക്കൂ, കൃത്യസമയത്ത് കെയ്‌ലോ ഓർമ്മിപ്പിക്കും.';

  @override
  String get pressAndHold => 'അമർത്തിപ്പിടിക്കുക';

  @override
  String get holdSeconds => '3 സെക്കൻഡ് പിടിക്കുക';

  @override
  String secondsShort(int seconds) {
    return '$seconds സെ';
  }

  @override
  String get sosHoldHint =>
      'SIM വഴി ബന്ധങ്ങളെ വിളിക്കാൻ 3 സെക്കൻഡ് പിടിക്കുക. പ്രാഥമിക ബന്ധത്തെ ആദ്യം വിളിക്കും. ഓരോ കോളും അവസാനിച്ച ശേഷം തുടരാൻ Kaylo-യിലേക്ക് മടങ്ങുക. സാധാരണ SIM നിരക്കുകൾ ബാധകമാണ്.';

  @override
  String get sosReleasedEarly => 'വിളിക്കാൻ 3 സെക്കൻഡ് അമർത്തിപ്പിടിക്കുക';

  @override
  String get sosSentTitle => 'സഹായം വരുന്നു';

  @override
  String sosSentContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ബന്ധങ്ങൾക്ക് ലൊക്കേഷനോടെ അലേർട്ട് അയച്ചു',
      one: '1 ബന്ധത്തിന് ലൊക്കേഷനോടെ അലേർട്ട് അയച്ചു',
    );
    return '$_temp0';
  }

  @override
  String sosCallingPrimary(String name) {
    return '$nameനെ വിളിക്കുന്നു';
  }

  @override
  String get sosNoContacts =>
      'അലേർട്ട് ലഭിക്കാൻ ആദ്യം ഒരു അടിയന്തര ബന്ധം ചേർക്കുക.';

  @override
  String get dismiss => 'അടയ്ക്കുക';

  @override
  String get emergencyContacts => 'അടിയന്തര ബന്ധങ്ങൾ';

  @override
  String get addContact => 'ബന്ധം ചേർക്കുക';

  @override
  String get contactName => 'പേര്';

  @override
  String get relationship => 'ബന്ധം';

  @override
  String get relationshipHint => 'ഉദാ. മകൾ';

  @override
  String get phoneNumber => 'ഫോൺ നമ്പർ';

  @override
  String get primary => 'പ്രധാനം';

  @override
  String get setAsPrimary => 'പ്രധാന ബന്ധമാക്കുക';

  @override
  String get removeContact => 'നീക്കം ചെയ്യുക';

  @override
  String get sosHistory => 'SOS ചരിത്രം';

  @override
  String alertsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count അലേർട്ടുകൾ അയച്ചു',
      one: '1 അലേർട്ട് അയച്ചു',
      zero: 'അലേർട്ടുകൾ അയച്ചിട്ടില്ല',
    );
    return '$_temp0';
  }

  @override
  String get noSosTitle => 'അലേർട്ടുകൾ അയച്ചിട്ടില്ല';

  @override
  String get noSosDescription =>
      'അയയ്ക്കുന്ന അലേർട്ടുകളും ആരെ അറിയിച്ചെന്നതും ഇവിടെ കാണാം.';

  @override
  String alertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ബന്ധങ്ങളെ അറിയിച്ചു',
      one: '1 ബന്ധത്തെ അറിയിച്ചു',
    );
    return '$_temp0';
  }

  @override
  String get sosStatusOpen => 'തുറന്നത്';

  @override
  String get sosStatusAcknowledged => 'കണ്ടു';

  @override
  String get sosStatusResolved => 'പരിഹരിച്ചു';

  @override
  String locationShared(String location) {
    return 'ലൊക്കേഷൻ പങ്കിട്ടു: $location';
  }

  @override
  String primaryContact(String name) {
    return 'പ്രധാന ബന്ധം: $name';
  }

  @override
  String get unitOrder => 'ഓർഡർ';

  @override
  String unitOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ഓർഡറുകൾ',
      one: '1 ഓർഡർ',
    );
    return '$_temp0';
  }

  @override
  String get standardPartsQuoted =>
      'സ്പെയർ പാർട്സിന്റെ വില മുൻകൂട്ടി അറിയിക്കും';

  @override
  String get standardCleanupAfter => 'പോകുംമുമ്പ് ജോലിസ്ഥലം വൃത്തിയാക്കും';

  @override
  String get standardBackgroundChecked => 'പശ്ചാത്തലം പരിശോധിച്ച കെയർഗിവർ';

  @override
  String get standardPrescriptionChecked =>
      'കുറിപ്പടി ഫാർമസിസ്റ്റ് പരിശോധിക്കും';

  @override
  String get careServices => 'കെയർ സേവനങ്ങൾ';

  @override
  String get allServices => 'എല്ലാ സേവനങ്ങളും';

  @override
  String get homeServicesTagline =>
      'കൃത്യസമയത്ത് എത്തി, ജോലി കഴിഞ്ഞ് വൃത്തിയാക്കുന്ന പ്ലംബർമാരും ഇലക്ട്രീഷ്യന്മാരും ക്ലീനർമാരും.';

  @override
  String get careServicesTagline =>
      'നിങ്ങൾ പരിപാലിക്കുന്നവർക്കായി പരിശീലനം നേടിയ കെയർഗിവർമാരും വീട്ടുപടിക്കൽ മരുന്നും.';

  @override
  String get allServicesTagline =>
      'വീട്, കൃഷി, കെയർ എന്നിവയിലായി കെയ്‌ലോ നൽകുന്ന എല്ലാ സേവനങ്ങളും.';

  @override
  String get useMyLocation => 'എന്റെ ലൊക്കേഷൻ ഉപയോഗിക്കുക';

  @override
  String get locating => 'കണ്ടെത്തുന്നു…';

  @override
  String get locationServicesOff =>
      'ലൊക്കേഷൻ സേവനങ്ങൾ ഓണാക്കി വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get locationDenied => 'ലൊക്കേഷൻ അനുമതി നൽകിയില്ല.';

  @override
  String get locationDeniedForever =>
      'കെയ്‌ലോയ്ക്ക് ലൊക്കേഷൻ തടഞ്ഞിരിക്കുന്നു. ഉപകരണ ക്രമീകരണങ്ങളിൽ അനുവദിക്കുക.';

  @override
  String get locationTimeout =>
      'GPS ലഭിച്ചില്ല. തുറന്ന സ്ഥലത്തേക്ക് മാറി വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get locationUnavailable => 'ലൊക്കേഷൻ ഇപ്പോൾ ലഭ്യമല്ല.';

  @override
  String get markAllRead => 'എല്ലാം വായിച്ചതായി അടയാളപ്പെടുത്തുക';

  @override
  String get noNotificationsTitle => 'പുതിയതൊന്നുമില്ല';

  @override
  String get noNotificationsDescription =>
      'ബുക്കിംഗ് അപ്ഡേറ്റുകളും സന്ദേശങ്ങളും ഓർമ്മപ്പെടുത്തലുകളും ഇവിടെ കാണാം.';

  @override
  String get today => 'ഇന്ന്';

  @override
  String get earlier => 'മുമ്പ്';

  @override
  String get justNow => 'ഇപ്പോൾ';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മിനിറ്റ് മുമ്പ്',
      one: '1 മിനിറ്റ് മുമ്പ്',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മണിക്കൂർ മുമ്പ്',
      one: '1 മണിക്കൂർ മുമ്പ്',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ദിവസം മുമ്പ്',
      one: 'ഇന്നലെ',
    );
    return '$_temp0';
  }

  @override
  String get bookingDetails => 'ബുക്കിംഗ് വിവരങ്ങൾ';

  @override
  String get cancelBookingTitle => 'ഈ ബുക്കിംഗ് റദ്ദാക്കണോ?';

  @override
  String get cancelBookingMessage =>
      'തൊഴിലാളിയെ ഒഴിവാക്കും. എപ്പോൾ വേണമെങ്കിലും വീണ്ടും ബുക്ക് ചെയ്യാം.';

  @override
  String get keepBooking => 'ബുക്കിംഗ് നിലനിർത്തുക';

  @override
  String get cancelBooking => 'ബുക്കിംഗ് റദ്ദാക്കുക';

  @override
  String get bookingCancelled => 'ബുക്കിംഗ് റദ്ദാക്കി';

  @override
  String get bookingCancelledBanner => 'ഈ ബുക്കിംഗ് റദ്ദാക്കിയതാണ്.';

  @override
  String get stepRequested => 'അഭ്യർത്ഥിച്ചു';

  @override
  String get stepConfirmed => 'ഉറപ്പായി';

  @override
  String get stepInProgress => 'നടക്കുന്നു';

  @override
  String get stepCompleted => 'പൂർത്തിയായി';

  @override
  String get assignedWorker => 'നിങ്ങളുടെ തൊഴിലാളി';

  @override
  String get noWorkerYet => 'സന്ദർശനത്തിന് മുമ്പ് ഒരു തൊഴിലാളിയെ നിയോഗിക്കും.';

  @override
  String get messageWorker => 'സന്ദേശം';

  @override
  String get reschedule => 'സമയം മാറ്റുക';

  @override
  String get bookingRescheduled => 'ബുക്കിംഗ് സമയം മാറ്റി';

  @override
  String get filters => 'ഫിൽട്ടറുകൾ';

  @override
  String get category => 'വിഭാഗം';

  @override
  String get applyFilters => 'പ്രയോഗിക്കുക';

  @override
  String get sortRelevance => 'പ്രസക്തി';

  @override
  String get sortPriceLowHigh => 'വില: കുറഞ്ഞത് മുതൽ';

  @override
  String get sortPriceHighLow => 'വില: കൂടിയത് മുതൽ';

  @override
  String get allCategories => 'എല്ലാം';

  @override
  String get noResultsTitle => 'സേവനങ്ങളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get noResultsDescription =>
      'മറ്റൊരു വാക്ക് ശ്രമിക്കൂ, അല്ലെങ്കിൽ പ്രശ്നം പറയൂ: \"പൈപ്പ് ചോരുന്നു\" എന്നും തിരയാം.';

  @override
  String resultsFor(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '\"$query\" എന്നതിന് $count ഫലങ്ങൾ',
      one: '\"$query\" എന്നതിന് 1 ഫലം',
    );
    return '$_temp0';
  }

  @override
  String get yourLocation => 'നിങ്ങളുടെ ലൊക്കേഷൻ';

  @override
  String get or => 'അല്ലെങ്കിൽ';

  @override
  String get townOrCity => 'പട്ടണം അല്ലെങ്കിൽ നഗരം';

  @override
  String get townHint => 'ഉദാ. കണ്ണൂർ';

  @override
  String get saveLocation => 'ലൊക്കേഷൻ സേവ് ചെയ്യുക';

  @override
  String get townRequired => 'പട്ടണമോ നഗരമോ നൽകുക';

  @override
  String locationUpdated(String label) {
    return 'ലൊക്കേഷൻ $label ആയി സജ്ജമാക്കി';
  }

  @override
  String get enableLocation => 'ലൊക്കേഷൻ ഓണാക്കുക';

  @override
  String get enableLocationSubtitle =>
      'അടുത്തുള്ള തൊഴിലാളികളെ കാണിക്കാനും SOS അലേർട്ടിൽ പങ്കിടാനും കെയ്‌ലോ നിങ്ങളുടെ ലൊക്കേഷൻ ഉപയോഗിക്കുന്നു.';

  @override
  String get locationWillAppear => 'നിങ്ങളുടെ ലൊക്കേഷൻ ഇവിടെ കാണാം';

  @override
  String get locateAgain => 'വീണ്ടും കണ്ടെത്തുക';

  @override
  String get continueLabel => 'തുടരുക';

  @override
  String get enterManually => 'സ്വയം നൽകുക';

  @override
  String get notNow => 'ഇപ്പോൾ വേണ്ട';

  @override
  String get noAddressesTitle => 'സേവ് ചെയ്ത വിലാസങ്ങളില്ല';

  @override
  String get noAddressesDescription =>
      'വീടോ കൃഷിയിടമോ ഒരിക്കൽ സേവ് ചെയ്താൽ ബുക്ക് ചെയ്യുമ്പോൾ ഒറ്റ ടാപ്പിൽ തിരഞ്ഞെടുക്കാം.';

  @override
  String get addAddress => 'വിലാസം ചേർക്കുക';

  @override
  String get defaultLabel => 'സ്ഥിരം';

  @override
  String get setAsDefault => 'സ്ഥിരമാക്കുക';

  @override
  String get removeAddress => 'നീക്കം ചെയ്യുക';

  @override
  String get addressLabel => 'ലേബൽ';

  @override
  String get labelHome => 'വീട്';

  @override
  String get labelFarm => 'കൃഷിയിടം';

  @override
  String get labelWork => 'ജോലിസ്ഥലം';

  @override
  String get labelOther => 'മറ്റുള്ളവ';

  @override
  String get labelOtherHint => 'ഉദാ. അമ്മയുടെ വീട്';

  @override
  String get addressLine => 'വിലാസം';

  @override
  String get addressSaved => 'വിലാസം സേവ് ചെയ്തു';

  @override
  String get contactUs => 'ഞങ്ങളെ ബന്ധപ്പെടുക';

  @override
  String get emailUs => 'ഇമെയിൽ അയയ്ക്കുക';

  @override
  String get reportProblem => 'പ്രശ്നം അറിയിക്കുക';

  @override
  String get reportProblemSubtitle => 'എന്താണ് തെറ്റിയതെന്ന് പറയൂ';

  @override
  String get reportProblemTemplate =>
      'എന്ത് സംഭവിച്ചു:\nആപ്പിൽ എവിടെ:\nഫോൺ മോഡൽ:';

  @override
  String get faq => 'പതിവ് ചോദ്യങ്ങൾ';

  @override
  String get faqBookQ => 'എങ്ങനെ സേവനം ബുക്ക് ചെയ്യാം?';

  @override
  String get faqBookA =>
      'ഹോം സ്ക്രീനിൽ നിന്നോ തിരയലിൽ നിന്നോ സേവനം തിരഞ്ഞെടുത്ത്, തീയതി, സമയം, എണ്ണം എന്നിവ നൽകി, വിലാസം ചേർത്ത് ഉറപ്പിക്കുക. ഉടൻ ബുക്കിംഗ് ഐഡി ലഭിക്കും; ബുക്കിംഗുകളിൽ ട്രാക്ക് ചെയ്യാം.';

  @override
  String get faqPayQ => 'എങ്ങനെ പണം അടയ്ക്കാം?';

  @override
  String get faqPayA =>
      'UPI, കാർഡ് എന്നിവ ഉറപ്പിക്കുമ്പോൾ ഈടാക്കും. ജോലി കഴിഞ്ഞ് തൊഴിലാളിക്ക് നേരിട്ട് നൽകാൻ \"സേവനത്തിന് ശേഷം അടയ്ക്കാം\" തിരഞ്ഞെടുക്കുക.';

  @override
  String get faqCancelQ => 'റദ്ദാക്കാനോ സമയം മാറ്റാനോ കഴിയുമോ?';

  @override
  String get faqCancelA =>
      'കഴിയും. ബുക്കിംഗുകളിൽ ബുക്കിംഗ് തുറന്ന് സമയം മാറ്റുകയോ റദ്ദാക്കുകയോ ചെയ്യുക. തൊഴിലാളി പുറപ്പെടുന്നതുവരെ രണ്ടും സൗജന്യമാണ്.';

  @override
  String get faqWorkersQ => 'തൊഴിലാളികളെ എങ്ങനെ പരിശോധിക്കുന്നു?';

  @override
  String get faqWorkersA =>
      'ലിസ്റ്റ് ചെയ്യുംമുമ്പ് ഓരോ തൊഴിലാളിയുടെയും ഐഡി പരിശോധിക്കും; ബുക്കിംഗ് പൂർത്തിയാക്കിയ ഉപഭോക്താക്കളിൽ നിന്ന് മാത്രമാണ് റേറ്റിംഗ്.';

  @override
  String get faqCareQ => 'കെയർ മോഡ് എന്താണ്?';

  @override
  String get faqCareA =>
      'മുതിർന്നവർക്കായി വലിയ അക്ഷരങ്ങളും ഉയർന്ന കോൺട്രാസ്റ്റുമുള്ള രൂപത്തിലേക്ക് ആപ്പ് മാറ്റുന്നു; മരുന്ന് ഓർമ്മപ്പെടുത്തലും ഒറ്റ അമർത്തലിൽ SOS ഉം ഉണ്ട്.';

  @override
  String get faqSosQ => 'SOS എങ്ങനെ പ്രവർത്തിക്കുന്നു?';

  @override
  String get faqSosA =>
      'SOS ബട്ടൺ മൂന്ന് സെക്കൻഡ് അമർത്തിപ്പിടിക്കുക. എല്ലാ അടിയന്തര ബന്ധങ്ങൾക്കും ലൊക്കേഷൻ ലഭിക്കും; പ്രധാന ബന്ധത്തെ വിളിക്കും.';

  @override
  String get helpFooter =>
      'കേരളത്തിലെ ഒരു ചെറിയ ടീമാണ് കെയ്‌ലോ നിർമ്മിക്കുന്നത്. എല്ലാ സന്ദേശങ്ങളും വായിക്കും.';

  @override
  String get couldNotOpenEmail => 'ഇമെയിൽ ആപ്പ് തുറക്കാനായില്ല.';

  @override
  String get rateTitle => 'കെയ്‌ലോ എങ്ങനെയുണ്ട്?';

  @override
  String get rateSubtitle =>
      'നിങ്ങളുടെ റേറ്റിംഗ് ടീമിന് അടുത്ത ശ്രദ്ധ എവിടെ വേണമെന്ന് പറയുന്നു.';

  @override
  String get rateComment => 'മെച്ചപ്പെടുത്തേണ്ടത് എന്തെങ്കിലും? (നിർബന്ധമില്ല)';

  @override
  String get submitRating => 'സമർപ്പിക്കുക';

  @override
  String get pickAStar => 'ആദ്യം ഒരു നക്ഷത്ര റേറ്റിംഗ് തിരഞ്ഞെടുക്കുക';

  @override
  String youRated(int stars) {
    return 'നിങ്ങൾ കെയ്‌ലോയ്ക്ക് 5-ൽ $stars നൽകി';
  }

  @override
  String get confirmLocation => 'ലൊക്കേഷൻ സ്ഥിരീകരിക്കുക';

  @override
  String get moveMapToPlacePin => 'പിൻ വയ്ക്കാൻ മാപ്പ് നീക്കുക';

  @override
  String get findingAddress => 'വിലാസം കണ്ടെത്തുന്നു…';

  @override
  String get selectedLocation => 'തിരഞ്ഞെടുത്ത ലൊക്കേഷൻ';

  @override
  String get mapUnavailable => 'മാപ്പ് പ്രിവ്യൂ ലഭ്യമല്ല';

  @override
  String get searchTownHint => 'പട്ടണമോ നഗരമോ തിരയുക';

  @override
  String workerAbout(String name, String place, int jobs) {
    return '$place-ൽ $jobs ജോലികൾ പൂർത്തിയാക്കിയ ഒരു കെയ്‌ലോ പ്രൊഫഷണലാണ് $name.';
  }

  @override
  String get verificationPending => 'പരിശോധന പുരോഗമിക്കുന്നു';

  @override
  String get certGovtId => 'സർക്കാർ തിരിച്ചറിയൽ രേഖ പരിശോധിച്ചു';

  @override
  String get certGovtIdSub => 'ആധാർ അല്ലെങ്കിൽ വോട്ടർ ഐഡി പരിശോധിച്ചു';

  @override
  String get certPolice => 'പോലീസ് ക്ലിയറൻസ് പരിശോധിച്ചു';

  @override
  String get certPoliceSub => 'പശ്ചാത്തല പരിശോധന ക്ലിയറാണ്';

  @override
  String get certSkill => 'കെയ്‌ലോ നൈപുണ്യ സർട്ടിഫിക്കറ്റ്';

  @override
  String get certSkillSub => 'പ്രായോഗിക കഴിവുകൾ പരിശോധിച്ചു';

  @override
  String get hourlyRate => 'മണിക്കൂർ നിരക്ക്';

  @override
  String get perHour => 'മണിക്കൂറിന്';

  @override
  String get priceOnVisit => 'സന്ദർശന വേളയിൽ വില തീരുമാനിക്കും';

  @override
  String get noReviewsYet => 'ഇതുവരെ അവലോകനങ്ങളൊന്നുമില്ല';

  @override
  String get newService => 'പുതിയത്';

  @override
  String get nearbyFirst => 'അടുത്തുള്ളവർ ആദ്യം';

  @override
  String get tomorrow => 'നാളെ';

  @override
  String inDays(int count) {
    return '$count ദിവസത്തിനുള്ളിൽ';
  }

  @override
  String get whoIsItFor => 'ഇത് ആർക്കാണ്?';

  @override
  String get appointmentNotes => 'ഡോക്ടർക്കുള്ള കുറിപ്പുകൾ (ഓപ്ഷണൽ)';

  @override
  String appointmentConfirmedWith(String doctor) {
    return '$doctor-മായി അപ്പോയിന്റ്മെന്റ് ബുക്ക് ചെയ്തു';
  }

  @override
  String get noUpcomingAppointments =>
      'വരാനിരിക്കുന്ന അപ്പോയിന്റ്മെന്റുകൾ ഒന്നുമില്ല';

  @override
  String get specGeneral => 'ജനറൽ ഫിസിഷ്യൻ';

  @override
  String get specCardio => 'കാർഡിയോളജിസ്റ്റ്';

  @override
  String get specOrtho => 'ഓർത്തോപീഡിക്';

  @override
  String get specGeriatric => 'ജെറിയാട്രിഷ്യൻ';

  @override
  String get specAyurveda => 'ആയുർവേദം';

  @override
  String get incPlumbTap => 'ടാപ്പ് അറ്റകുറ്റപ്പണി';

  @override
  String get incPlumbPipe => 'പൈപ്പ് ചോർച്ച';

  @override
  String get incPlumbDrain => 'ഡ്രെയിൻ ക്ലീനിംഗ്';

  @override
  String get incPlumbInstall => 'ഇൻസ്റ്റാളേഷൻ';

  @override
  String get incElecSwitch => 'സ്വിച്ച്ബോർഡ് അറ്റകുറ്റപ്പണി';

  @override
  String get incElecWiring => 'വയറിംഗ് പരിഹാരം';

  @override
  String get incElecFan => 'ഫാൻ ഘടിപ്പിക്കൽ';

  @override
  String get incElecMcb => 'MCB ട്രിപ്പിംഗ്';

  @override
  String get incCleanDeep => 'പൂർണ്ണ ഭവന ശുചീകരണം';

  @override
  String get incCleanKitchen => 'അടുക്കള ശുചീകരണം';

  @override
  String get incCleanBath => 'ബാത്ത്റൂം സ്ക്രബ്';

  @override
  String get incCleanSofa => 'സോഫ ഷാംപൂ';

  @override
  String get incCarpFurniture => 'ഫർണിച്ചർ അറ്റകുറ്റപ്പണി';

  @override
  String get incCarpDoor => 'വാതിലുകളും ജനലുകളും';

  @override
  String get incCarpLock => 'പൂട്ട് ഘടിപ്പിക്കൽ';

  @override
  String get incCarpCustom => 'തടിപ്പണികൾ';

  @override
  String get incPaintInterior => 'ഇന്റീരിയർ പെയിന്റിംഗ്';

  @override
  String get incPaintExterior => 'എക്സ്റ്റീരിയർ പെയിന്റിംഗ്';

  @override
  String get incPaintPutty => 'വാൾ പുട്ടി & പ്രൈമർ';

  @override
  String get incPaintWaterproof => 'വാട്ടർപ്രൂഫിംഗ്';

  @override
  String get incAcFilter => 'ഫിൽട്ടർ ക്ലീനിംഗ്';

  @override
  String get incAcGas => 'ഗ്യാസ് റീഫിൽ';

  @override
  String get incAcCooling => 'തണുപ്പിക്കൽ പ്രശ്ന പരിഹാരം';

  @override
  String get incAcInstall => 'ഘടിപ്പിക്കലും അഴിക്കലും';

  @override
  String get incApplWasher => 'വാഷിംഗ് മെഷീൻ';

  @override
  String get incApplFridge => 'റഫ്രിജറേറ്റർ';

  @override
  String get incApplMicrowave => 'മൈക്രോവേവ്';

  @override
  String get incApplTv => 'ടിവി മൗണ്ടിംഗും അറ്റകുറ്റപ്പണിയും';

  @override
  String get incGenInspect => 'പൊതുവായ പരിശോധന';

  @override
  String get incGenRepair => 'അറ്റകുറ്റപ്പണിയും പരിഹാരവും';

  @override
  String get incGenInstall => 'പുതിയ ഇൻസ്റ്റാളേഷൻ';

  @override
  String get incGenMaintain => 'പരിപാലനം';

  @override
  String get invoiceEmail => 'ഇൻവോയ്‌സിനുള്ള ഇമെയിൽ';

  @override
  String get invoiceEmailRequired => 'ഇൻവോയ്‌സിനായി ഒരു ഇമെയിൽ വിലാസം നൽകുക';

  @override
  String get confirmationEmail => 'സ്ഥിരീകരണത്തിനുള്ള ഇമെയിൽ (ഐച്ഛികം)';

  @override
  String get payNow => 'ഇപ്പോൾ പണമടയ്ക്കുക';

  @override
  String get payNowSubtitle =>
      'കാർഡ്, നെറ്റ്ബാങ്കിംഗ് അല്ലെങ്കിൽ UPI, Razorpay വഴി സുരക്ഷിതം';

  @override
  String get prescriptions => 'കുറിപ്പടികൾ';

  @override
  String get prescriptionsSubtitle =>
      'നിങ്ങളുടെ ആരോഗ്യ രേഖകൾ സ്കാൻ ചെയ്ത് വായിച്ച് സൂക്ഷിക്കുക';

  @override
  String get trustedContacts => 'വിശ്വസ്ത കോൺടാക്റ്റുകൾ';

  @override
  String get trustedContactsSubtitle =>
      'SOS കോളുകൾക്കായി കുടുംബത്തെയും ഡോക്ടർമാരെയും ബന്ധിപ്പിക്കുക';

  @override
  String get sosStartFailedContacts =>
      'SOS ആരംഭിക്കാനായില്ല. നിങ്ങളുടെ കണക്ഷനും വിശ്വസ്ത കോൺടാക്റ്റുകളും പരിശോധിക്കുക.';

  @override
  String get sosStartFailed => 'SOS ആരംഭിക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get sosModeKaylo => 'കെയ്‌ലോ കോൾ';

  @override
  String get sosModeSim => 'സിം കോൾ';

  @override
  String get manageTrustedContacts => 'വിശ്വസ്ത കോൺടാക്റ്റുകൾ നിയന്ത്രിക്കുക';

  @override
  String get sosKayloHoldHint =>
      'നിങ്ങളുടെ വിശ്വസ്ത കെയ്‌ലോ കോൺടാക്റ്റുകളെ ക്ഷണിക്കാൻ 3 സെക്കൻഡ് അമർത്തിപ്പിടിക്കുക. അവർക്ക് ഒരുമിച്ച് കോളിൽ ചേരാം. ക്ഷണം അയച്ചു എന്നതിനർത്ഥം ആരെങ്കിലും ഉത്തരം നൽകി എന്നല്ല.';

  @override
  String get contactsOpenFailed => 'ഫോൺ കോൺടാക്റ്റുകൾ തുറക്കാനായില്ല.';

  @override
  String get chooseFromPhoneContacts =>
      'ഫോൺ കോൺടാക്റ്റുകളിൽ നിന്ന് തിരഞ്ഞെടുക്കുക';

  @override
  String sosContactsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count കോൺടാക്റ്റുകൾ ഒഴിവാക്കി: ആ നമ്പറുകളിലേക്ക് വിളിക്കാനാവില്ല.',
      one: '1 കോൺടാക്റ്റ് ഒഴിവാക്കി: ആ നമ്പറിലേക്ക് വിളിക്കാനാവില്ല.',
    );
    return '$_temp0';
  }

  @override
  String get incomingSosTitle => 'കെയ്‌ലോ SOS വരുന്നു';

  @override
  String get incomingSosSubtitle => 'ഒരു വിശ്വസ്ത കോൺടാക്റ്റിന് സഹായം വേണം';

  @override
  String get decline => 'നിരസിക്കുക';

  @override
  String get joinCall => 'കോളിൽ ചേരുക';

  @override
  String get signInLiveForContacts =>
      'വിശ്വസ്ത കോൺടാക്റ്റുകളെ ബന്ധിപ്പിക്കാൻ ലൈവ് ആപ്പിൽ സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get couldNotConnectRetry =>
      'ബന്ധിപ്പിക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get refreshConnections => 'കണക്ഷനുകൾ പുതുക്കുക';

  @override
  String get trustedCircleTitle =>
      'നിങ്ങളുടെ പ്രിയപ്പെട്ടവരെ കെയ്‌ലോയിലേക്ക് കൊണ്ടുവരൂ';

  @override
  String get trustedCircleBody =>
      'കെയ്‌ലോ ഉപയോഗിക്കുന്ന അഞ്ച് കുടുംബാംഗങ്ങളെയോ ഡോക്ടർമാരെയോ വരെ ക്ഷണിക്കാം. അവർ നിങ്ങളുടെ കോഡ് സ്വീകരിച്ചാൽ, നിങ്ങളുടെ SOS അലേർട്ടുകൾ അവർക്ക് ലഭിക്കുകയും ഒരേ വോയ്‌സ് കോളിൽ ചേരാനാവുകയും ചെയ്യും.';

  @override
  String get getInviteCode => 'എന്റെ ക്ഷണ കോഡ് നേടുക';

  @override
  String get inviteCodeCopied => 'ക്ഷണ കോഡ് പകർത്തി';

  @override
  String get copyCode => 'കോഡ് പകർത്തുക';

  @override
  String get inviteCodeValidity =>
      'ഏഴ് ദിവസത്തേക്ക് സാധുവാണ്. നിങ്ങൾ വിശ്വസിക്കുന്നവരുമായി മാത്രം പങ്കിടുക.';

  @override
  String get acceptInviteTitle => 'ഒരാളുടെ ക്ഷണം സ്വീകരിക്കുക';

  @override
  String get inviteCode => 'ക്ഷണ കോഡ്';

  @override
  String get acceptInvitation => 'ക്ഷണം സ്വീകരിക്കുക';

  @override
  String get invitationAccepted =>
      'ക്ഷണം സ്വീകരിച്ചു. നിങ്ങൾ ഇപ്പോൾ ബന്ധിപ്പിക്കപ്പെട്ടു; അവരുടെ SOS അലേർട്ടുകൾ നിങ്ങൾക്ക് ലഭിക്കും.';

  @override
  String get yourConnections => 'നിങ്ങളുടെ കണക്ഷനുകൾ';

  @override
  String get noConnectionsYet => 'ഇതുവരെ കണക്ഷനുകളില്ല';

  @override
  String get receivesYourSos => 'നിങ്ങളുടെ SOS അലേർട്ടുകൾ ലഭിക്കുന്നു';

  @override
  String get youReceiveTheirSos =>
      'അവരുടെ SOS അലേർട്ടുകൾ നിങ്ങൾക്ക് ലഭിക്കുന്നു';

  @override
  String get removeConnection => 'കണക്ഷൻ നീക്കം ചെയ്യുക';

  @override
  String get removeConnectionTitle => 'കണക്ഷൻ നീക്കം ചെയ്യണോ?';

  @override
  String get removeConnectionBody =>
      'ഈ കണക്ഷന് ഇനി SOS കോൾ ക്ഷണങ്ങൾ ലഭിക്കില്ല.';

  @override
  String get contactsLoadFailedRetry =>
      'കോൺടാക്റ്റുകൾ ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക';

  @override
  String get callTitle => 'കെയ്‌ലോ SOS കോൾ';

  @override
  String get callEnded => 'കോൾ അവസാനിച്ചു';

  @override
  String get callYourCircle => 'നിങ്ങളുടെ വിശ്വസ്ത വലയം';

  @override
  String get callCouldNotConnect => 'കണക്റ്റ് ചെയ്യാനായില്ല';

  @override
  String get callConnecting => 'കണക്റ്റ് ചെയ്യുന്നു…';

  @override
  String get callKeepOpen => 'കോൾ സമയത്ത് കെയ്‌ലോ തുറന്നുവയ്ക്കുക.';

  @override
  String get retryCall => 'കോൾ വീണ്ടും ശ്രമിക്കുക';

  @override
  String get callErrorRoom =>
      'ഈ കോൾ ലഭ്യമല്ല അല്ലെങ്കിൽ അവസാനിച്ചു. പുതിയ കോൾ തുടങ്ങാൻ SOS-ലേക്ക് മടങ്ങുക.';

  @override
  String get callErrorSettings =>
      'കോൾ ക്രമീകരണങ്ങൾ ലോഡ് ചെയ്യാനായില്ല. കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get callErrorMicrophone =>
      'മൈക്രോഫോൺ ഉപയോഗിക്കാനായില്ല. കെയ്‌ലോയ്ക്കുള്ള മൈക്രോഫോൺ അനുമതി പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get callErrorJoin =>
      'ഈ കോളിൽ ചേരാനായില്ല. വീണ്ടും ശ്രമിക്കുക, അല്ലെങ്കിൽ വിളിച്ചയാളോട് പുതിയ SOS കോൾ തുടങ്ങാൻ പറയുക.';

  @override
  String get callInterrupted => 'കണക്ഷൻ തടസ്സപ്പെട്ടു. വീണ്ടും ശ്രമിക്കുന്നു…';

  @override
  String get callPeerConnected => 'കണക്റ്റ് ചെയ്തു';

  @override
  String get callPeerFailed => 'കണക്ഷൻ പരാജയപ്പെട്ടു';

  @override
  String get callPeerReconnecting => 'വീണ്ടും കണക്റ്റ് ചെയ്യുന്നു';

  @override
  String get callPeerConnecting => 'കണക്റ്റ് ചെയ്യുന്നു';

  @override
  String get callYou => 'നിങ്ങൾ';

  @override
  String get callYouMuted => 'നിങ്ങൾ • മ്യൂട്ട് ചെയ്തു';

  @override
  String get callInvitedWaiting => 'ക്ഷണിച്ചു • ഉത്തരത്തിനായി കാത്തിരിക്കുന്നു';

  @override
  String get callDeclined => 'നിരസിച്ചു';

  @override
  String get callLeft => 'കോൾ വിട്ടു';

  @override
  String get mute => 'മ്യൂട്ട്';

  @override
  String get unmute => 'അൺമ്യൂട്ട്';

  @override
  String get speaker => 'സ്പീക്കർ';

  @override
  String get callAudioOutputFailed =>
      'ഓഡിയോ ഔട്ട്‌പുട്ട് മാറ്റാനായില്ല. കോൾ ഇപ്പോഴും സജീവമാണ്.';

  @override
  String get close => 'അടയ്ക്കുക';

  @override
  String get callEndForEveryone => 'എല്ലാവർക്കും കോൾ അവസാനിപ്പിക്കുക';

  @override
  String get callLeave => 'കോൾ വിടുക';

  @override
  String get prescriptionsLoadFailed =>
      'കുറിപ്പടികൾ ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get actionFailed => 'ആ പ്രവർത്തനം പൂർത്തിയാക്കാനായില്ല.';

  @override
  String get prescriptionSaveFailed =>
      'കുറിപ്പടി സേവ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get prescriptionsHeadline => 'നിങ്ങളുടെ ആരോഗ്യ രേഖകൾ, ഒരിടത്ത്';

  @override
  String get prescriptionsIntro =>
      'ഒരു കുറിപ്പടി സ്കാൻ ചെയ്യുക അല്ലെങ്കിൽ പഴയ രേഖ ടൈപ്പ് ചെയ്യുക. PDF-കൾ ഈ ഉപകരണത്തിൽ സ്വകാര്യമായി സൂക്ഷിക്കുന്നു.';

  @override
  String get prescriptionsAndroidOnly =>
      'കുറിപ്പടി സ്കാനിംഗും PDF-കളും നിലവിൽ Android ആപ്പിൽ ലഭ്യമാണ്.';

  @override
  String get scanOrPhotos => 'സ്കാൻ / ഫോട്ടോകൾ';

  @override
  String get typeRecord => 'രേഖ ടൈപ്പ് ചെയ്യുക';

  @override
  String get searchPrescriptions => 'കുറിപ്പടികൾ തിരയുക';

  @override
  String get noPrescriptionsYet => 'ഇതുവരെ കുറിപ്പടികളില്ല';

  @override
  String get noMatchingPrescriptions => 'പൊരുത്തപ്പെടുന്ന കുറിപ്പടികളില്ല';

  @override
  String get prescriptionNeedsTitleText =>
      'ഒരു തലക്കെട്ടും കുറിപ്പടിയുടെ വിവരങ്ങളും ചേർക്കുക.';

  @override
  String get prescriptionRecord => 'കുറിപ്പടി രേഖ';

  @override
  String get reviewPrescription => 'കുറിപ്പടി പരിശോധിക്കുക';

  @override
  String get deletePrescription => 'കുറിപ്പടി ഇല്ലാതാക്കുക';

  @override
  String get deletePrescriptionTitle => 'കുറിപ്പടി ഇല്ലാതാക്കണോ?';

  @override
  String get deletePrescriptionBody =>
      'PDF-ഉം ടെക്സ്റ്റും ഈ ഉപകരണത്തിൽ നിന്ന് നീക്കം ചെയ്യും.';

  @override
  String get delete => 'ഇല്ലാതാക്കുക';

  @override
  String get prescriptionReviewHint =>
      'എടുത്ത ടെക്സ്റ്റ് യഥാർത്ഥ കുറിപ്പടിയുമായി ഒത്തുനോക്കുക. കൈയക്ഷരം അപൂർണ്ണമോ തെറ്റോ ആകാം; മരുന്നുകളുടെ പേരും അളവും ഡോക്ടറോട് ചോദിച്ച് ഉറപ്പാക്കുക.';

  @override
  String get viewOriginalPdf => 'യഥാർത്ഥ PDF കാണുക';

  @override
  String get titleLabel => 'തലക്കെട്ട്';

  @override
  String get extractedTextNotes => 'എടുത്ത ടെക്സ്റ്റ് / കുറിപ്പുകൾ';

  @override
  String get prescriptionDetails => 'കുറിപ്പടി വിവരങ്ങൾ';

  @override
  String get prescriptionEditHint =>
      'ഈ ടെക്സ്റ്റ് തിരുത്തിയാലും സ്കാൻ ചെയ്ത യഥാർത്ഥ PDF മാറില്ല.';

  @override
  String get saving => 'സേവ് ചെയ്യുന്നു…';

  @override
  String get savePrescription => 'കുറിപ്പടി സേവ് ചെയ്യുക';

  @override
  String get openSavedPdf => 'സേവ് ചെയ്ത PDF തുറക്കുക';

  @override
  String get shareSavedPdf => 'സേവ് ചെയ്ത PDF പങ്കിടുക';

  @override
  String get deleteAccount => 'അക്കൗണ്ട് ഇല്ലാതാക്കുക';

  @override
  String get deleteRequiresLive =>
      'അക്കൗണ്ട് ഇല്ലാതാക്കാൻ സൈൻ ഇൻ ചെയ്ത ലൈവ് അക്കൗണ്ട് വേണം.';

  @override
  String get deleteNotConfirmed =>
      'ഇല്ലാതാക്കൽ സ്ഥിരീകരിച്ചില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get deleteFailed =>
      'അക്കൗണ്ട് ഇല്ലാതാക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get deleteAccountHeadline =>
      'നിങ്ങളുടെ കെയ്‌ലോ അക്കൗണ്ട് എന്നെന്നേക്കുമായി ഇല്ലാതാക്കണോ?';

  @override
  String get deleteAccountBody =>
      'ഇത് നിങ്ങളുടെ സൈൻ-ഇൻ, പ്രൊഫൈൽ, ബുക്കിംഗുകൾ, സന്ദേശങ്ങൾ, കെയർ രേഖകൾ, ഈ ഉപകരണത്തിലുള്ള കുറിപ്പടികൾ എന്നിവ നീക്കം ചെയ്യും. ഇത് പഴയപടിയാക്കാനാവില്ല. സജീവമായ ബുക്കിംഗുകൾ ആദ്യം പൂർത്തിയാക്കുകയോ റദ്ദാക്കുകയോ ചെയ്യുക. തീർപ്പാകാത്ത പേയ്‌മെന്റുകൾക്ക് kayloapp@gmail.com-ൽ ബന്ധപ്പെടുക.';

  @override
  String get deleteAccountNote =>
      'പേയ്‌മെന്റ് സേവനദാതാക്കൾ ഇടപാട് രേഖകൾ സൂക്ഷിച്ചേക്കാം. നിങ്ങൾ മുമ്പ് പങ്കിട്ട രേഖകൾ മറ്റുള്ളവരുടെ ഉപകരണങ്ങളിൽ നിന്ന് നീക്കം ചെയ്യപ്പെടില്ല.';

  @override
  String get typeDeleteToConfirm =>
      'സ്ഥിരീകരിക്കാൻ DELETE എന്ന് ടൈപ്പ് ചെയ്യുക';

  @override
  String get deleting => 'ഇല്ലാതാക്കുന്നു…';

  @override
  String get deleteMyAccount => 'എന്റെ അക്കൗണ്ട് ഇല്ലാതാക്കുക';

  @override
  String get paymentVerified =>
      'പേയ്‌മെന്റ് സ്ഥിരീകരിച്ചു. നിങ്ങളുടെ ബുക്കിംഗ് ഉറപ്പായി.';

  @override
  String get paymentNotCompleted => 'പേയ്‌മെന്റ് പൂർത്തിയായില്ല.';

  @override
  String get checkoutOpenFailed =>
      'സുരക്ഷിത ചെക്കൗട്ട് തുറക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get cardsAndUpi => 'കാർഡുകളും UPI-യും';

  @override
  String get paymentMethodsBody =>
      'സുരക്ഷിതമായ Razorpay ചെക്കൗട്ടിൽ കാർഡ് വിവരങ്ങൾ നൽകുകയോ UPI തിരഞ്ഞെടുക്കുകയോ ചെയ്യാം. ലഭ്യമാണെങ്കിൽ, ആ കാർഡ് വീണ്ടും ഉപയോഗിക്കാൻ Razorpay-യുടെ കാർഡ് സേവ് ചെയ്യാനുള്ള ഓപ്ഷൻ തിരഞ്ഞെടുക്കുക. സേവ് ചെയ്ത കാർഡുകൾ ചെക്കൗട്ടിനുള്ളിൽ തന്നെ നിയന്ത്രിക്കാം.';

  @override
  String get paymentMethodsNote =>
      'കെയ്‌ലോ നിങ്ങളുടെ മുഴുവൻ കാർഡ് നമ്പറോ CVV-യോ PIN-ഓ സൂക്ഷിക്കുന്നില്ല. നിലവിലെ പേയ്‌മെന്റ് സംവിധാനത്തിൽ NFC വഴി കാർഡ് ചേർക്കാനാവില്ല.';

  @override
  String get completePendingPayment => 'ബാക്കിയുള്ള പേയ്‌മെന്റ് പൂർത്തിയാക്കുക';

  @override
  String get noPendingPayments =>
      'നിങ്ങളുടെ അടുത്ത ബുക്കിംഗിൽ ചെക്കൗട്ട് തുറക്കും; അവിടെ കാർഡ് ചേർക്കുകയോ തിരഞ്ഞെടുക്കുകയോ ചെയ്യാം.';

  @override
  String pendingBookingLine(String id, String date) {
    return 'ബുക്കിംഗ് $id • $date';
  }

  @override
  String get bookingsLoadFailedRetry =>
      'ബുക്കിംഗുകൾ ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക';

  @override
  String get openingPayment => 'പേയ്‌മെന്റ് തുറക്കുന്നു…';

  @override
  String get payAndBook => 'പണമടച്ച് ബുക്ക് ചെയ്യുക';

  @override
  String get appointmentPaymentFailed =>
      'പേയ്‌മെന്റ് പൂർത്തിയാക്കാനായില്ല. നിങ്ങളുടെ അപ്പോയിന്റ്മെന്റ് ഉറപ്പായിട്ടില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get visitPaymentFailed =>
      'പേയ്‌മെന്റ് പൂർത്തിയാക്കാനായില്ല. നിങ്ങളുടെ സന്ദർശനം ഉറപ്പായിട്ടില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get careServiceUnavailable => 'ഈ കെയർ സേവനം ലഭ്യമല്ല.';

  @override
  String get appointmentNotConfirmed =>
      'പേയ്‌മെന്റ് പൂർത്തിയായില്ല. നിങ്ങളുടെ അപ്പോയിന്റ്മെന്റ് ഉറപ്പായിട്ടില്ല.';

  @override
  String get hapticFeedback => 'ഹാപ്റ്റിക് പ്രതികരണം';

  @override
  String get soundEffects => 'ശബ്ദ ഇഫക്റ്റുകൾ';

  @override
  String get voiceStarting => 'മൈക്രോഫോൺ ആരംഭിക്കുന്നു…';

  @override
  String get ocrNeedsReview =>
      'ചില വാക്കുകൾ വായിക്കാൻ കഴിഞ്ഞില്ല. യഥാർത്ഥ സ്കാൻ പരിശോധിച്ച് കുറിപ്പുകൾ തിരുത്തുക.';

  @override
  String get allBookings => 'എല്ലാ ബുക്കിങ്ങുകളും';

  @override
  String get noCompletedBookings => 'പൂർത്തിയായ ബുക്കിങ്ങുകളില്ല';

  @override
  String get noCompletedBookingsDescription =>
      'ജോലി പൂർത്തിയായാൽ ആ ബുക്കിങ്ങുകൾ ഇവിടെ കാണാം.';

  @override
  String get verificationRecord => 'പരിശോധനാ രേഖ';

  @override
  String get refreshVerification => 'പരിശോധനാ നില പുതുക്കുക';

  @override
  String get verificationLoadError =>
      'നിലവിലെ പരിശോധനാ നില ലഭ്യമാക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get kayloVerified => 'Kaylo-യിൽ പരിശോധിച്ചത്';

  @override
  String get notYetVerified => 'ഇതുവരെ പരിശോധിച്ചിട്ടില്ല';

  @override
  String get viewVerification => 'പരിശോധനാ രേഖ കാണുക';

  @override
  String get verificationRecorded =>
      'ഈ പ്രൊഫഷണലിന്റെ പ്രൊഫൈൽ Kaylo-യിൽ പരിശോധിച്ചതായി രേഖപ്പെടുത്തിയിട്ടുണ്ട്.';

  @override
  String get verificationNotRecorded =>
      'ഈ പ്രൊഫൈലിൽ പരിശോധിച്ചതായി രേഖപ്പെടുത്തിയിട്ടില്ല.';

  @override
  String get listedServices => 'ലിസ്റ്റ് ചെയ്ത സേവനങ്ങൾ';

  @override
  String get profileReference => 'പ്രൊഫൈൽ റഫറൻസ്';

  @override
  String get serviceArea => 'സേവന മേഖല';

  @override
  String get verificationScope =>
      'ഈ രേഖ പ്രൊഫൈലിന്റെ നിലവിലെ നിലയാണ് കാണിക്കുന്നത്. അനുബന്ധ രേഖകളും പരിശോധനാ വിശദാംശങ്ങളും ലഭ്യമല്ല. ഇത് സർക്കാർ ലൈസൻസോ പ്രൊഫഷണൽ യോഗ്യതയോ അല്ല.';

  @override
  String get selectOnMap => 'മാപ്പിൽ തിരഞ്ഞെടുക്കുക';

  @override
  String get chooseAddress => 'ഒരു വിലാസം തിരഞ്ഞെടുക്കുക';
}
