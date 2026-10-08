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
  String get refreshJobsTooltip => 'பணிகளைப் புதுப்பிக்கவும்';

  @override
  String get tabJobs => 'பணிகள்';

  @override
  String get tabEarnings => 'வருவாய்';

  @override
  String get tabProfile => 'சுயவிவரம்';

  @override
  String get dutyOnline => 'நீங்கள் ஆன்லைனில் உள்ளீர்கள்';

  @override
  String get dutyOffline => 'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள்';

  @override
  String dutyTakingOrders(String district) {
    return '$district மாவட்டத்தில் முன்பதிவுகளை ஏற்கிறது';
  }

  @override
  String get dutyNotReceivingRequests => 'கோரிக்கைகள் பெறப்படவில்லை';

  @override
  String get todaysPay => 'இன்றைய வருமானம்';

  @override
  String get jobsToday => 'இன்றைய பணிகள்';

  @override
  String get rating => 'மதிப்பீடு';

  @override
  String get activeJob => 'செயலில் உள்ள பணி';

  @override
  String get offlineTitle => 'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள்';

  @override
  String get offlineDescription =>
      'வாடிக்கையாளர்களிடமிருந்து அருகிலுள்ள பணிக் கோரிக்கைகளைப் பெற மேலே உங்கள் நிலையை ஆன்லைனுக்கு மாற்றவும்.';

  @override
  String newRequests(int count) {
    return 'புதிய கோரிக்கைகள் ($count)';
  }

  @override
  String get searchingForRequests => 'கோரிக்கைகளைத் தேடுகிறது...';

  @override
  String get searchingForRequestsSubtitle =>
      'அருகிலுள்ள வாடிக்கையாளர் முன்பதிவு செய்யும் போது உங்களுக்கு அறிவிப்பு வரும்.';

  @override
  String get payout => 'வருமானம்';

  @override
  String get decline => 'நிராகரி';

  @override
  String get acceptJob => 'பணியை ஏற்றுக்கொள்';

  @override
  String get stageRequested => 'கோரப்பட்டது';

  @override
  String get stageAccepted => 'ஏற்றுக்கொள்ளப்பட்டது';

  @override
  String get stageOnTheWay => 'வழியில்';

  @override
  String get stageArrived => 'வந்து சேர்ந்தார்';

  @override
  String get stageInProgress => 'செயலில் உள்ளது';

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
  String get actionStartJob => 'பணியைத் தொடங்கு';

  @override
  String get actionCompleteJob => 'பணியை முடிக்கவும்';

  @override
  String timeInMinutes(int minutes) {
    return '$minutes நிமிடங்களில்';
  }

  @override
  String timeInHours(int hours) {
    return '$hours மணிநேரத்தில்';
  }

  @override
  String timeTomorrow(String time) {
    return 'நாளை $time';
  }

  @override
  String timeToday(String time) {
    return 'இன்று $time';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes நிமிடங்களுக்கு முன்பு';
  }

  @override
  String get sortNearest => 'மிக அருகில்';

  @override
  String get sortHighestPayout => 'அதிக வருமானம்';

  @override
  String get sortSoonest => 'விரைவில்';

  @override
  String get filterEmptyTitle => 'வடிகட்டலுக்கு பொருந்தும் பணிகள் இல்லை';

  @override
  String get filterEmptySubtitle =>
      'மற்ற வடிகட்டிகளைத் தேர்வு செய்யவும் அல்லது வடிகட்டிகளை அழிக்கவும்.';

  @override
  String get clearFilters => 'வடிகட்டிகளை அழிக்கவும்';

  @override
  String get expand => 'பெரிதாக்கு';

  @override
  String get openInGoogleMaps => 'கூகிள் வரைபடத்தில் திற';

  @override
  String aboutMinutes(int minutes) {
    return 'சுமார் $minutes நிமிடம்';
  }

  @override
  String get jobLocationMap => 'பணி இருப்பிட வரைபடம்';
}
