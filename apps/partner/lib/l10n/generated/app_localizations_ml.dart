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
}
