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
  String get languageSettings => 'Language Settings';

  @override
  String get profileLanguageTile => 'Language';

  @override
  String get appSettingsHeader => 'App Settings';

  @override
  String get profileTitle => 'Partner profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get verifiedPartner => 'Verified partner';

  @override
  String get verificationUnderReview => 'Verification in progress';

  @override
  String get verificationRejected => 'Verification rejected';

  @override
  String get verificationNotStarted => 'Not verified yet';

  @override
  String get performanceHeader => 'Performance & ratings';

  @override
  String get totalJobs => 'Total jobs';

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String memberSince(String date) {
    return 'Since $date';
  }

  @override
  String get offeredServicesHeader => 'Services you offer';

  @override
  String get noServicesYet => 'No services listed yet';

  @override
  String get payoutHeader => 'Payout account';

  @override
  String upiLabel(String upi) {
    return 'UPI ID: $upi';
  }

  @override
  String get noPayoutYet => 'No payout account yet';

  @override
  String get bankChangeNote => 'Bank account changes go through support';

  @override
  String get verificationHeader => 'KYC & verification';

  @override
  String get documentAadhaar => 'Aadhaar card';

  @override
  String get documentPoliceCertificate => 'Police clearance certificate';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusNotSubmitted => 'Not submitted';

  @override
  String get areaScheduleHeader => 'Service area & schedule';

  @override
  String travelRadius(String km) {
    return '$km km radius';
  }

  @override
  String get noDistrictYet => 'Service area not set';

  @override
  String get hoursNotSet => 'Working hours not set';

  @override
  String get customHours => 'Different hours on different days';

  @override
  String get manageAvailability => 'Manage availability';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutTitle => 'Log out?';

  @override
  String get logOutBody =>
      'You will need your partner ID and password to sign in again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get notRegisteredTitle => 'Finish your registration';

  @override
  String get notRegisteredBody =>
      'Your worker profile is not set up yet. Complete registration to start receiving jobs.';

  @override
  String get profileLoadFailed => 'Could not load your profile';

  @override
  String get retry => 'Retry';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get districtLabel => 'District';

  @override
  String get travelRadiusLabel => 'Travel radius (km)';

  @override
  String get upiIdLabel => 'UPI ID';

  @override
  String get servicesLabel => 'Services you offer';

  @override
  String get save => 'Save';

  @override
  String get profileSaved => 'Profile updated';

  @override
  String get nameRequired => 'Enter your name';

  @override
  String get chooseOneService => 'Choose at least one service';

  @override
  String get invalidUpi => 'Enter a valid UPI ID, like name@bank';

  @override
  String get radiusRange => 'Enter a radius between 1 and 100 km';

  @override
  String get dutyUpdateFailed => 'Could not update your availability';

  @override
  String get dutyTakingOrdersAnywhere => 'Taking job requests';

  @override
  String get availabilityTitle => 'My availability';

  @override
  String get workingHoursHeader => 'Working hours';

  @override
  String get workingHoursHint =>
      'Customers can only book you inside these hours.';

  @override
  String get dayOff => 'Day off';

  @override
  String get saveHours => 'Save hours';

  @override
  String get hoursSaved => 'Working hours saved';

  @override
  String get endAfterStart => 'The end time must be after the start';

  @override
  String get daysOffHeader => 'Days off';

  @override
  String get daysOffHint => 'Customers cannot book these days.';

  @override
  String get addDaysOff => 'Add days off';

  @override
  String get noDaysOff => 'No days off planned';

  @override
  String get reasonLabel => 'Reason (optional)';

  @override
  String get reasonHint => 'Festival, travel, family…';

  @override
  String get timeOffAdded => 'Days off added';

  @override
  String get timeOffRemoved => 'Days off removed';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String dateRange(String from, String to) {
    return '$from to $to';
  }

  @override
  String get authSubtitle => 'Sign in with the partner ID issued by Kaylo.';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authPartnerId => 'Partner ID';

  @override
  String get authPassword => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authForgotPassword => 'Forgot password? Contact Kaylo';

  @override
  String get authSupport => 'Contact Kaylo support';

  @override
  String get authApply => 'Apply as a partner';

  @override
  String get authCheckStatus => 'Check application status';

  @override
  String get authDemoCredentials => 'Demo: KP-000123 / kaylo123';

  @override
  String get authInvalidId => 'Enter a valid partner ID, like KP-000123.';

  @override
  String get authInvalidCredentials =>
      'The partner ID or password is incorrect.';

  @override
  String get authTooManyAttempts =>
      'Too many attempts. Please wait and try again.';

  @override
  String get authNetworkError =>
      'Check your internet connection and try again.';

  @override
  String get authUnavailableTitle => 'Unable to verify your account';

  @override
  String get authUnavailable =>
      'We could not verify your partner access. Try again or contact Kaylo support.';

  @override
  String get authPasswordRule =>
      'Use at least 12 characters for your new password.';

  @override
  String get authDifferentPassword =>
      'Choose a password different from your temporary password.';

  @override
  String get authSessionExpired =>
      'Your session expired. Sign out and sign in again.';

  @override
  String get authPasswordConfirmation =>
      'Your password update needs confirmation. Tap Save password again to retry securely.';

  @override
  String get authIdentityNotAllowed =>
      'Use the partner ID and password issued by Kaylo. Customer accounts cannot sign in here.';

  @override
  String get authChangePassword => 'Set your password';

  @override
  String get authChangePasswordBody =>
      'Replace your temporary password before opening your partner account.';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authConfirmPassword => 'Confirm new password';

  @override
  String get authSavePassword => 'Save password';

  @override
  String get authPasswordMismatch => 'The passwords do not match.';

  @override
  String get authNotIssuedBody =>
      'This account has no issued worker profile. Apply to Kaylo or contact support about your application.';

  @override
  String get authVerificationBody =>
      'Jobs are available after Kaylo approves your verification. You can view your profile or contact support.';

  @override
  String get partnerJobNotifications => 'Job requests';

  @override
  String get partnerNewJobRequest => 'New job request';

  @override
  String get partnerOpenJobRequest =>
      'Open Kaylo Partner to review the request.';

  @override
  String get applicationTitle => 'Apply to Kaylo';

  @override
  String get applicationPersonal => 'About you';

  @override
  String get applicationSkills => 'Your work & service area';

  @override
  String get applicationDocuments => 'Your documents';

  @override
  String get applicationPayout => 'Payout & consent';

  @override
  String applicationStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get applicationIntro =>
      'Apply without an account. Kaylo will review your details and documents before issuing a partner login.';

  @override
  String get applicationPhone => 'Phone number';

  @override
  String get applicationEmail => 'Delivery email';

  @override
  String get applicationEmailHint =>
      'Use an email you can access. Kaylo sends your partner ID and temporary password here after approval.';

  @override
  String get applicationInvalidPhone =>
      'Enter a valid phone number with country code';

  @override
  String get applicationInvalidEmail => 'Enter a valid delivery email';

  @override
  String get applicationProfession => 'Profession';

  @override
  String get applicationProfessionRequired => 'Enter your profession';

  @override
  String get applicationExperience => 'Experience (years)';

  @override
  String get applicationInvalidExperience =>
      'Enter experience from 0 to 60 years';

  @override
  String get applicationChooseDistrict => 'Choose your district';

  @override
  String get applicationNoServices =>
      'The service catalogue is not available yet. Please try again later.';

  @override
  String get applicationDocumentsHint =>
      'Add all five documents. Use JPG or PNG for photos; JPG, PNG or PDF for other documents. Maximum 10 MB per file.';

  @override
  String get applicationDocumentsPrivacy =>
      'Documents are uploaded privately for Kaylo’s application review. They are not shown in the public status lookup.';

  @override
  String get applicationPhoto => 'Profile photo';

  @override
  String get applicationAadhaarFront => 'Aadhaar front';

  @override
  String get applicationAadhaarBack => 'Aadhaar back';

  @override
  String get applicationSelfie => 'Selfie';

  @override
  String get applicationChooseFile => 'Choose a file';

  @override
  String get applicationAllDocuments => 'Add all five documents to continue';

  @override
  String get applicationUpi => 'UPI';

  @override
  String get applicationBank => 'Bank account';

  @override
  String get applicationAccountHolder => 'Account holder name';

  @override
  String get applicationBankName => 'Bank name';

  @override
  String get applicationAccountNumber => 'Account number';

  @override
  String get applicationConfirmAccount => 'Confirm account number';

  @override
  String get applicationIfsc => 'IFSC code';

  @override
  String get applicationBankRequired => 'Enter the bank details';

  @override
  String get applicationInvalidAccount =>
      'Enter a 9 to 18 digit account number';

  @override
  String get applicationAccountMismatch => 'The account numbers do not match';

  @override
  String get applicationInvalidIfsc => 'Enter a valid 11-character IFSC code';

  @override
  String get applicationReviewHint => 'Check your details before sending.';

  @override
  String get applicationConsent =>
      'I confirm these details are mine and accurate, and consent to Kaylo storing and reviewing my details and documents for partner verification.';

  @override
  String get applicationConsentRequired =>
      'Please give consent before submitting';

  @override
  String get applicationKeepOpen =>
      'Keep Kaylo open until all documents finish uploading. If your connection drops, retry here without creating another application.';

  @override
  String get applicationBack => 'Back';

  @override
  String get applicationContinue => 'Continue';

  @override
  String get applicationSubmit => 'Submit application';

  @override
  String get applicationSending => 'Finish sending your application';

  @override
  String get applicationRecoveryHint =>
      'Your application is only ready for review when all five documents are received. Retry continues the same application. If you close the app before finishing, contact Kaylo with your reference.';

  @override
  String get applicationReference => 'Application reference';

  @override
  String applicationUploadProgress(int count, int total) {
    return '$count of $total documents received';
  }

  @override
  String get applicationCheckStatus => 'Check application status';

  @override
  String get applicationBackToSignIn => 'Back to sign in';

  @override
  String get applicationStatusHint =>
      'Enter your application reference to see its status. Personal details and documents are never displayed here.';

  @override
  String get applicationInvalidReference =>
      'Enter the reference from your application';

  @override
  String get applicationUnderReview => 'Application under review';

  @override
  String get applicationUnderReviewHint =>
      'Your details and all five documents have been received. Kaylo will review them before deciding on your application. This reference is not a partner login.';

  @override
  String get applicationIncomplete => 'Documents still needed';

  @override
  String get applicationIncompleteHint =>
      'Your details were received, but document upload is not complete. Resume from this app session or contact Kaylo with your reference for help.';

  @override
  String get applicationApproved => 'Application approved';

  @override
  String get applicationApprovedHint =>
      'Kaylo sends your partner ID and temporary password to your delivery email after approval. If you have not received them, contact support. Your first sign-in requires a new password.';

  @override
  String get applicationRejected => 'Application not approved';

  @override
  String get applicationRejectedHint =>
      'Kaylo has not approved this application. No partner login is available for it. Contact support with your reference for further help.';

  @override
  String get applicationCopyReference => 'Copy reference';

  @override
  String get applicationReferenceCopied => 'Reference copied';

  @override
  String get applicationResumeUpload => 'Resume document upload';

  @override
  String get applicationContactSupport => 'Contact Kaylo support';

  @override
  String applicationSupportSubject(String reference) {
    return 'Partner application help: $reference';
  }

  @override
  String get applicationSupportHint =>
      'Email kayloapp@gmail.com with your application reference.';

  @override
  String get applicationDemoNotice =>
      'Sample mode: this application stays in this app session and is not sent to Kaylo.';

  @override
  String get applicationConnectionError =>
      'Could not connect. Check your connection and retry.';

  @override
  String get applicationAlreadyOpen =>
      'There is already an open application for this phone number. Check its status or contact Kaylo support.';

  @override
  String get applicationInvalidDetails =>
      'Please check your application details.';

  @override
  String get applicationInvalidDocument =>
      'Choose a valid JPG, PNG or PDF file, up to 10 MB. Profile photos and selfies must be images.';

  @override
  String get applicationUploadExpired =>
      'The upload session is no longer available. Contact Kaylo with your reference to finish your application.';

  @override
  String get applicationNotFound =>
      'No application matches that reference. Check the reference and try again.';

  @override
  String get applicationUnavailable =>
      'Applications are unavailable right now. Please try again later or contact Kaylo support.';

  @override
  String get applicationIdentityInUse =>
      'This phone or email is already used by a Kaylo account. Contact support before applying with this identity.';

  @override
  String get liveJobsPending =>
      'Live job requests and earnings are not available yet. Your profile and availability are ready to use.';
}
