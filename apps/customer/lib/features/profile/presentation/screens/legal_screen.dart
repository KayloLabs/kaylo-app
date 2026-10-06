import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  final bool privacy;
  const LegalScreen({super.key, this.privacy = false});

  static const terms = <(String, String)>[
    (
      'Using Kaylo',
      'Kaylo connects customers with local service providers. Use accurate account and booking details, keep your sign-in codes private, and use the service lawfully and respectfully. A parent or guardian must supervise use by a minor.',
    ),
    (
      'Bookings and payment',
      'Review the provider, date, service and price before paying. Online bookings are confirmed only after payment verification. Payments are processed by Razorpay. Availability may change; contact support if a paid appointment cannot be fulfilled. Never share your card PIN, CVV or bank OTP with a service provider.',
    ),
    (
      'Cancellations and concerns',
      'Use your booking details to request cancellation and contact kayloapp@gmail.com for refunds, disputes or service concerns. Refund eligibility depends on the booking status and service already delivered. Kaylo will communicate the outcome and any applicable charges before resolving a request.',
    ),
    (
      'Care and prescriptions',
      'Care tools help organise appointments and personal records. Scanned text can contain mistakes, especially handwriting. Compare it with the original prescription and confirm medicines and doses with a qualified clinician. Kaylo does not diagnose conditions or prescribe treatment.',
    ),
    (
      'Emergency assistance',
      'SOS depends on internet access, device permissions and your contacts being available. An invitation does not mean someone has answered. Kaylo is not an emergency dispatch service. For immediate emergency assistance in India, call 112.',
    ),
    (
      'Your content and account',
      'Only upload records you own or are authorised to manage. You retain ownership of your content. Do not harass others, impersonate a provider or submit misleading information. You may delete your account in Settings. Contact support first for unresolved bookings or payments.',
    ),
    (
      'Contact and updates',
      'For help, disputes or questions about these terms, contact kayloapp@gmail.com. Changes will be reflected on this page. These terms do not remove rights provided by applicable law.',
    ),
  ];
  static const policy = <(String, String)>[
    (
      'Information we use',
      'Kaylo uses your name, contact details, sign-in identity, addresses, bookings, messages and payment references to operate your account and services. Care information may include emergency contacts, reminders and appointments that you choose to add.',
    ),
    (
      'Prescriptions',
      'Prescription PDFs and extracted text are stored privately on this device. Scanning and text recognition run on the device. They are not automatically sent to doctors or contacts. When you choose Share, the selected document is provided to the app or recipient you select. Deleting the app or its data can remove these local records.',
    ),
    (
      'Permissions and SOS',
      'Location is used when you choose a location feature. The microphone is used when you join a voice call. SOS shares an alert and call invitation with the trusted contacts you select. We do not record call audio. You can change permissions in your device settings.',
    ),
    (
      'Service providers',
      'Firebase supports sign-in, device notifications, diagnostics and analytics. Supabase stores account and service data. Razorpay processes payments and any saved-card tokenisation; Kaylo does not store your full card number, CVV or PIN. Relevant booking and contact information is shared with the service provider fulfilling your booking.',
    ),
    (
      'Storage and protection',
      'Access controls protect account data. Third-party infrastructure may process information outside your region. No system can guarantee absolute security. Keep your device protected and share prescriptions only with people you trust.',
    ),
    (
      'Your choices and deletion',
      'You can edit your profile and contacts, remove local prescriptions, and request account deletion from Settings. Deletion removes your Kaylo account and associated app records. Payment processors may retain their transaction records under their own policies and legal duties. Copies you previously shared with other people are outside Kaylo’s control.',
    ),
    (
      'Contact',
      'For access, correction, deletion or privacy concerns, write to kayloapp@gmail.com. Include enough information to identify your account, but never send passwords, OTPs or full payment-card details.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(privacy ? 'Privacy Policy' : 'Terms of Service'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Updated 2 October 2026',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        for (final section in privacy ? policy : terms) ...[
          Text(section.$1, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SelectableText(
            section.$2,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
        ],
      ],
    ),
  );
}
