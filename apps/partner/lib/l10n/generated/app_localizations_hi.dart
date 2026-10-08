// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'केलो पार्टनर';

  @override
  String get refreshJobsTooltip => 'काम रीफ्रेश करें';

  @override
  String get tabJobs => 'काम';

  @override
  String get tabEarnings => 'कमाई';

  @override
  String get tabProfile => 'प्रोफ़ाइल';

  @override
  String get dutyOnline => 'आप ऑनलाइन हैं';

  @override
  String get dutyOffline => 'आप ऑफलाइन हैं';

  @override
  String dutyTakingOrders(String district) {
    return '$district में ऑर्डर स्वीकार किए जा रहे हैं';
  }

  @override
  String get dutyNotReceivingRequests => 'नए अनुरोध प्राप्त नहीं हो रहे हैं';

  @override
  String get todaysPay => 'आज की कमाई';

  @override
  String get jobsToday => 'आज के काम';

  @override
  String get rating => 'रेटिंग';

  @override
  String get activeJob => 'सक्रिय काम';

  @override
  String get offlineTitle => 'आप ऑफलाइन हैं';

  @override
  String get offlineDescription =>
      'ग्राहकों से आस-पास के काम के अनुरोध प्राप्त करने के लिए ऊपर अपनी ड्यूटी स्थिति ऑनलाइन पर बदलें।';

  @override
  String newRequests(int count) {
    return 'नए अनुरोध ($count)';
  }

  @override
  String get searchingForRequests => 'अनुरोधों की खोज जारी है...';

  @override
  String get searchingForRequestsSubtitle =>
      'जब कोई नजदीकी ग्राहक बुक करेगा तो आपको आवाज़ सुनाई देगी।';

  @override
  String get payout => 'भुगतान';

  @override
  String get decline => 'अस्वीकार करें';

  @override
  String get acceptJob => 'काम स्वीकार करें';

  @override
  String get stageRequested => 'अनुरोधित';

  @override
  String get stageAccepted => 'स्वीकृत';

  @override
  String get stageOnTheWay => 'रास्ते में';

  @override
  String get stageArrived => 'पहुंच गए';

  @override
  String get stageInProgress => 'प्रगति पर';

  @override
  String get stageCompleted => 'पूर्ण';

  @override
  String get stageCancelled => 'रद्द';

  @override
  String get actionAccept => 'स्वीकार करें';

  @override
  String get actionStartTravel => 'यात्रा शुरू करें';

  @override
  String get actionArrived => 'मैं पहुंच गया';

  @override
  String get actionStartJob => 'काम शुरू करें';

  @override
  String get actionCompleteJob => 'काम पूरा करें';

  @override
  String timeInMinutes(int minutes) {
    return '$minutes मिनट में';
  }

  @override
  String timeInHours(int hours) {
    return '$hours घंटे में';
  }

  @override
  String timeTomorrow(String time) {
    return 'कल $time';
  }

  @override
  String timeToday(String time) {
    return 'आज $time';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String get sortNearest => 'सबसे नज़दीक';

  @override
  String get sortHighestPayout => 'सबसे ज़्यादा कमाई';

  @override
  String get sortSoonest => 'सबसे पहले';

  @override
  String get filterEmptyTitle => 'कोई काम इस फ़िल्टर से मेल नहीं खाता';

  @override
  String get filterEmptySubtitle =>
      'अपने फ़िल्टर बदलें या सभी काम देखने के लिए उन्हें साफ़ करें।';

  @override
  String get clearFilters => 'फ़िल्टर हटाएं';
}
