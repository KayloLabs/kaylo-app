// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'कायलो पार्टनर';

  @override
  String get refreshJobsTooltip => 'नौकरियां रीफ्रेश करें';

  @override
  String get tabJobs => 'काम';

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
  String get jobsToday => 'आज के काम';

  @override
  String get rating => 'रेटिंग';

  @override
  String get activeJob => 'सक्रिय काम';

  @override
  String get offlineTitle => 'आप ऑफ़लाइन हैं';

  @override
  String get offlineDescription =>
      'ग्राहकों से आस-पास के काम के अनुरोध प्राप्त करने के लिए ऊपर अपनी ड्यूटी स्थिति को ऑनलाइन करें।';

  @override
  String newRequests(int count) {
    return 'नए अनुरोध ($count)';
  }

  @override
  String get searchingForRequests => 'अनुरोध खोजे जा रहे हैं...';

  @override
  String get searchingForRequestsSubtitle =>
      'जब कोई आस-पास का ग्राहक बुक करेगा तो आपको एक पिंग सुनाई देगी।';

  @override
  String get payout => 'भुगतान';

  @override
  String get decline => 'अस्वीकार करें';

  @override
  String get acceptJob => 'काम स्वीकार करें';

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
  String get actionStartJob => 'काम शुरू करें';

  @override
  String get actionCompleteJob => 'काम पूरा करें';

  @override
  String get languageSettings => 'भाषा सेटिंग्स';

  @override
  String get profileLanguageTile => 'भाषा';

  @override
  String get appSettingsHeader => 'ऐप सेटिंग्स';
}
