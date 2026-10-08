// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kaylo Partner';

  @override
  String get refreshJobsTooltip => 'Refresh jobs';

  @override
  String get tabJobs => 'Jobs';

  @override
  String get tabEarnings => 'Earnings';

  @override
  String get tabProfile => 'Profile';

  @override
  String get dutyOnline => 'You\'re Online';

  @override
  String get dutyOffline => 'You\'re Offline';

  @override
  String dutyTakingOrders(String district) {
    return 'Taking orders in $district';
  }

  @override
  String get dutyNotReceivingRequests => 'Not receiving requests';

  @override
  String get todaysPay => 'Today\'s Pay';

  @override
  String get jobsToday => 'Jobs Today';

  @override
  String get rating => 'Rating';

  @override
  String get activeJob => 'Active Job';

  @override
  String get offlineTitle => 'You\'re Offline';

  @override
  String get offlineDescription =>
      'Switch your duty status to Online above to receive nearby job requests from customers.';

  @override
  String newRequests(int count) {
    return 'New Requests ($count)';
  }

  @override
  String get searchingForRequests => 'Searching for requests...';

  @override
  String get searchingForRequestsSubtitle =>
      'You will hear a ping when a nearby customer books.';

  @override
  String get payout => 'Payout';

  @override
  String get decline => 'Decline';

  @override
  String get acceptJob => 'Accept Job';

  @override
  String get stageRequested => 'Requested';

  @override
  String get stageAccepted => 'Accepted';

  @override
  String get stageOnTheWay => 'On the way';

  @override
  String get stageArrived => 'Arrived';

  @override
  String get stageInProgress => 'In progress';

  @override
  String get stageCompleted => 'Completed';

  @override
  String get stageCancelled => 'Cancelled';

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionStartTravel => 'Start travel';

  @override
  String get actionArrived => 'I have arrived';

  @override
  String get actionStartJob => 'Start job';

  @override
  String get actionCompleteJob => 'Complete job';

  @override
  String timeInMinutes(int minutes) {
    return 'in $minutes min';
  }

  @override
  String timeInHours(int hours) {
    return 'in $hours hr';
  }

  @override
  String timeTomorrow(String time) {
    return 'tomorrow $time';
  }

  @override
  String timeToday(String time) {
    return 'today $time';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String get sortNearest => 'Nearest';

  @override
  String get sortHighestPayout => 'Highest payout';

  @override
  String get sortSoonest => 'Soonest';

  @override
  String get filterEmptyTitle => 'No jobs match your filter';

  @override
  String get filterEmptySubtitle =>
      'Try adjusting your filter options or clear them to see all jobs.';

  @override
  String get clearFilters => 'Clear filters';
}
