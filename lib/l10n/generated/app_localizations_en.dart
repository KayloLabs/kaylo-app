// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello => 'Hello';

  @override
  String get searchServices => 'Search services…';

  @override
  String get whatDoYouNeedHelpWith => 'What do you need help with?';

  @override
  String get home => 'Home';

  @override
  String get homeSubtitle => 'Solutions for\nyour home.';

  @override
  String get farm => 'Farm';

  @override
  String get farmSubtitle => 'Care and support\nfor your farm.';

  @override
  String get care => 'Care';

  @override
  String get careSubtitle => 'Help for your\nloved ones.';

  @override
  String get popularServices => 'Popular Services';

  @override
  String get seeAll => 'See All';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get howCanWeHelp => 'How can we help you today?';

  @override
  String get heroCoconutTitle => 'Coconut\nHarvesting\nMade Easy';

  @override
  String get heroCoconutSubtitle => 'Book trusted climbers\nin your area';

  @override
  String get heroCleanTitle => 'Deep Clean\nYour Home\nToday';

  @override
  String get heroCleanSubtitle => 'Professional services\nat your doorstep';

  @override
  String get heroPlumberTitle => 'Expert Plumbers\n& Farmers\nReady';

  @override
  String get heroPlumberSubtitle => 'Reliable helpers for\nevery task';

  @override
  String get heroBookNow => 'Book Now';

  @override
  String get heroExplore => 'Explore';

  @override
  String get heroHireNow => 'Hire Now';

  @override
  String get promoTitle => 'Never miss important work';

  @override
  String get promoSubtitle =>
      'Set reminders and we\'ll take\ncare of the rest.';

  @override
  String get promoButton => 'Set Reminder';

  @override
  String get recommendedForYou => 'Recommended for you';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get careModeTitle => 'Kaylo Care Mode';

  @override
  String get careModeSubtitle => 'Larger text and simpler screens for seniors';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get pushNotificationsSubtitle => 'Booking updates and offers';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get termsPrivacy => 'Terms & Privacy';

  @override
  String get madeInKerala => 'Made with ♥ in Kerala';

  @override
  String get profile => 'Profile';

  @override
  String get statBookings => 'Bookings';

  @override
  String get statRating => 'Rating';

  @override
  String get statSaved => 'Saved';

  @override
  String get account => 'Account';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get myBookingsSubtitle => 'Track and manage your services';

  @override
  String get savedAddresses => 'Saved Addresses';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get preferences => 'Preferences';

  @override
  String get settingsSubtitle => 'Theme, language, care mode, notifications';

  @override
  String get support => 'Support';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get rateKaylo => 'Rate Kaylo';

  @override
  String get rateThanks => 'Thanks for the love!';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutConfirmTitle => 'Log out?';

  @override
  String get logOutConfirmMessage =>
      'You will need to sign in again to book services.';

  @override
  String get cancel => 'Cancel';

  @override
  String get profileEditSoon => 'Profile editing arrives with sign-in';

  @override
  String get kayloCare => 'Kaylo Care';

  @override
  String get careHomeGreeting => 'How can we care for you today?';

  @override
  String get medicineReminders => 'Medicine Reminders';

  @override
  String get medicineRemindersSubtitle => 'Never miss a dose';

  @override
  String get doctorAppointment => 'Doctor Appointment';

  @override
  String get doctorAppointmentSubtitle => 'Book a visit or teleconsult';

  @override
  String get emergencySos => 'Emergency SOS';

  @override
  String get emergencySosSubtitle => 'Alert your family instantly';

  @override
  String get caregiverBooking => 'Book a Caregiver';

  @override
  String get caregiverBookingSubtitle => 'Trusted help at home';

  @override
  String get themeCareOverride => 'Theme follows Care Mode while it is on';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get voiceSearch => 'Voice search';

  @override
  String get voiceListening => 'Listening…';

  @override
  String get voiceTapToSpeak => 'Speak now, in any app language';

  @override
  String get voiceYouSaid => 'You said';

  @override
  String get voiceNoMatch => 'No matching service found. Try again?';

  @override
  String get voiceUnavailable => 'Voice search is not available on this device';

  @override
  String get voiceTryAgain => 'Try again';

  @override
  String get voiceMicDenied =>
      'Microphone access was denied. Allow it in your browser or phone settings to use voice search.';

  @override
  String get farmServices => 'Farm Services';

  @override
  String get farmServicesTagline =>
      'Verified climbers, harvesters and farm hands, booked by the tree or by the hour.';

  @override
  String get noServicesTitle => 'No services yet';

  @override
  String get noServicesDescription =>
      'Farm services will appear here as workers are onboarded.';

  @override
  String perUnit(String unit) {
    return 'per $unit';
  }

  @override
  String get unitTree => 'tree';

  @override
  String get unitHour => 'hour';

  @override
  String get unitVisit => 'visit';

  @override
  String unitTreeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trees',
      one: '1 tree',
    );
    return '$_temp0';
  }

  @override
  String unitHourCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String unitVisitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visits',
      one: '1 visit',
    );
    return '$_temp0';
  }

  @override
  String get serviceStandards => 'What the worker commits to';

  @override
  String get standardSafetyHarness => 'Safety harness on every climb';

  @override
  String get standardBunchProtection =>
      'Bunches lowered on ropes, never dropped';

  @override
  String get standardDebrisCleared => 'Fronds and husks cleared before leaving';

  @override
  String get standardGroundNets => 'Ground nets to protect crops below';

  @override
  String get standardPowerLineGuard => 'Safe clearance from power lines';

  @override
  String get standardWoodChipping => 'Cut branches chipped or stacked neatly';

  @override
  String get standardEcoCompost => 'Organic compost and mulch only';

  @override
  String get standardPestPrevention => 'Pest check on every visit';

  @override
  String get standardBoundaryClearing => 'Boundaries and drains cleared';

  @override
  String get standardVerifiedWorker => 'ID-verified worker';

  @override
  String get standardOnTimeArrival => 'Arrives in the booked time slot';

  @override
  String get standardFairPrice => 'Price agreed before work starts';

  @override
  String workersNearYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verified workers near you',
      one: '1 verified worker near you',
    );
    return '$_temp0';
  }

  @override
  String get noWorkersYet => 'Workers for this service are being onboarded';

  @override
  String get liveTotalNote =>
      'Your total updates live as you set the quantity on the next step.';

  @override
  String get bookNow => 'Book now';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get selectDate => 'Date';

  @override
  String get change => 'Change';

  @override
  String get selectTimeSlot => 'Time slot';

  @override
  String get quantity => 'Quantity';

  @override
  String priceEach(String price) {
    return '$price each';
  }

  @override
  String get calculation => 'How it adds up';

  @override
  String breakdown(String price, String units) {
    return '$price × $units';
  }

  @override
  String get total => 'Total';

  @override
  String get farmAddress => 'Farm address';

  @override
  String get farmAddressHint => 'House name, street, town';

  @override
  String get addressRequired => 'Please enter the farm address';

  @override
  String get continueToPayment => 'Continue to payment';

  @override
  String get paymentTitle => 'Payment';

  @override
  String get orderSummary => 'Order summary';

  @override
  String get service => 'Service';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get rate => 'Rate';

  @override
  String get totalPayable => 'Total payable';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get payUpi => 'UPI';

  @override
  String get payUpiSubtitle => 'Google Pay, PhonePe, Paytm';

  @override
  String get payCard => 'Credit or debit card';

  @override
  String get payCardSubtitle => 'Visa, Mastercard, RuPay';

  @override
  String get payAfter => 'Pay after service';

  @override
  String get payAfterSubtitle => 'Pay the worker once the job is done';

  @override
  String confirmAndPay(String amount) {
    return 'Confirm and pay $amount';
  }

  @override
  String get confirmBooking => 'Confirm booking';

  @override
  String get paymentFailed =>
      'The payment did not go through. Please try again.';

  @override
  String get draftMissing =>
      'This step needs a booking in progress. Start again from Farm Services.';

  @override
  String get bookingConfirmed => 'Booking confirmed';

  @override
  String bookingConfirmedSubtitle(String date, String time) {
    return 'Your worker will arrive on $date at $time';
  }

  @override
  String get bookingId => 'Booking ID';

  @override
  String get status => 'Status';

  @override
  String get payment => 'Payment';

  @override
  String get viewMyBookings => 'View my bookings';

  @override
  String get backToHome => 'Back to home';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get noBookingsTitle => 'No bookings yet';

  @override
  String get noBookingsDescription =>
      'Book a farm or home service and it will show up here.';

  @override
  String get bookAService => 'Book a service';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get past => 'Past';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get messages => 'Messages';

  @override
  String get messagesSubtitle => 'Chat with the workers you have booked';

  @override
  String get noMessagesTitle => 'No conversations yet';

  @override
  String get noMessagesDescription =>
      'Once you book a worker, you can message them here.';

  @override
  String get noMessagesInThread => 'Say hello to start the conversation';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get typeMessage => 'Type a message';

  @override
  String get todaysMedicines => 'Today\'s medicines';

  @override
  String get medicinesSubtitle => 'Tap the circle after you take a dose';

  @override
  String pendingDoses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses pending',
      one: '1 dose pending',
      zero: 'All doses taken',
    );
    return '$_temp0';
  }

  @override
  String nextDose(String name, String time) {
    return 'Next: $name at $time';
  }

  @override
  String get addReminder => 'Add reminder';

  @override
  String get medicineName => 'Medicine name';

  @override
  String get medicineNameHint => 'e.g. BP tablet';

  @override
  String get dosage => 'Dosage';

  @override
  String get dosageHint => 'e.g. 1 tablet after breakfast';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get save => 'Save';

  @override
  String addedBy(String name) {
    return 'Added by $name';
  }

  @override
  String markedTaken(String name) {
    return '$name marked as taken';
  }

  @override
  String markedPending(String name) {
    return '$name marked as pending';
  }

  @override
  String get nameRequired => 'Please enter a name';

  @override
  String get phoneRequired => 'Please enter a phone number';

  @override
  String get noRemindersTitle => 'No reminders yet';

  @override
  String get noRemindersDescription =>
      'Add your medicines and Kaylo will remind you at the right time.';

  @override
  String get pressAndHold => 'Press and hold';

  @override
  String get holdSeconds => 'Hold for 3 seconds';

  @override
  String secondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String get sosHoldHint =>
      'Press and hold the button for 3 seconds. Your emergency contacts get your location right away.';

  @override
  String get sosReleasedEarly => 'Keep holding for 3 seconds to send an alert';

  @override
  String get sosSentTitle => 'Help is on the way';

  @override
  String sosSentContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts alerted with your location',
      one: '1 contact alerted with your location',
    );
    return '$_temp0';
  }

  @override
  String sosCallingPrimary(String name) {
    return 'Calling $name';
  }

  @override
  String get sosNoContacts =>
      'Add an emergency contact first, so someone receives the alert.';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get emergencyContacts => 'Emergency contacts';

  @override
  String get addContact => 'Add contact';

  @override
  String get contactName => 'Name';

  @override
  String get relationship => 'Relationship';

  @override
  String get relationshipHint => 'e.g. Daughter';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get primary => 'Primary';

  @override
  String get setAsPrimary => 'Set as primary';

  @override
  String get removeContact => 'Remove';

  @override
  String get sosHistory => 'SOS history';

  @override
  String alertsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alerts sent',
      one: '1 alert sent',
      zero: 'No alerts sent',
    );
    return '$_temp0';
  }

  @override
  String get noSosTitle => 'No alerts sent';

  @override
  String get noSosDescription =>
      'Alerts you send will be listed here with who was notified.';

  @override
  String alertedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts notified',
      one: '1 contact notified',
    );
    return '$_temp0';
  }

  @override
  String get sosStatusOpen => 'Open';

  @override
  String get sosStatusAcknowledged => 'Acknowledged';

  @override
  String get sosStatusResolved => 'Resolved';

  @override
  String locationShared(String location) {
    return 'Location shared: $location';
  }

  @override
  String primaryContact(String name) {
    return 'Primary contact: $name';
  }
}
