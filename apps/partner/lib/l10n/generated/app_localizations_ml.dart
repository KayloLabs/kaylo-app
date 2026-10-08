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
  String get dutyOffline => 'നിങ്ങൾ ഓഫ്ലൈനിലാണ്';

  @override
  String dutyTakingOrders(String district) {
    return '$district ജില്ലയിൽ ഓർഡറുകൾ സ്വീകരിക്കുന്നു';
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
  String get activeJob => 'നിലവിലെ ജോലി';

  @override
  String get offlineTitle => 'നിങ്ങൾ ഓഫ്ലൈനിലാണ്';

  @override
  String get offlineDescription =>
      'ഉപഭോക്താക്കളിൽ നിന്ന് പുതിയ ജോലികൾ ലഭിക്കാൻ മുകളിലുള്ള ഡ്യൂട്ടി സ്റ്റാറ്റസ് ഓൺലൈനിലേക്ക് മാറ്റുക.';

  @override
  String newRequests(int count) {
    return 'പുതിയ അഭ്യർത്ഥനകൾ ($count)';
  }

  @override
  String get searchingForRequests => 'അഭ്യർത്ഥനകൾ തിരയുന്നു...';

  @override
  String get searchingForRequestsSubtitle =>
      'ഒരു ഉപഭോക്താവ് ബുക്ക് ചെയ്യുമ്പോൾ നോട്ടിഫിക്കേഷൻ ലഭിക്കും.';

  @override
  String get payout => 'പ്രതിഫലം';

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
  String get actionStartTravel => 'യാത്ര ആരംഭിക്കുക';

  @override
  String get actionArrived => 'ഞാൻ എത്തിച്ചേർന്നു';

  @override
  String get actionStartJob => 'ജോലി തുടങ്ങുക';

  @override
  String get actionCompleteJob => 'ജോലി പൂർത്തിയാക്കുക';

  @override
  String timeInMinutes(int minutes) {
    return '$minutes മിനിറ്റിൽ';
  }

  @override
  String timeInHours(int hours) {
    return '$hours മണിക്കൂറിൽ';
  }

  @override
  String timeTomorrow(String time) {
    return 'നാളെ $time';
  }

  @override
  String timeToday(String time) {
    return 'ഇന്ന് $time';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes മിനിറ്റ് മുൻപ്';
  }

  @override
  String get sortNearest => 'ഏറ്റവും അടുത്ത്';

  @override
  String get sortHighestPayout => 'കൂടിയ വരുമാനം';

  @override
  String get sortSoonest => 'ഉടൻ തന്നെ';

  @override
  String get filterEmptyTitle => 'ഫിൽട്ടറുമായി പൊരുത്തപ്പെടുന്ന ജോലികളില്ല';

  @override
  String get filterEmptySubtitle =>
      'മറ്റ് ഫിൽട്ടറുകൾ തിരഞ്ഞെടുക്കുക അല്ലെങ്കിൽ ഫിൽട്ടറുകൾ നീക്കം ചെയ്യുക.';

  @override
  String get clearFilters => 'ഫിൽട്ടറുകൾ നീക്കുക';

  @override
  String get expand => 'വലുതാക്കുക';

  @override
  String get openInGoogleMaps => 'ഗൂഗിൾ മാപ്പിൽ തുറക്കുക';

  @override
  String aboutMinutes(int minutes) {
    return 'ഏകദേശം $minutes മിനിറ്റ്';
  }

  @override
  String get jobLocationMap => 'ജോലി സ്ഥലത്തിന്റെ മാപ്പ്';
}
