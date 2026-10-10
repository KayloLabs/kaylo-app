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
      'ജോലികൾ ലഭിക്കാൻ ഫോൺ നമ്പർ ഉപയോഗിച്ച് വീണ്ടും സൈൻ ഇൻ ചെയ്യേണ്ടി വരും.';

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
}
