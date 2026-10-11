// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appTitle => 'കെയ്‌ലോ പാർട്ണർ';

  @override
  String get refreshJobsTooltip => 'ജോലികൾ പുതുക്കുക';

  @override
  String get tabJobs => 'ജോലികൾ';

  @override
  String get tabEarnings => 'വരുമാനം';

  @override
  String get tabProfile => 'പ്രൊഫൈൽ';

  @override
  String get dutyOnline => 'നിങ്ങൾ ഓൺലൈനിലാണ്';

  @override
  String get dutyOffline => 'നിങ്ങൾ ഓഫ്‌ലൈനിലാണ്';

  @override
  String dutyTakingOrders(String district) {
    return '$district ഓർഡറുകൾ എടുക്കുന്നു';
  }

  @override
  String get dutyNotReceivingRequests => 'അഭ്യർത്ഥനകൾ സ്വീകരിക്കുന്നില്ല';

  @override
  String get todaysPay => 'ഇന്നത്തെ വരുമാനം';

  @override
  String get jobsToday => 'ഇന്നത്തെ ജോലികൾ';

  @override
  String get rating => 'റേറ്റിംഗ്';

  @override
  String get activeJob => 'സജീവമായ ജോലി';

  @override
  String get offlineTitle => 'നിങ്ങൾ ഓഫ്‌ലൈനിലാണ്';

  @override
  String get offlineDescription =>
      'സമീപത്തുള്ള ഉപഭോക്താക്കളിൽ നിന്ന് ജോലി അഭ്യർത്ഥനകൾ ലഭിക്കുന്നതിന് നിങ്ങളുടെ ഡ്യൂട്ടി സ്റ്റാറ്റസ് ഓൺലൈനിലേക്ക് മാറ്റുക.';

  @override
  String newRequests(int count) {
    return 'പുതിയ അഭ്യർത്ഥനകൾ ($count)';
  }

  @override
  String get searchingForRequests => 'അഭ്യർത്ഥനകൾക്കായി തിരയുന്നു...';

  @override
  String get searchingForRequestsSubtitle =>
      'സമീപത്തുള്ള ഉപഭോക്താവ് ബുക്ക് ചെയ്യുമ്പോൾ നിങ്ങൾക്ക് ഒരു പിംഗ് കേൾക്കാം.';

  @override
  String get payout => 'പേഔട്ട്';

  @override
  String get decline => 'നിരസിക്കുക';

  @override
  String get acceptJob => 'ജോലി സ്വീകരിക്കുക';

  @override
  String get stageRequested => 'അഭ്യർത്ഥിച്ചു';

  @override
  String get stageAccepted => 'സ്വീകരിച്ചു';

  @override
  String get stageOnTheWay => 'യാത്രയിലാണ്';

  @override
  String get stageArrived => 'എത്തിച്ചേർന്നു';

  @override
  String get stageInProgress => 'പുരോഗമിക്കുന്നു';

  @override
  String get stageCompleted => 'പൂർത്തിയായി';

  @override
  String get stageCancelled => 'റദ്ദാക്കി';

  @override
  String get actionAccept => 'സ്വീകരിക്കുക';

  @override
  String get actionStartTravel => 'യാത്ര തുടങ്ങുക';

  @override
  String get actionArrived => 'ഞാൻ എത്തിച്ചേർന്നു';

  @override
  String get actionStartJob => 'ജോലി തുടങ്ങുക';

  @override
  String get actionCompleteJob => 'ജോലി പൂർത്തിയാക്കുക';

  @override
  String get languageSettings => 'ഭാഷാ ക്രമീകരണങ്ങൾ';

  @override
  String get profileLanguageTile => 'ഭാഷ';

  @override
  String get appSettingsHeader => 'ആപ്പ് ക്രമീകരണങ്ങൾ';

  @override
  String get profileTitle => 'പാർട്ണർ പ്രൊഫൈൽ';

  @override
  String get editProfile => 'പ്രൊഫൈൽ മാറ്റുക';

  @override
  String get verifiedPartner => 'പരിശോധിച്ച പാർട്ണർ';

  @override
  String get verificationUnderReview => 'പരിശോധന നടക്കുന്നു';

  @override
  String get verificationRejected => 'പരിശോധന നിരസിച്ചു';

  @override
  String get verificationNotStarted => 'ഇതുവരെ പരിശോധിച്ചിട്ടില്ല';

  @override
  String get performanceHeader => 'പ്രകടനവും റേറ്റിംഗും';

  @override
  String get totalJobs => 'ആകെ ജോലികൾ';

  @override
  String reviewsCount(int count) {
    return '$count അവലോകനങ്ങൾ';
  }

  @override
  String memberSince(String date) {
    return '$date മുതൽ';
  }

  @override
  String get offeredServicesHeader => 'നിങ്ങൾ നൽകുന്ന സേവനങ്ങൾ';

  @override
  String get noServicesYet => 'ഇതുവരെ സേവനങ്ങളൊന്നും ചേർത്തിട്ടില്ല';

  @override
  String get payoutHeader => 'പണം സ്വീകരിക്കുന്ന അക്കൗണ്ട്';

  @override
  String upiLabel(String upi) {
    return 'UPI ID: $upi';
  }

  @override
  String get noPayoutYet => 'ഇതുവരെ അക്കൗണ്ട് ചേർത്തിട്ടില്ല';

  @override
  String get bankChangeNote =>
      'ബാങ്ക് അക്കൗണ്ട് മാറ്റങ്ങൾ സപ്പോർട്ട് ടീം വഴിയാണ്';

  @override
  String get verificationHeader => 'KYC-യും പരിശോധനയും';

  @override
  String get documentAadhaar => 'ആധാർ കാർഡ്';

  @override
  String get documentPoliceCertificate => 'പോലീസ് ക്ലിയറൻസ് സർട്ടിഫിക്കറ്റ്';

  @override
  String get statusVerified => 'പരിശോധിച്ചു';

  @override
  String get statusPending => 'കാത്തിരിക്കുന്നു';

  @override
  String get statusRejected => 'നിരസിച്ചു';

  @override
  String get statusNotSubmitted => 'സമർപ്പിച്ചിട്ടില്ല';

  @override
  String get areaScheduleHeader => 'സേവന മേഖലയും സമയവും';

  @override
  String travelRadius(String km) {
    return '$km കി.മീ. പരിധിയിൽ';
  }

  @override
  String get noDistrictYet => 'സേവന മേഖല തീരുമാനിച്ചിട്ടില്ല';

  @override
  String get hoursNotSet => 'ജോലി സമയം തീരുമാനിച്ചിട്ടില്ല';

  @override
  String get customHours => 'ദിവസങ്ങൾക്കനുസരിച്ച് വ്യത്യസ്ത സമയം';

  @override
  String get manageAvailability => 'ലഭ്യത മാറ്റുക';

  @override
  String get logOut => 'ലോഗ് ഔട്ട്';

  @override
  String get logOutTitle => 'ലോഗ് ഔട്ട് ചെയ്യണോ?';

  @override
  String get logOutBody =>
      'വീണ്ടും സൈൻ ഇൻ ചെയ്യാൻ പാർട്ണർ ഐഡിയും പാസ്‌വേഡും വേണം.';

  @override
  String get cancel => 'റദ്ദാക്കുക';

  @override
  String get notRegisteredTitle => 'രജിസ്ട്രേഷൻ പൂർത്തിയാക്കുക';

  @override
  String get notRegisteredBody =>
      'നിങ്ങളുടെ വർക്കർ പ്രൊഫൈൽ ഇതുവരെ തയ്യാറായിട്ടില്ല. ജോലികൾ ലഭിക്കാൻ രജിസ്ട്രേഷൻ പൂർത്തിയാക്കുക.';

  @override
  String get profileLoadFailed => 'പ്രൊഫൈൽ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get retry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get editProfileTitle => 'പ്രൊഫൈൽ മാറ്റുക';

  @override
  String get fullNameLabel => 'മുഴുവൻ പേര്';

  @override
  String get districtLabel => 'ജില്ല';

  @override
  String get travelRadiusLabel => 'യാത്രാ പരിധി (കി.മീ.)';

  @override
  String get upiIdLabel => 'UPI ID';

  @override
  String get servicesLabel => 'നിങ്ങൾ നൽകുന്ന സേവനങ്ങൾ';

  @override
  String get save => 'സേവ് ചെയ്യുക';

  @override
  String get profileSaved => 'പ്രൊഫൈൽ അപ്ഡേറ്റ് ചെയ്തു';

  @override
  String get nameRequired => 'നിങ്ങളുടെ പേര് നൽകുക';

  @override
  String get chooseOneService => 'കുറഞ്ഞത് ഒരു സേവനം തിരഞ്ഞെടുക്കുക';

  @override
  String get invalidUpi => 'ശരിയായ UPI ID നൽകുക, ഉദാ: name@bank';

  @override
  String get radiusRange => '1 മുതൽ 100 കി.മീ. വരെയുള്ള പരിധി നൽകുക';

  @override
  String get dutyUpdateFailed => 'ലഭ്യത അപ്ഡേറ്റ് ചെയ്യാനായില്ല';

  @override
  String get dutyTakingOrdersAnywhere => 'ജോലി അഭ്യർത്ഥനകൾ സ്വീകരിക്കുന്നു';

  @override
  String get availabilityTitle => 'എന്റെ ലഭ്യത';

  @override
  String get workingHoursHeader => 'ജോലി സമയം';

  @override
  String get workingHoursHint =>
      'ഈ സമയത്തിനുള്ളിൽ മാത്രമേ ഉപഭോക്താക്കൾക്ക് നിങ്ങളെ ബുക്ക് ചെയ്യാനാകൂ.';

  @override
  String get dayOff => 'അവധി';

  @override
  String get saveHours => 'സമയം സേവ് ചെയ്യുക';

  @override
  String get hoursSaved => 'ജോലി സമയം സേവ് ചെയ്തു';

  @override
  String get endAfterStart => 'അവസാന സമയം തുടക്കത്തിന് ശേഷമായിരിക്കണം';

  @override
  String get daysOffHeader => 'അവധി ദിവസങ്ങൾ';

  @override
  String get daysOffHint =>
      'ഈ ദിവസങ്ങളിൽ ഉപഭോക്താക്കൾക്ക് ബുക്ക് ചെയ്യാനാകില്ല.';

  @override
  String get addDaysOff => 'അവധി ചേർക്കുക';

  @override
  String get noDaysOff => 'അവധികളൊന്നും ആസൂത്രണം ചെയ്തിട്ടില്ല';

  @override
  String get reasonLabel => 'കാരണം (ഐച്ഛികം)';

  @override
  String get reasonHint => 'ഉത്സവം, യാത്ര, കുടുംബം…';

  @override
  String get timeOffAdded => 'അവധി ചേർത്തു';

  @override
  String get timeOffRemoved => 'അവധി നീക്കി';

  @override
  String get remove => 'നീക്കുക';

  @override
  String get add => 'ചേർക്കുക';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ദിവസം',
      one: '1 ദിവസം',
    );
    return '$_temp0';
  }

  @override
  String dateRange(String from, String to) {
    return '$from മുതൽ $to വരെ';
  }

  @override
  String get authSubtitle =>
      'Kaylo നൽകിയ പാർട്ണർ ഐഡി ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get authSignIn => 'സൈൻ ഇൻ';

  @override
  String get authPartnerId => 'പാർട്ണർ ഐഡി';

  @override
  String get authPassword => 'പാസ്‌വേഡ്';

  @override
  String get authShowPassword => 'പാസ്‌വേഡ് കാണിക്കുക';

  @override
  String get authHidePassword => 'പാസ്‌വേഡ് മറയ്ക്കുക';

  @override
  String get authForgotPassword => 'പാസ്‌വേഡ് മറന്നോ? Kaylo-യെ ബന്ധപ്പെടുക';

  @override
  String get authSupport => 'Kaylo സഹായം തേടുക';

  @override
  String get authApply => 'പാർട്ണറാകാൻ അപേക്ഷിക്കുക';

  @override
  String get authCheckStatus => 'അപേക്ഷയുടെ സ്ഥിതി പരിശോധിക്കുക';

  @override
  String get authDemoCredentials => 'ഡെമോ: KP-000123 / kaylo123';

  @override
  String get authInvalidId => 'KP-000123 പോലെയുള്ള സാധുവായ പാർട്ണർ ഐഡി നൽകുക.';

  @override
  String get authInvalidCredentials => 'പാർട്ണർ ഐഡിയോ പാസ്‌വേഡോ തെറ്റാണ്.';

  @override
  String get authTooManyAttempts =>
      'നിരവധി ശ്രമങ്ങൾ നടന്നു. അൽപ്പം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get authNetworkError =>
      'ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get authUnavailableTitle => 'അക്കൗണ്ട് പരിശോധിക്കാനായില്ല';

  @override
  String get authUnavailable =>
      'നിങ്ങളുടെ പാർട്ണർ പ്രവേശനം പരിശോധിക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക അല്ലെങ്കിൽ Kaylo സഹായം തേടുക.';

  @override
  String get authPasswordRule =>
      'പുതിയ പാസ്‌വേഡിൽ കുറഞ്ഞത് 12 അക്ഷരങ്ങൾ ഉപയോഗിക്കുക.';

  @override
  String get authDifferentPassword =>
      'താൽക്കാലിക പാസ്‌വേഡിൽനിന്ന് വ്യത്യസ്തമായത് തിരഞ്ഞെടുക്കുക.';

  @override
  String get authSessionExpired =>
      'സെഷൻ കാലഹരണപ്പെട്ടു. സൈൻ ഔട്ട് ചെയ്ത് വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get authPasswordConfirmation =>
      'പാസ്‌വേഡ് മാറ്റം സ്ഥിരീകരിക്കേണ്ടതുണ്ട്. വീണ്ടും ശ്രമിക്കാൻ പാസ്‌വേഡ് സംരക്ഷിക്കുക അമർത്തുക.';

  @override
  String get authIdentityNotAllowed =>
      'Kaylo നൽകിയ പാർട്ണർ ഐഡിയും പാസ്‌വേഡും ഉപയോഗിക്കുക. ഉപഭോക്തൃ അക്കൗണ്ടുകൾക്ക് ഇവിടെ പ്രവേശിക്കാനാകില്ല.';

  @override
  String get authChangePassword => 'നിങ്ങളുടെ പാസ്‌വേഡ് സജ്ജമാക്കുക';

  @override
  String get authChangePasswordBody =>
      'പാർട്ണർ അക്കൗണ്ടിൽ പ്രവേശിക്കുന്നതിനുമുമ്പ് താൽക്കാലിക പാസ്‌വേഡ് മാറ്റുക.';

  @override
  String get authNewPassword => 'പുതിയ പാസ്‌വേഡ്';

  @override
  String get authConfirmPassword => 'പുതിയ പാസ്‌വേഡ് ഉറപ്പാക്കുക';

  @override
  String get authSavePassword => 'പാസ്‌വേഡ് സംരക്ഷിക്കുക';

  @override
  String get authPasswordMismatch => 'പാസ്‌വേഡുകൾ പൊരുത്തപ്പെടുന്നില്ല.';

  @override
  String get authNotIssuedBody =>
      'ഈ അക്കൗണ്ടിന് നൽകിയ തൊഴിലാളി പ്രൊഫൈൽ ഇല്ല. Kaylo-യിൽ അപേക്ഷിക്കുക അല്ലെങ്കിൽ അപേക്ഷയെക്കുറിച്ച് സഹായം തേടുക.';

  @override
  String get authVerificationBody =>
      'Kaylo പരിശോധന അംഗീകരിച്ചശേഷം ജോലികൾ ലഭ്യമാകും. പ്രൊഫൈൽ കാണുകയോ സഹായം തേടുകയോ ചെയ്യാം.';

  @override
  String get partnerJobNotifications => 'ജോലി അഭ്യർത്ഥനകൾ';

  @override
  String get partnerNewJobRequest => 'പുതിയ ജോലി അഭ്യർത്ഥന';

  @override
  String get partnerOpenJobRequest =>
      'അഭ്യർത്ഥന പരിശോധിക്കാൻ Kaylo Partner തുറക്കുക.';

  @override
  String get applicationTitle => 'Kaylo-യിൽ അപേക്ഷിക്കുക';

  @override
  String get applicationPersonal => 'നിങ്ങളെക്കുറിച്ച്';

  @override
  String get applicationSkills => 'നിങ്ങളുടെ ജോലിയും സേവന മേഖലയും';

  @override
  String get applicationDocuments => 'നിങ്ങളുടെ രേഖകൾ';

  @override
  String get applicationPayout => 'പണമടയ്ക്കലും സമ്മതവും';

  @override
  String applicationStep(int current, int total) {
    return 'ഘട്ടം $current / $total';
  }

  @override
  String get applicationIntro =>
      'അക്കൗണ്ടില്ലാതെ അപേക്ഷിക്കാം. പാർട്ണർ ലോഗിൻ നൽകുന്നതിന് മുമ്പ് Kaylo നിങ്ങളുടെ വിവരങ്ങളും രേഖകളും പരിശോധിക്കും.';

  @override
  String get applicationPhone => 'ഫോൺ നമ്പർ';

  @override
  String get applicationEmail => 'വിവരങ്ങൾ അയയ്ക്കേണ്ട ഇമെയിൽ';

  @override
  String get applicationEmailHint =>
      'നിങ്ങൾക്ക് തുറക്കാനാകുന്ന ഇമെയിൽ നൽകുക. അംഗീകാരത്തിന് ശേഷം പാർട്ണർ ഐഡിയും താൽക്കാലിക പാസ്‌വേഡും Kaylo ഇതിലേക്ക് അയയ്ക്കും.';

  @override
  String get applicationInvalidPhone =>
      'രാജ്യ കോഡ് സഹിതം ശരിയായ ഫോൺ നമ്പർ നൽകുക';

  @override
  String get applicationInvalidEmail => 'ശരിയായ ഇമെയിൽ വിലാസം നൽകുക';

  @override
  String get applicationProfession => 'തൊഴിൽ';

  @override
  String get applicationProfessionRequired => 'നിങ്ങളുടെ തൊഴിൽ നൽകുക';

  @override
  String get applicationExperience => 'പ്രവൃത്തിപരിചയം (വർഷം)';

  @override
  String get applicationInvalidExperience =>
      '0 മുതൽ 60 വർഷം വരെയുള്ള പരിചയം നൽകുക';

  @override
  String get applicationChooseDistrict => 'നിങ്ങളുടെ ജില്ല തിരഞ്ഞെടുക്കുക';

  @override
  String get applicationNoServices =>
      'സേവന പട്ടിക ഇപ്പോൾ ലഭ്യമല്ല. പിന്നീട് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get applicationDocumentsHint =>
      'അഞ്ച് രേഖകളും ചേർക്കുക. ഫോട്ടോകൾക്ക് JPG അല്ലെങ്കിൽ PNG; മറ്റ് രേഖകൾക്ക് JPG, PNG അല്ലെങ്കിൽ PDF. ഓരോ ഫയലും പരമാവധി 10 MB.';

  @override
  String get applicationDocumentsPrivacy =>
      'അപേക്ഷ പരിശോധിക്കാൻ രേഖകൾ സ്വകാര്യമായി Kaylo-യിലേക്ക് അപ്‌ലോഡ് ചെയ്യുന്നു. പൊതു സ്റ്റാറ്റസ് പരിശോധനയിൽ അവ കാണിക്കില്ല.';

  @override
  String get applicationPhoto => 'പ്രൊഫൈൽ ഫോട്ടോ';

  @override
  String get applicationAadhaarFront => 'ആധാറിന്റെ മുൻവശം';

  @override
  String get applicationAadhaarBack => 'ആധാറിന്റെ പിൻവശം';

  @override
  String get applicationSelfie => 'സെൽഫി';

  @override
  String get applicationChooseFile => 'ഫയൽ തിരഞ്ഞെടുക്കുക';

  @override
  String get applicationAllDocuments => 'തുടരാൻ അഞ്ച് രേഖകളും ചേർക്കുക';

  @override
  String get applicationUpi => 'UPI';

  @override
  String get applicationBank => 'ബാങ്ക് അക്കൗണ്ട്';

  @override
  String get applicationAccountHolder => 'അക്കൗണ്ട് ഉടമയുടെ പേര്';

  @override
  String get applicationBankName => 'ബാങ്കിന്റെ പേര്';

  @override
  String get applicationAccountNumber => 'അക്കൗണ്ട് നമ്പർ';

  @override
  String get applicationConfirmAccount => 'അക്കൗണ്ട് നമ്പർ വീണ്ടും നൽകുക';

  @override
  String get applicationIfsc => 'IFSC കോഡ്';

  @override
  String get applicationBankRequired => 'ബാങ്ക് വിവരങ്ങൾ നൽകുക';

  @override
  String get applicationInvalidAccount =>
      '9 മുതൽ 18 അക്കങ്ങളുള്ള അക്കൗണ്ട് നമ്പർ നൽകുക';

  @override
  String get applicationAccountMismatch =>
      'അക്കൗണ്ട് നമ്പറുകൾ പൊരുത്തപ്പെടുന്നില്ല';

  @override
  String get applicationInvalidIfsc =>
      '11 അക്ഷരങ്ങളുള്ള ശരിയായ IFSC കോഡ് നൽകുക';

  @override
  String get applicationReviewHint =>
      'അയയ്ക്കുന്നതിന് മുമ്പ് വിവരങ്ങൾ പരിശോധിക്കുക.';

  @override
  String get applicationConsent =>
      'ഈ വിവരങ്ങൾ എന്റേതും ശരിയുമാണെന്ന് ഞാൻ സ്ഥിരീകരിക്കുന്നു. പാർട്ണർ പരിശോധനയ്ക്കായി എന്റെ വിവരങ്ങളും രേഖകളും സൂക്ഷിക്കാനും പരിശോധിക്കാനും Kaylo-യ്ക്ക് സമ്മതം നൽകുന്നു.';

  @override
  String get applicationConsentRequired =>
      'അയയ്ക്കുന്നതിന് മുമ്പ് സമ്മതം നൽകുക';

  @override
  String get applicationKeepOpen =>
      'എല്ലാ രേഖകളും അപ്‌ലോഡ് ആകുന്നത് വരെ Kaylo തുറന്നുവയ്ക്കുക. ബന്ധം നഷ്ടപ്പെട്ടാൽ പുതിയ അപേക്ഷ നൽകാതെ ഇവിടെ തന്നെ വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get applicationBack => 'പിന്നോട്ട്';

  @override
  String get applicationContinue => 'തുടരുക';

  @override
  String get applicationSubmit => 'അപേക്ഷ അയയ്ക്കുക';

  @override
  String get applicationSending => 'അപേക്ഷ അയയ്ക്കുന്നത് പൂർത്തിയാക്കുക';

  @override
  String get applicationRecoveryHint =>
      'അഞ്ച് രേഖകളും ലഭിച്ചാൽ മാത്രമേ അപേക്ഷ പരിശോധനയ്ക്ക് തയ്യാറാകൂ. വീണ്ടും ശ്രമിക്കുമ്പോൾ അതേ അപേക്ഷ തുടരും. പൂർത്തിയാകുന്നതിന് മുമ്പ് ആപ്പ് അടച്ചാൽ റഫറൻസ് നൽകി Kaylo-യെ ബന്ധപ്പെടുക.';

  @override
  String get applicationReference => 'അപേക്ഷയുടെ റഫറൻസ്';

  @override
  String applicationUploadProgress(int count, int total) {
    return '$total രേഖകളിൽ $count ലഭിച്ചു';
  }

  @override
  String get applicationCheckStatus => 'അപേക്ഷയുടെ നില പരിശോധിക്കുക';

  @override
  String get applicationBackToSignIn => 'സൈൻ ഇന്നിലേക്ക് മടങ്ങുക';

  @override
  String get applicationStatusHint =>
      'നില അറിയാൻ അപേക്ഷയുടെ റഫറൻസ് നൽകുക. വ്യക്തിഗത വിവരങ്ങളും രേഖകളും ഇവിടെ ഒരിക്കലും കാണിക്കില്ല.';

  @override
  String get applicationInvalidReference => 'അപേക്ഷയിൽ ലഭിച്ച റഫറൻസ് നൽകുക';

  @override
  String get applicationUnderReview => 'അപേക്ഷ പരിശോധിച്ചുകൊണ്ടിരിക്കുന്നു';

  @override
  String get applicationUnderReviewHint =>
      'നിങ്ങളുടെ വിവരങ്ങളും അഞ്ച് രേഖകളും ലഭിച്ചു. തീരുമാനമെടുക്കുന്നതിന് മുമ്പ് Kaylo അവ പരിശോധിക്കും. ഈ റഫറൻസ് പാർട്ണർ ലോഗിൻ അല്ല.';

  @override
  String get applicationIncomplete => 'രേഖകൾ ഇനിയും ലഭിക്കാനുണ്ട്';

  @override
  String get applicationIncompleteHint =>
      'നിങ്ങളുടെ വിവരങ്ങൾ ലഭിച്ചു, എന്നാൽ രേഖകളുടെ അപ്‌ലോഡ് പൂർത്തിയായിട്ടില്ല. ഈ ആപ്പ് സെഷനിൽ തുടരുക അല്ലെങ്കിൽ റഫറൻസ് നൽകി Kaylo-യുടെ സഹായം തേടുക.';

  @override
  String get applicationApproved => 'അപേക്ഷ അംഗീകരിച്ചു';

  @override
  String get applicationApprovedHint =>
      'അംഗീകാരത്തിന് ശേഷം പാർട്ണർ ഐഡിയും താൽക്കാലിക പാസ്‌വേഡും Kaylo ഇമെയിലിൽ അയയ്ക്കും. ലഭിച്ചില്ലെങ്കിൽ സഹായത്തിനായി ബന്ധപ്പെടുക. ആദ്യ സൈൻ ഇന്നിൽ പുതിയ പാസ്‌വേഡ് നൽകണം.';

  @override
  String get applicationRejected => 'അപേക്ഷ അംഗീകരിച്ചില്ല';

  @override
  String get applicationRejectedHint =>
      'ഈ അപേക്ഷ Kaylo അംഗീകരിച്ചിട്ടില്ല. ഇതിന് പാർട്ണർ ലോഗിൻ ലഭ്യമല്ല. കൂടുതൽ സഹായത്തിന് റഫറൻസ് നൽകി ബന്ധപ്പെടുക.';

  @override
  String get applicationCopyReference => 'റഫറൻസ് പകർത്തുക';

  @override
  String get applicationReferenceCopied => 'റഫറൻസ് പകർത്തി';

  @override
  String get applicationResumeUpload => 'രേഖകളുടെ അപ്‌ലോഡ് തുടരുക';

  @override
  String get applicationContactSupport => 'Kaylo സഹായവുമായി ബന്ധപ്പെടുക';

  @override
  String applicationSupportSubject(String reference) {
    return 'പാർട്ണർ അപേക്ഷ സഹായം: $reference';
  }

  @override
  String get applicationSupportHint =>
      'അപേക്ഷയുടെ റഫറൻസ് സഹിതം kayloapp@gmail.com-ലേക്ക് ഇമെയിൽ അയയ്ക്കുക.';

  @override
  String get applicationDemoNotice =>
      'സാമ്പിൾ മോഡ്: ഈ അപേക്ഷ ഈ ആപ്പ് സെഷനിൽ മാത്രം നിലനിൽക്കും; Kaylo-യ്ക്ക് അയയ്ക്കില്ല.';

  @override
  String get applicationConnectionError =>
      'ബന്ധപ്പെടാനായില്ല. ഇന്റർനെറ്റ് പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get applicationAlreadyOpen =>
      'ഈ ഫോൺ നമ്പറിൽ ഒരു അപേക്ഷ നിലവിലുണ്ട്. അതിന്റെ നില പരിശോധിക്കുക അല്ലെങ്കിൽ Kaylo സഹായവുമായി ബന്ധപ്പെടുക.';

  @override
  String get applicationInvalidDetails => 'അപേക്ഷയിലെ വിവരങ്ങൾ പരിശോധിക്കുക.';

  @override
  String get applicationInvalidDocument =>
      '10 MB വരെയുള്ള ശരിയായ JPG, PNG അല്ലെങ്കിൽ PDF ഫയൽ തിരഞ്ഞെടുക്കുക. പ്രൊഫൈൽ ഫോട്ടോയും സെൽഫിയും ചിത്രങ്ങളായിരിക്കണം.';

  @override
  String get applicationUploadExpired =>
      'അപ്‌ലോഡ് സെഷൻ ഇനി ലഭ്യമല്ല. അപേക്ഷ പൂർത്തിയാക്കാൻ റഫറൻസ് നൽകി Kaylo-യെ ബന്ധപ്പെടുക.';

  @override
  String get applicationNotFound =>
      'ഈ റഫറൻസിൽ അപേക്ഷ കണ്ടെത്തിയില്ല. റഫറൻസ് പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get applicationUnavailable =>
      'അപേക്ഷ സേവനം ഇപ്പോൾ ലഭ്യമല്ല. പിന്നീട് ശ്രമിക്കുക അല്ലെങ്കിൽ Kaylo സഹായവുമായി ബന്ധപ്പെടുക.';

  @override
  String get applicationIdentityInUse =>
      'ഈ ഫോണോ ഇമെയിലോ ഒരു Kaylo അക്കൗണ്ടിൽ ഉപയോഗിക്കുന്നു. ഈ വിവരങ്ങൾ ഉപയോഗിച്ച് അപേക്ഷിക്കുന്നതിന് മുമ്പ് സഹായവുമായി ബന്ധപ്പെടുക.';

  @override
  String get liveJobsPending =>
      'തത്സമയ ജോലി അഭ്യർത്ഥനകളും വരുമാനവും ഇതുവരെ ലഭ്യമല്ല. നിങ്ങളുടെ പ്രൊഫൈലും ലഭ്യതയും ഉപയോഗിക്കാം.';

  @override
  String get applicationChangesRequested => 'മാറ്റങ്ങൾ ആവശ്യപ്പെട്ടു';

  @override
  String get applicationChangesRequestedHint =>
      'അപേക്ഷ വീണ്ടും പരിശോധിക്കാൻ Kaylo-യ്ക്ക് പുതുക്കിയ രേഖകൾ ആവശ്യമാണ്. നിർദ്ദേശങ്ങൾ കാണാനും പുതിയ രേഖകൾ നൽകാനും ഇമെയിലിൽ ലഭിച്ച സുരക്ഷിത ലിങ്ക് തുറക്കുക.';

  @override
  String get chatMessages => 'സന്ദേശങ്ങൾ';

  @override
  String get chatTitle => 'ചാറ്റ്';

  @override
  String chatUnread(int count) {
    return 'ചാറ്റ് ($count)';
  }

  @override
  String get chatViewConversation => 'സംഭാഷണം കാണുക';

  @override
  String get chatNoMessages => 'നിങ്ങളുടെ സംഭാഷണങ്ങൾ ഇവിടെ തുടങ്ങുന്നു';

  @override
  String get chatNoMessagesBody =>
      'ജോലി സ്വീകരിച്ച ശേഷം ഉപഭോക്താവിന് സന്ദേശമയയ്ക്കാൻ ചാറ്റ് തുറക്കുക.';

  @override
  String get chatStartConversation =>
      'ഈ ബുക്കിങ്ങിനെക്കുറിച്ച് സന്ദേശമയയ്ക്കുക.';

  @override
  String get chatLoadFailed =>
      'സംഭാഷണം ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get chatMessageHint => 'ഉപഭോക്താവിന് സന്ദേശം';

  @override
  String get chatSend => 'സന്ദേശം അയയ്ക്കുക';

  @override
  String get chatSendFailed => 'സന്ദേശം അയയ്ക്കാനായില്ല. വീണ്ടും അയയ്ക്കുക.';

  @override
  String get chatTyping => 'ഉപഭോക്താവ് ടൈപ്പ് ചെയ്യുന്നു…';

  @override
  String get chatRead => 'വായിച്ചു';

  @override
  String get chatSent => 'അയച്ചു';

  @override
  String get chatReadOnly => 'ഈ ബുക്കിങ് അവസാനിച്ചു. സംഭാഷണം ഇനിയും വായിക്കാം.';

  @override
  String get chatOnMyWay => 'വന്നുകൊണ്ടിരിക്കുന്നു';

  @override
  String get chatReached => 'ഞാൻ എത്തി';

  @override
  String get chatLate => '10 മിനിറ്റ് വൈകും';

  @override
  String get chatExactLocation => 'കൃത്യമായ സ്ഥലം പങ്കിടാമോ';

  @override
  String get chatMockBackGate => 'പിന്നിലെ ഗേറ്റിലേക്ക് വരൂ.';

  @override
  String get chatMockWaiting => 'ശരി, കാത്തിരിക്കുന്നു.';

  @override
  String get chatMockCall => 'എത്തുമ്പോൾ വിളിക്കൂ.';

  @override
  String get chatMockTenMinutes => '10 മിനിറ്റ് മതിയോ?';

  @override
  String get chatMockThanks => 'നന്ദി!';

  @override
  String get chatMockDog => 'നായ ശാന്തമാണ്, പേടിക്കേണ്ട.';

  @override
  String get alertsTitle => 'അറിയിപ്പുകൾ';

  @override
  String get alertsMarkAllRead => 'എല്ലാം വായിച്ചതായി അടയാളപ്പെടുത്തുക';

  @override
  String get alertsToday => 'ഇന്ന്';

  @override
  String get alertsEarlier => 'മുമ്പുള്ളവ';

  @override
  String get alertsEmpty => 'പുതിയ അറിയിപ്പുകളൊന്നുമില്ല';

  @override
  String get alertsEmptyBody =>
      'പുതിയ അഭ്യർഥനകളും ജോലിയുടെ വിവരങ്ങളും ഇവിടെ കാണാം.';

  @override
  String get alertsLoadFailed =>
      'അറിയിപ്പുകൾ ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get alertsUpdateFailed =>
      'അറിയിപ്പ് പുതുക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get alertNewRequest => 'പുതിയ ജോലി അഭ്യർഥന';

  @override
  String get alertAccepted => 'ജോലി സ്വീകരിച്ചു';

  @override
  String get alertOnTheWay => 'നിങ്ങൾ വരുന്ന വിവരം ഉപഭോക്താവിനെ അറിയിച്ചു';

  @override
  String get alertArrived => 'എത്തിയത് സ്ഥിരീകരിച്ചു';

  @override
  String get alertInProgress => 'ജോലി തുടങ്ങി';

  @override
  String get alertCompleted => 'ജോലി പൂർത്തിയായി';

  @override
  String get alertCancelled => 'ജോലി റദ്ദാക്കി';

  @override
  String alertRequestBody(String service, String distance) {
    return '$service · $distance കി.മീ. അകലെ';
  }

  @override
  String alertJobBody(String service) {
    return '$service · ബുക്കിങ് വിവരങ്ങൾ കാണുക';
  }

  @override
  String get reviewsTitle => 'അവലോകനങ്ങൾ';

  @override
  String get reviewsSeeAll => 'എല്ലാം കാണുക';

  @override
  String get reviewsCustomerRating => 'ഉപഭോക്താവിന്റെ റേറ്റിങ്';

  @override
  String reviewsDistribution(int stars, int count) {
    return '$stars സ്റ്റാർ: $count അവലോകനങ്ങൾ';
  }

  @override
  String get reviewsAll => 'എല്ലാം';

  @override
  String get reviewsFive => '5 സ്റ്റാർ';

  @override
  String get reviewsFour => '4 സ്റ്റാർ';

  @override
  String get reviewsThreeBelow => '3 സ്റ്റാറും താഴെയും';

  @override
  String get reviewsEmpty => 'അവലോകനങ്ങളൊന്നുമില്ല';

  @override
  String get reviewsEmptyBody =>
      'പൂർത്തിയായ ജോലികളുടെ ഉപഭോക്തൃ അവലോകനങ്ങൾ ഇവിടെ കാണാം.';

  @override
  String get reviewsLoadFailed =>
      'അവലോകനങ്ങൾ ലോഡ് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get reviewSample1 =>
      'ചോരുന്ന ടാപ്പ് നന്നായി ശരിയാക്കി, ചെയ്ത ജോലി വിശദീകരിച്ചു.';

  @override
  String get reviewSample2 => 'സമയത്തിനെത്തി, വളരെ സഹായിച്ചു.';

  @override
  String get reviewSample3 => 'നല്ല ജോലി. സ്ഥലം വൃത്തിയാക്കി മടങ്ങി.';

  @override
  String get reviewSample4 =>
      'ശ്രദ്ധയോടെ ജോലി ചെയ്തു, എല്ലാ കാര്യങ്ങളും വ്യക്തമായി പറഞ്ഞു.';

  @override
  String get reviewSample5 =>
      'ജോലി നന്നായിരുന്നു, പക്ഷേ അറിയിക്കാതെ അരമണിക്കൂർ വൈകി.';

  @override
  String get reviewSample6 => 'വീണ്ടും ബുക്ക് ചെയ്യാൻ സന്തോഷം.';

  @override
  String get reviewSample7 =>
      'പ്രശ്നം പരിഹരിച്ചു, എല്ലാ ചോദ്യങ്ങൾക്കും മറുപടി നൽകി.';

  @override
  String get reviewSample8 =>
      'ക്ഷമയോടെയും മര്യാദയോടെയും നന്നായി ജോലി ചെയ്തു. നന്ദി.';

  @override
  String get chatCallCustomer => 'ഉപഭോക്താവിനെ വിളിക്കുക';

  @override
  String get chatNavigate => 'വഴി കാണുക';

  @override
  String get partnerJobReadOnly =>
      'ജോലി വിവരങ്ങൾ കാണാനും ഉപഭോക്താവിനെ ബന്ധപ്പെടാനും കഴിയും. ജോലിയുടെ സ്ഥിതി പുതുക്കാനുള്ള സൗകര്യം ഉടൻ ലഭ്യമാകും.';

  @override
  String get alertCashCollected => 'പണം കൈപ്പറ്റി';

  @override
  String get alertPaymentReceived => 'പണമടവ് ലഭിച്ചു';

  @override
  String get alertSettlement => 'കണക്കുതീർപ്പ് രേഖപ്പെടുത്തി';
}
