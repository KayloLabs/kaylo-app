// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'கெய்லோ பார்ட்னர்';

  @override
  String get refreshJobsTooltip => 'வேலைகளைப் புதுப்பிக்கவும்';

  @override
  String get tabJobs => 'வேலைகள்';

  @override
  String get tabEarnings => 'வருமானம்';

  @override
  String get tabProfile => 'சுயவிவரம்';

  @override
  String get dutyOnline => 'நீங்கள் ஆன்லைனில் உள்ளீர்கள்';

  @override
  String get dutyOffline => 'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள்';

  @override
  String dutyTakingOrders(String district) {
    return '$district இல் ஆர்டர்களை எடுக்கிறீர்கள்';
  }

  @override
  String get dutyNotReceivingRequests => 'கோரிக்கைகளைப் பெறவில்லை';

  @override
  String get todaysPay => 'இன்றைய வருமானம்';

  @override
  String get jobsToday => 'இன்றைய வேலைகள்';

  @override
  String get rating => 'மதிப்பீடு';

  @override
  String get activeJob => 'செயலில் உள்ள வேலை';

  @override
  String get offlineTitle => 'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள்';

  @override
  String get offlineDescription =>
      'அருகிலுள்ள வாடிக்கையாளர்களிடமிருந்து வேலை கோரிக்கைகளைப் பெற உங்கள் கடமை நிலையை ஆன்லைனுக்கு மாற்றவும்.';

  @override
  String newRequests(int count) {
    return 'புதிய கோரிக்கைகள் ($count)';
  }

  @override
  String get searchingForRequests => 'கோரிக்கைகளைத் தேடுகிறது...';

  @override
  String get searchingForRequestsSubtitle =>
      'அருகிலுள்ள வாடிக்கையாளர் முன்பதிவு செய்யும்போது ஒரு பிங் சத்தம் கேட்கும்.';

  @override
  String get payout => 'பேஅவுட்';

  @override
  String get decline => 'நிராகரி';

  @override
  String get acceptJob => 'வேலையை ஏற்றுக்கொள்';

  @override
  String get stageRequested => 'கோரப்பட்டது';

  @override
  String get stageAccepted => 'ஏற்றுக்கொள்ளப்பட்டது';

  @override
  String get stageOnTheWay => 'வழியில்';

  @override
  String get stageArrived => 'வந்துவிட்டது';

  @override
  String get stageInProgress => 'செயல்பாட்டில்';

  @override
  String get stageCompleted => 'முடிந்தது';

  @override
  String get stageCancelled => 'ரத்து செய்யப்பட்டது';

  @override
  String get actionAccept => 'ஏற்றுக்கொள்';

  @override
  String get actionStartTravel => 'பயணத்தைத் தொடங்கு';

  @override
  String get actionArrived => 'நான் வந்துவிட்டேன்';

  @override
  String get actionStartJob => 'வேலையைத் தொடங்கு';

  @override
  String get actionCompleteJob => 'வேலையை முடி';

  @override
  String get languageSettings => 'மொழி அமைப்புகள்';

  @override
  String get profileLanguageTile => 'மொழி';

  @override
  String get appSettingsHeader => 'பயன்பாட்டு அமைப்புகள்';
}
