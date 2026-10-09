// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String sosCallWaiting(String name) {
    return 'Next: $name. The call starts after 3 seconds in Kaylo.';
  }

  @override
  String sosCallProgress(int attempted, int total) {
    return '$attempted of $total calls attempted';
  }

  @override
  String get sosCallsFinished =>
      'Call sequence finished. An attempted call does not confirm someone answered.';

  @override
  String get sosCallsStopped =>
      'Remaining calls stopped. An ongoing call can be ended in your phone app.';

  @override
  String get sosStopCalls => 'Stop remaining calls';

  @override
  String get sosAndroidOnly => 'SIM calling is available on Android phones.';

  @override
  String careDosesTaken(int taken, int total) {
    return '$taken of $total doses taken';
  }

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
  String get editProfile => 'Edit profile';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get statCompleted => 'Completed';

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
  String get homeServices => 'Home Services';

  @override
  String get allHomeServices => 'All Home Services';

  @override
  String get exploreHomeServices =>
      'Explore verified home service professionals';

  @override
  String get serviceDetails => 'Service Details';

  @override
  String get professionalAtDoorstep => 'Professional services at your doorstep';

  @override
  String get popularSubServices => 'Popular Sub-services';

  @override
  String get selectSubServices => 'Select sub-services';

  @override
  String get startingFrom => 'Starts from';

  @override
  String get bookNow => 'Book now';

  @override
  String get bookService => 'Book Service';

  @override
  String get workersAvailable => 'workers available';

  @override
  String get availableWorkers => 'Available Workers';

  @override
  String get sortAndFilter => 'Sort & Filter';

  @override
  String get sortBy => 'Sort by';

  @override
  String get rating => 'Rating';

  @override
  String get priceLowToHigh => 'Price: Low to High';

  @override
  String get priceHighToLow => 'Price: High to Low';

  @override
  String get experience => 'Experience';

  @override
  String get distance => 'Distance';

  @override
  String get filter => 'Filter';

  @override
  String get priceRange => 'Price Range';

  @override
  String get availability => 'Availability';

  @override
  String get availableToday => 'Available Today';

  @override
  String get minRating => 'Minimum Rating';

  @override
  String get verifiedOnly => 'Verified Only';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get noWorkersFound => 'No workers found matching your criteria';

  @override
  String get workerProfile => 'Worker Profile';

  @override
  String get completedJobs => 'Completed Jobs';

  @override
  String get yearsExperience => 'Years Experience';

  @override
  String get trustScore => 'Trust Score';

  @override
  String get responseTime => 'Response Time';

  @override
  String get certifications => 'Certifications';

  @override
  String get reviews => 'Reviews';

  @override
  String get customerReviews => 'Customer Reviews';

  @override
  String get verifiedProfessional => 'Verified Professional';

  @override
  String get searchServicesOrWorkers => 'Search services or professionals…';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get clearAll => 'Clear All';

  @override
  String get services => 'Services';

  @override
  String get professionals => 'Professionals';

  @override
  String get noResultsFound => 'No results found for';

  @override
  String get tryDifferentSearch =>
      'Try searching for another service or professional';

  @override
  String get selectSpecialty => 'Select Specialty';

  @override
  String get availableDoctors => 'Available Doctors';

  @override
  String get consultationFee => 'Consultation Fee';

  @override
  String get selectDate => 'Date';

  @override
  String get selectTimeSlot => 'Time slot';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get consultationType => 'Consultation Type';

  @override
  String get homeVisit => 'Home Visit';

  @override
  String get teleconsult => 'Video Teleconsult';

  @override
  String get confirmAppointment => 'Confirm Appointment';

  @override
  String get upcomingAppointments => 'Upcoming Appointments';

  @override
  String get appointmentConfirmed => 'Appointment Confirmed!';

  @override
  String get appointmentDetails => 'Your appointment has been scheduled.';

  @override
  String get selectCaregiver => 'Select Caregiver';

  @override
  String get hours => 'Hours';

  @override
  String get selectHours => 'Select Hours';

  @override
  String get careType => 'Care Type';

  @override
  String get elderlyCare => 'Elderly Care';

  @override
  String get postOpCare => 'Post-operative Care';

  @override
  String get companionship => 'Companionship';

  @override
  String get mobilityAssistance => 'Mobility Assistance';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get caregiverBooked => 'Caregiver Booked!';

  @override
  String get caregiverBookingSuccess =>
      'Your caregiver request has been submitted.';

  @override
  String get nearYou => 'Near you';

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
  String get scheduleTitle => 'Schedule';

  @override
  String get change => 'Change';

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
  String get serviceAddress => 'Service address';

  @override
  String get serviceAddressRequired => 'Please enter the service address';

  @override
  String get worker => 'Worker';

  @override
  String get popularSearches => 'Popular searches';

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
  String get payAfter => 'Pay cash after the service';

  @override
  String get payAfterSubtitle =>
      'Hand the cash to the worker once the job is done';

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
      'Hold for 3 seconds to call your contacts through your SIM, primary contact first. After each call ends, return to Kaylo to continue. Normal SIM charges apply.';

  @override
  String get sosReleasedEarly => 'Keep holding for 3 seconds to start calling';

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

  @override
  String get unitOrder => 'order';

  @override
  String unitOrderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String get standardPartsQuoted => 'Spare parts quoted before fitting';

  @override
  String get standardCleanupAfter => 'Work area cleaned before leaving';

  @override
  String get standardBackgroundChecked => 'Background-checked caregiver';

  @override
  String get standardPrescriptionChecked =>
      'Prescription checked by a pharmacist';

  @override
  String get careServices => 'Care Services';

  @override
  String get allServices => 'All services';

  @override
  String get homeServicesTagline =>
      'Plumbers, electricians and cleaners who show up on time and clean up after.';

  @override
  String get careServicesTagline =>
      'Trained caregivers and doorstep medicines for the people you look after.';

  @override
  String get allServicesTagline =>
      'Everything Kaylo offers, across home, farm and care.';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get locating => 'Locating…';

  @override
  String get locationServicesOff => 'Turn on location services and try again.';

  @override
  String get locationDenied => 'Location permission was not granted.';

  @override
  String get locationDeniedForever =>
      'Location is blocked for Kaylo. Allow it in your device settings.';

  @override
  String get locationTimeout =>
      'Could not get a GPS fix. Move to open sky and try again.';

  @override
  String get locationUnavailable => 'Location is unavailable right now.';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotificationsTitle => 'You\'re all caught up';

  @override
  String get noNotificationsDescription =>
      'Booking updates, messages and reminders will show up here.';

  @override
  String get today => 'Today';

  @override
  String get earlier => 'Earlier';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'Yesterday',
    );
    return '$_temp0';
  }

  @override
  String get bookingDetails => 'Booking details';

  @override
  String get cancelBookingTitle => 'Cancel this booking?';

  @override
  String get cancelBookingMessage =>
      'The worker will be released. You can book again anytime.';

  @override
  String get keepBooking => 'Keep booking';

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get bookingCancelled => 'Booking cancelled';

  @override
  String get bookingCancelledBanner => 'This booking was cancelled.';

  @override
  String get stepRequested => 'Requested';

  @override
  String get stepConfirmed => 'Confirmed';

  @override
  String get stepInProgress => 'In progress';

  @override
  String get stepCompleted => 'Completed';

  @override
  String get assignedWorker => 'Your worker';

  @override
  String get noWorkerYet => 'A worker will be assigned before the visit.';

  @override
  String get messageWorker => 'Message';

  @override
  String get reschedule => 'Reschedule';

  @override
  String get bookingRescheduled => 'Booking rescheduled';

  @override
  String get filters => 'Filters';

  @override
  String get category => 'Category';

  @override
  String get applyFilters => 'Apply';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortPriceLowHigh => 'Price: low to high';

  @override
  String get sortPriceHighLow => 'Price: high to low';

  @override
  String get allCategories => 'All';

  @override
  String get noResultsTitle => 'No services match';

  @override
  String get noResultsDescription =>
      'Try another word, or describe the problem: \"tap is leaking\" works too.';

  @override
  String resultsFor(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results for \"$query\"',
      one: '1 result for \"$query\"',
    );
    return '$_temp0';
  }

  @override
  String get yourLocation => 'Your location';

  @override
  String get or => 'or';

  @override
  String get townOrCity => 'Town or city';

  @override
  String get townHint => 'e.g. Kannur';

  @override
  String get saveLocation => 'Save location';

  @override
  String get townRequired => 'Please enter a town or city';

  @override
  String locationUpdated(String label) {
    return 'Location set to $label';
  }

  @override
  String get enableLocation => 'Enable location';

  @override
  String get enableLocationSubtitle =>
      'Kaylo uses your location to show workers near you and to share it in an SOS alert.';

  @override
  String get locationWillAppear => 'Your location will appear here';

  @override
  String get locateAgain => 'Locate again';

  @override
  String get continueLabel => 'Continue';

  @override
  String get enterManually => 'Enter manually';

  @override
  String get notNow => 'Not now';

  @override
  String get noAddressesTitle => 'No saved addresses';

  @override
  String get noAddressesDescription =>
      'Save your home or farm once and pick it in a tap when booking.';

  @override
  String get addAddress => 'Add address';

  @override
  String get defaultLabel => 'Default';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get removeAddress => 'Remove';

  @override
  String get addressLabel => 'Label';

  @override
  String get labelHome => 'Home';

  @override
  String get labelFarm => 'Farm';

  @override
  String get labelWork => 'Work';

  @override
  String get labelOther => 'Other';

  @override
  String get labelOtherHint => 'e.g. Amma\'s house';

  @override
  String get addressLine => 'Address';

  @override
  String get addressSaved => 'Address saved';

  @override
  String get contactUs => 'Contact us';

  @override
  String get emailUs => 'Email us';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get reportProblemSubtitle => 'Tell us what went wrong';

  @override
  String get reportProblemTemplate =>
      'What happened:\nWhere in the app:\nPhone model:';

  @override
  String get faq => 'Frequently asked questions';

  @override
  String get faqBookQ => 'How do I book a service?';

  @override
  String get faqBookA =>
      'Pick a service from the home screen or search, choose a date, time slot and quantity, add the address, and confirm. You get a booking ID right away and can track it under Bookings.';

  @override
  String get faqPayQ => 'How do I pay?';

  @override
  String get faqPayA =>
      'UPI and cards are charged when you confirm. Choose \"Pay after service\" to pay the worker directly once the job is done.';

  @override
  String get faqCancelQ => 'Can I cancel or reschedule?';

  @override
  String get faqCancelA =>
      'Yes. Open the booking under Bookings and use Reschedule or Cancel. Both are free until the worker is on the way.';

  @override
  String get faqWorkersQ => 'How are workers verified?';

  @override
  String get faqWorkersA =>
      'Every worker\'s ID is checked before they are listed, and ratings come only from customers who completed a booking.';

  @override
  String get faqCareQ => 'What is Care Mode?';

  @override
  String get faqCareA =>
      'Care Mode turns the whole app into a large-text, high-contrast layout for seniors, with medicine reminders and one-hold SOS.';

  @override
  String get faqSosQ => 'How does SOS work?';

  @override
  String get faqSosA =>
      'Press and hold the SOS button for three seconds. Every emergency contact receives your location, and the primary contact is called.';

  @override
  String get helpFooter =>
      'Kaylo is built by a small team in Kerala. Every message is read.';

  @override
  String get couldNotOpenEmail => 'Could not open your email app.';

  @override
  String get rateTitle => 'How is Kaylo working for you?';

  @override
  String get rateSubtitle => 'Your rating tells the team where to focus next.';

  @override
  String get rateComment => 'Anything we should improve? (optional)';

  @override
  String get submitRating => 'Submit';

  @override
  String get pickAStar => 'Pick a star rating first';

  @override
  String youRated(int stars) {
    return 'You rated Kaylo $stars of 5';
  }

  @override
  String get confirmLocation => 'Confirm location';

  @override
  String get moveMapToPlacePin => 'Move the map to place the pin';

  @override
  String get findingAddress => 'Finding address…';

  @override
  String get selectedLocation => 'Selected location';

  @override
  String get mapUnavailable => 'Map preview unavailable';

  @override
  String get searchTownHint => 'Search a town or city';

  @override
  String workerAbout(String name, String place, int jobs) {
    return '$name is a Kaylo professional in $place with $jobs completed jobs.';
  }

  @override
  String get verificationPending => 'Verification in progress';

  @override
  String get certGovtId => 'Government ID verified';

  @override
  String get certGovtIdSub => 'Aadhaar or Voter ID checked';

  @override
  String get certPolice => 'Police clearance verified';

  @override
  String get certPoliceSub => 'Background check clear';

  @override
  String get certSkill => 'Kaylo skill certified';

  @override
  String get certSkillSub => 'Practical skills tested';

  @override
  String get hourlyRate => 'Hourly rate';

  @override
  String get perHour => 'per hour';

  @override
  String get priceOnVisit => 'Price shared on visit';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get newService => 'New';

  @override
  String get nearbyFirst => 'Nearby first';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String inDays(int count) {
    return 'In $count days';
  }

  @override
  String get whoIsItFor => 'Who is it for?';

  @override
  String get appointmentNotes => 'Notes for the doctor (optional)';

  @override
  String appointmentConfirmedWith(String doctor) {
    return 'Appointment booked with $doctor';
  }

  @override
  String get noUpcomingAppointments => 'No upcoming appointments yet';

  @override
  String get specGeneral => 'General physician';

  @override
  String get specCardio => 'Cardiologist';

  @override
  String get specOrtho => 'Orthopaedic';

  @override
  String get specGeriatric => 'Geriatrician';

  @override
  String get specAyurveda => 'Ayurveda';

  @override
  String get incPlumbTap => 'Tap repair';

  @override
  String get incPlumbPipe => 'Pipe leakage';

  @override
  String get incPlumbDrain => 'Drain cleaning';

  @override
  String get incPlumbInstall => 'Installation';

  @override
  String get incElecSwitch => 'Switchboard repair';

  @override
  String get incElecWiring => 'Wiring fix';

  @override
  String get incElecFan => 'Fan installation';

  @override
  String get incElecMcb => 'MCB tripping';

  @override
  String get incCleanDeep => 'Full home deep clean';

  @override
  String get incCleanKitchen => 'Kitchen cleaning';

  @override
  String get incCleanBath => 'Bathroom scrub';

  @override
  String get incCleanSofa => 'Sofa shampoo';

  @override
  String get incCarpFurniture => 'Furniture repair';

  @override
  String get incCarpDoor => 'Doors and windows';

  @override
  String get incCarpLock => 'Lock installation';

  @override
  String get incCarpCustom => 'Custom woodwork';

  @override
  String get incPaintInterior => 'Interior painting';

  @override
  String get incPaintExterior => 'Exterior painting';

  @override
  String get incPaintPutty => 'Wall putty and primer';

  @override
  String get incPaintWaterproof => 'Waterproofing';

  @override
  String get incAcFilter => 'Filter cleaning';

  @override
  String get incAcGas => 'Gas refill';

  @override
  String get incAcCooling => 'Cooling issue repair';

  @override
  String get incAcInstall => 'Installation and removal';

  @override
  String get incApplWasher => 'Washing machine';

  @override
  String get incApplFridge => 'Refrigerator';

  @override
  String get incApplMicrowave => 'Microwave';

  @override
  String get incApplTv => 'TV mounting and repair';

  @override
  String get incGenInspect => 'General inspection';

  @override
  String get incGenRepair => 'Repair and fix';

  @override
  String get incGenInstall => 'New installation';

  @override
  String get incGenMaintain => 'Maintenance';

  @override
  String get invoiceEmail => 'Email for the invoice';

  @override
  String get invoiceEmailRequired => 'Enter an email address for the invoice';

  @override
  String get confirmationEmail => 'Email for the confirmation (optional)';

  @override
  String get payNow => 'Pay now';

  @override
  String get payNowSubtitle => 'Cards, netbanking or UPI, secured by Razorpay';

  @override
  String get prescriptions => 'Prescriptions';

  @override
  String get prescriptionsSubtitle => 'Scan, read and keep your health records';

  @override
  String get trustedContacts => 'Trusted contacts';

  @override
  String get trustedContactsSubtitle =>
      'Connect family and doctors for SOS calls';

  @override
  String get sosStartFailedContacts =>
      'Could not start SOS. Check your connection and trusted contacts.';

  @override
  String get sosStartFailed => 'Could not start SOS. Please try again.';

  @override
  String get sosModeKaylo => 'Kaylo call';

  @override
  String get sosModeSim => 'SIM call';

  @override
  String get manageTrustedContacts => 'Manage trusted contacts';

  @override
  String get sosKayloHoldHint =>
      'Hold for 3 seconds to invite your trusted Kaylo contacts. They can join the call together. An invitation does not mean someone has answered.';

  @override
  String get contactsOpenFailed => 'Could not open phone contacts.';

  @override
  String get chooseFromPhoneContacts => 'Choose from phone contacts';

  @override
  String sosContactsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts were skipped: their numbers cannot be dialled.',
      one: '1 contact was skipped: its number cannot be dialled.',
    );
    return '$_temp0';
  }

  @override
  String get incomingSosTitle => 'Incoming Kaylo SOS';

  @override
  String get incomingSosSubtitle => 'A trusted contact needs help';

  @override
  String get decline => 'Decline';

  @override
  String get joinCall => 'Join call';

  @override
  String get signInLiveForContacts =>
      'Sign into the live app to connect trusted contacts.';

  @override
  String get couldNotConnectRetry => 'Could not connect. Please try again.';

  @override
  String get refreshConnections => 'Refresh connections';

  @override
  String get trustedCircleTitle => 'Bring your circle into Kaylo';

  @override
  String get trustedCircleBody =>
      'Invite up to five family members or doctors who use Kaylo. When they accept your code, they can receive your SOS alerts and join the same voice call.';

  @override
  String get getInviteCode => 'Get my invite code';

  @override
  String get inviteCodeCopied => 'Invite code copied';

  @override
  String get copyCode => 'Copy code';

  @override
  String get inviteCodeValidity =>
      'Valid for seven days. Share only with people you trust.';

  @override
  String get acceptInviteTitle => 'Accept someone’s invitation';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get acceptInvitation => 'Accept invitation';

  @override
  String get invitationAccepted =>
      'Invitation accepted. You are now connected and can receive their SOS alerts.';

  @override
  String get yourConnections => 'Your connections';

  @override
  String get noConnectionsYet => 'No connections yet';

  @override
  String get receivesYourSos => 'Receives your SOS alerts';

  @override
  String get youReceiveTheirSos => 'You receive their SOS alerts';

  @override
  String get removeConnection => 'Remove connection';

  @override
  String get removeConnectionTitle => 'Remove connection?';

  @override
  String get removeConnectionBody =>
      'This connection will no longer receive SOS call invitations.';

  @override
  String get contactsLoadFailedRetry => 'Could not load contacts. Retry';

  @override
  String get callTitle => 'Kaylo SOS call';

  @override
  String get callEnded => 'Call ended';

  @override
  String get callYourCircle => 'Your trusted circle';

  @override
  String get callCouldNotConnect => 'Could not connect';

  @override
  String get callConnecting => 'Connecting…';

  @override
  String get callKeepOpen => 'Keep Kaylo open during the call.';

  @override
  String get retryCall => 'Retry call';

  @override
  String get callErrorRoom =>
      'This call is unavailable or has ended. Return to SOS to start a new call.';

  @override
  String get callErrorSettings =>
      'Could not load call settings. Check your connection and retry.';

  @override
  String get callErrorMicrophone =>
      'Could not access the microphone. Check microphone access for Kaylo and retry.';

  @override
  String get callErrorJoin =>
      'Could not join this call. Retry, or ask the caller to start a new SOS call.';

  @override
  String get callInterrupted => 'Connection interrupted. Retrying…';

  @override
  String get callPeerConnected => 'Connected';

  @override
  String get callPeerFailed => 'Connection failed';

  @override
  String get callPeerReconnecting => 'Reconnecting';

  @override
  String get callPeerConnecting => 'Connecting';

  @override
  String get callYou => 'You';

  @override
  String get callYouMuted => 'You • Muted';

  @override
  String get callInvitedWaiting => 'Invited • Waiting to answer';

  @override
  String get callDeclined => 'Declined';

  @override
  String get callLeft => 'Left the call';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get speaker => 'Speaker';

  @override
  String get callAudioOutputFailed =>
      'Could not change audio output. The call is still active.';

  @override
  String get close => 'Close';

  @override
  String get callEndForEveryone => 'End call for everyone';

  @override
  String get callLeave => 'Leave call';

  @override
  String get prescriptionsLoadFailed =>
      'Could not load prescriptions. Please try again.';

  @override
  String get actionFailed => 'Could not complete that action.';

  @override
  String get prescriptionSaveFailed =>
      'Could not save the prescription. Please try again.';

  @override
  String get prescriptionsHeadline => 'Your health records, together';

  @override
  String get prescriptionsIntro =>
      'Scan a prescription or type a previous record. PDFs are saved privately on this device.';

  @override
  String get prescriptionsAndroidOnly =>
      'Prescription scanning and PDFs are currently available in the Android app.';

  @override
  String get scanOrPhotos => 'Scan / photos';

  @override
  String get typeRecord => 'Type record';

  @override
  String get searchPrescriptions => 'Search prescriptions';

  @override
  String get noPrescriptionsYet => 'No prescriptions yet';

  @override
  String get noMatchingPrescriptions => 'No matching prescriptions';

  @override
  String get prescriptionNeedsTitleText => 'Add a title and prescription text.';

  @override
  String get prescriptionRecord => 'Prescription record';

  @override
  String get reviewPrescription => 'Review prescription';

  @override
  String get deletePrescription => 'Delete prescription';

  @override
  String get deletePrescriptionTitle => 'Delete prescription?';

  @override
  String get deletePrescriptionBody =>
      'The PDF and text will be removed from this device.';

  @override
  String get delete => 'Delete';

  @override
  String get prescriptionReviewHint =>
      'Review the extracted text against the original. Handwriting may be incomplete or incorrect; confirm medicine names and doses with your doctor.';

  @override
  String get viewOriginalPdf => 'View original PDF';

  @override
  String get titleLabel => 'Title';

  @override
  String get extractedTextNotes => 'Extracted text / notes';

  @override
  String get prescriptionDetails => 'Prescription details';

  @override
  String get prescriptionEditHint =>
      'Editing this text keeps the original scanned PDF unchanged.';

  @override
  String get saving => 'Saving…';

  @override
  String get savePrescription => 'Save prescription';

  @override
  String get openSavedPdf => 'Open saved PDF';

  @override
  String get shareSavedPdf => 'Share saved PDF';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteRequiresLive =>
      'Account deletion requires a signed-in live account.';

  @override
  String get deleteNotConfirmed => 'Deletion was not confirmed. Please retry.';

  @override
  String get deleteFailed => 'Could not delete the account. Please try again.';

  @override
  String get deleteAccountHeadline => 'Permanently delete your Kaylo account?';

  @override
  String get deleteAccountBody =>
      'This removes your sign-in, profile, bookings, messages, care records and prescriptions stored on this device. It cannot be undone. Complete or cancel active bookings first. For unresolved payments, contact kayloapp@gmail.com.';

  @override
  String get deleteAccountNote =>
      'Payment processors may retain transaction records. Documents you previously shared are not removed from other people’s devices.';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm';

  @override
  String get deleting => 'Deleting…';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get paymentVerified => 'Payment verified. Your booking is confirmed.';

  @override
  String get paymentNotCompleted => 'Payment was not completed.';

  @override
  String get checkoutOpenFailed =>
      'Could not open secure checkout. Please try again.';

  @override
  String get cardsAndUpi => 'Cards and UPI';

  @override
  String get paymentMethodsBody =>
      'Enter a card manually or choose UPI in secure Razorpay checkout. Where supported, choose Razorpay’s save-card option to use that card again. Saved cards are managed inside checkout.';

  @override
  String get paymentMethodsNote =>
      'Kaylo does not store your full card number, CVV or PIN. NFC card enrolment is not supported by the current payment integration.';

  @override
  String get completePendingPayment => 'Complete a pending payment';

  @override
  String get noPendingPayments =>
      'Your next booking will open checkout, where you can add or select a card.';

  @override
  String pendingBookingLine(String id, String date) {
    return 'Booking $id • $date';
  }

  @override
  String get bookingsLoadFailedRetry => 'Could not load bookings. Retry';

  @override
  String get openingPayment => 'Opening payment…';

  @override
  String get payAndBook => 'Pay & book';

  @override
  String get appointmentPaymentFailed =>
      'Could not complete payment. Your appointment is not confirmed. Please try again.';

  @override
  String get visitPaymentFailed =>
      'Could not complete payment. Your visit is not confirmed. Please try again.';

  @override
  String get careServiceUnavailable => 'This care service is unavailable.';

  @override
  String get appointmentNotConfirmed =>
      'Payment was not completed. Your appointment is not confirmed.';

  @override
  String get hapticFeedback => 'Haptic feedback';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get voiceStarting => 'Starting microphone…';

  @override
  String get ocrNeedsReview =>
      'Some text could not be read. Check the original scan and correct the notes before using them.';

  @override
  String get allBookings => 'All bookings';

  @override
  String get noCompletedBookings => 'No completed bookings yet';

  @override
  String get noCompletedBookingsDescription =>
      'Your completed jobs will appear here once the work is done.';

  @override
  String get verificationRecord => 'Verification record';

  @override
  String get refreshVerification => 'Refresh verification status';

  @override
  String get verificationLoadError =>
      'Could not load the current verification status. Please try again.';

  @override
  String get kayloVerified => 'Verified on Kaylo';

  @override
  String get notYetVerified => 'Not yet verified';

  @override
  String get viewVerification => 'View verification record';

  @override
  String get verificationRecorded =>
      'This professional’s profile is marked as verified in Kaylo.';

  @override
  String get verificationNotRecorded =>
      'No verified status is recorded for this profile.';

  @override
  String get listedServices => 'Listed services';

  @override
  String get profileReference => 'Profile reference';

  @override
  String get serviceArea => 'Service area';

  @override
  String get verificationScope =>
      'This record reflects the profile’s current status. Supporting documents and check details are not available. It is not a government licence or a professional qualification.';

  @override
  String get selectOnMap => 'Choose on map';

  @override
  String get chooseAddress => 'Choose an address';

  @override
  String get offerFirst100Title => 'Your first one is special';

  @override
  String get offerFirst100Body =>
      '₹100 off your first booking of ₹499 or more.';

  @override
  String get offerKaylo150Title => 'A little help with bigger jobs';

  @override
  String get offerKaylo150Body =>
      '₹150 off a booking of ₹1,499 or more. Once per account.';

  @override
  String get offerWeekend100Title => 'A weekend well spent';

  @override
  String get offerWeekend100Body =>
      '₹100 off ₹999 or more on Saturdays and Sundays. Once per account.';

  @override
  String get offerWeekday50Title => 'A midweek lift';

  @override
  String get offerWeekday50Body =>
      '₹50 off ₹599 or more, Monday to Friday. Once per account.';

  @override
  String get offerHome80Title => 'Home, sorted';

  @override
  String get offerHome80Body =>
      '₹80 off a home service of ₹499 or more. Once per account.';

  @override
  String get offerFarm125Title => 'For the land that feeds us';

  @override
  String get offerFarm125Body =>
      '₹125 off a farm service of ₹999 or more. Once per account.';

  @override
  String get offerCare60Title => 'Care, made a little lighter';

  @override
  String get offerCare60Body =>
      '₹60 off a Care booking of ₹399 or more. Once per account.';

  @override
  String get offerKaylo300Title => 'For the really big days';

  @override
  String get offerKaylo300Body =>
      '₹300 off a booking of ₹2,999 or more. Once per account.';

  @override
  String get offerNext75Title => 'Something for next time';

  @override
  String get offerNext75Body =>
      '₹75 off your next booking of ₹799 or more. Unlocks after a confirmed booking.';

  @override
  String get offerThanks120Title => 'Three bookings in. Thank you.';

  @override
  String get offerThanks120Body =>
      '₹120 off a booking of ₹999 or more. Unlocks after three confirmed bookings.';

  @override
  String get offerReasonFirstOnly => 'For your first booking only';

  @override
  String get offerReasonUsed => 'Already used';

  @override
  String get offerReasonRewardUsed => 'Reward used';

  @override
  String get offerReasonWeekend => 'Available on weekends';

  @override
  String get offerReasonWeekday => 'Available Monday to Friday';

  @override
  String get offerReasonNeedsConfirmed =>
      'Unlocks after your first confirmed booking';

  @override
  String get offerReasonNeedsThree => 'Unlocks after three confirmed bookings';

  @override
  String get offerReasonHomeOnly => 'For home services only';

  @override
  String get offerReasonFarmOnly => 'For farm services only';

  @override
  String get offerReasonCareOnly => 'For Care bookings only';

  @override
  String offerReasonAddMore(String amount) {
    return 'Add $amount more to use this offer';
  }

  @override
  String get offerNotAvailable => 'Offer not available';

  @override
  String get offersTitle => 'A little more Kaylo';

  @override
  String get offersHeadline => 'Everyday help.\nA little extra happiness.';

  @override
  String get offersIntro =>
      'Thoughtful savings for the jobs that matter. One offer per booking.';

  @override
  String get offersLoadFailed => 'Your offers couldn’t load. Please try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get enterCouponCode => 'Enter coupon code';

  @override
  String get couponNotFound => 'That code isn’t available';

  @override
  String get offersTerms =>
      'Discounts reduce your booking total. They cannot be exchanged for cash or combined. Cancelled bookings release their offer. Eligibility is checked again at checkout.';

  @override
  String offerAmountOff(String amount) {
    return '$amount off';
  }

  @override
  String get applyOffer => 'Apply';

  @override
  String get removeOffer => 'Remove';

  @override
  String offerYouSave(String amount) {
    return 'You save $amount';
  }

  @override
  String get offersAndRewards => 'Offers & rewards';

  @override
  String offerCodeApplied(String code) {
    return '$code applied';
  }

  @override
  String get offerStampApplied => 'APPLIED';

  @override
  String offersReadyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offers ready to use',
      one: '1 offer ready to use',
    );
    return '$_temp0';
  }

  @override
  String get yourRewards => 'Your rewards';

  @override
  String get allOffers => 'All offers';

  @override
  String offerLabel(String code) {
    return 'Offer • $code';
  }

  @override
  String get scratchCoverTitle => 'A little thank you';

  @override
  String get scratchCoverHint => 'Scratch to reveal your reward';

  @override
  String get revealReward => 'Reveal reward';

  @override
  String scratchSemantics(String amount) {
    return 'Scratch reward. Reveal $amount off a booking.';
  }

  @override
  String get bannerWelcomeTitle => 'A warm welcome. ₹100 on us.';

  @override
  String get bannerWelcomeBody => 'Your first-booking offer is unlocked';

  @override
  String get bannerRewardsTitle => 'Good work. A little extra joy.';

  @override
  String get bannerRewardsBody => 'Explore your offers & scratch rewards';

  @override
  String get secretTagline => 'A little care goes a long way.';

  @override
  String get secretSemantics => 'Kaylo. Made with care.';

  @override
  String get addPaymentMethod => 'Add payment method';

  @override
  String get cardExpiry => 'Expiry (MM/YY)';

  @override
  String get cardHolderName => 'Name on card';

  @override
  String get cardNumber => 'Card number';

  @override
  String get defaultTag => 'Default';

  @override
  String get deletePaymentMethodConfirm =>
      'Remove this payment method? You can add it again any time.';

  @override
  String get noPaymentMethods => 'No saved payment methods';

  @override
  String get noPaymentMethodsSubtitle =>
      'Save a UPI ID or card to pay faster next time.';

  @override
  String get paymentMethodAdded => 'Payment method saved';

  @override
  String get paymentMethodRemoved => 'Payment method removed';

  @override
  String get removeMethod => 'Remove';

  @override
  String get savePaymentMethod => 'Save payment method';

  @override
  String get setDefault => 'Set as default';

  @override
  String get upiId => 'UPI ID';

  @override
  String payCashAmount(String amount) {
    return 'Pay the worker $amount in cash when the job is done';
  }

  @override
  String paidCashAmount(String amount) {
    return 'Paid $amount in cash';
  }

  @override
  String get workerOnTheWay => 'Your worker is on the way';

  @override
  String get workerArrived => 'Your worker has arrived';

  @override
  String get rateYourWorker => 'Rate your worker';

  @override
  String get rateWorkerHint =>
      'How did it go? A line or two helps other customers.';

  @override
  String get reviewTextHint => 'Say a little about the work (optional)';

  @override
  String get submitReview => 'Submit review';

  @override
  String get reviewSubmitted => 'Thanks, your review is in';

  @override
  String get yourReview => 'Your review';

  @override
  String get editReview => 'Edit';

  @override
  String get ratingRequired => 'Pick a star rating first';

  @override
  String starLabel(int count) {
    return '$count of 5 stars';
  }

  @override
  String get addOns => 'Add-ons';

  @override
  String addOnsIncluded(String list) {
    return 'Add-ons: $list';
  }
}
