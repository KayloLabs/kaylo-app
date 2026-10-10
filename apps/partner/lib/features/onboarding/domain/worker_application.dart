import 'dart:typed_data';

import '../../profile/domain/worker_profile.dart';

enum ApplicationDocumentType {
  photo('photo'),
  aadhaarFront('aadhaar_front'),
  aadhaarBack('aadhaar_back'),
  policeCertificate('police_certificate'),
  selfie('selfie');

  const ApplicationDocumentType(this.value);
  final String value;
}

enum ApplicationFailureCode {
  connection,
  alreadyOpen,
  identityInUse,
  invalidDetails,
  invalidDocument,
  expiredUpload,
  notFound,
  unavailable,
}

class WorkerApplicationFailure implements Exception {
  const WorkerApplicationFailure(this.code);
  final ApplicationFailureCode code;
}

/// Sensitive fields and bytes live in memory only. Never serialize the draft to
/// device preferences, crash logs, or an analytics event.
class ApplicationDocument {
  const ApplicationDocument({required this.name, required this.bytes});
  static const maxBytes = 10 * 1024 * 1024;
  final String name;
  final Uint8List bytes;

  String? get extension {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'png';
    }
    if (bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-') {
      return 'pdf';
    }
    return null;
  }

  String? get mimeType => switch (extension) {
    'jpg' => 'image/jpeg',
    'png' => 'image/png',
    'pdf' => 'application/pdf',
    _ => null,
  };

  bool get isValid =>
      bytes.isNotEmpty && bytes.length <= maxBytes && extension != null;
}

class ApplicationDetails {
  const ApplicationDetails({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.profession,
    required this.services,
    required this.experienceYears,
    required this.district,
    required this.travelRadiusKm,
    this.upiId,
    this.bankAccount,
    required this.consent,
  });

  final String fullName;
  final String phone;
  final String email;
  final String profession;
  final List<String> services;
  final int experienceYears;
  final String district;
  final int travelRadiusKm;
  final String? upiId;
  final ApplicationBankAccount? bankAccount;
  final bool consent;

  static String normalizePhone(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[\s()-]'), '');
    if (RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleaned)) return '+91$cleaned';
    return cleaned;
  }

  static bool validPhone(String value) =>
      RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(normalizePhone(value));
  static bool validEmail(String value) =>
      value.trim().length <= 254 &&
      !value.trim().toLowerCase().endsWith('@partners.kaylo.app') &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  bool get isValid =>
      fullName.trim().length >= 2 &&
      fullName.trim().length <= 120 &&
      validPhone(phone) &&
      validEmail(email) &&
      profession.trim().length >= 2 &&
      profession.trim().length <= 120 &&
      services.isNotEmpty &&
      services.length <= 30 &&
      experienceYears >= 0 &&
      experienceYears <= 60 &&
      keralaDistricts.contains(district) &&
      travelRadiusKm >= 1 &&
      travelRadiusKm <= 100 &&
      ((upiId != null && upiIdPattern.hasMatch(upiId!.trim())) ||
          (bankAccount?.isValid ?? false)) &&
      consent;

  Map<String, dynamic> toJson() => {
    'full_name': fullName.trim(),
    'phone': normalizePhone(phone),
    'email': email.trim().toLowerCase(),
    'profession': profession.trim(),
    'services': services.toSet().toList(),
    'experience_years': experienceYears,
    'district': district,
    'travel_radius_km': travelRadiusKm,
    if (upiId != null) 'upi_id': upiId!.trim(),
    if (bankAccount != null) 'bank_account': bankAccount!.toJson(),
    'consent': consent,
  };
}

class ApplicationBankAccount {
  const ApplicationBankAccount({
    required this.holder,
    required this.bankName,
    required this.accountNumber,
    required this.ifsc,
  });
  final String holder;
  final String bankName;
  final String accountNumber;
  final String ifsc;

  bool get isValid =>
      holder.trim().length >= 2 &&
      bankName.trim().length >= 2 &&
      RegExp(r'^[0-9]{9,18}$').hasMatch(accountNumber.trim()) &&
      RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc.trim().toUpperCase());

  Map<String, String> toJson() => {
    'account_holder': holder.trim(),
    'bank_name': bankName.trim(),
    'account_number': accountNumber.trim(),
    'ifsc': ifsc.trim().toUpperCase(),
  };
}

class ApplicationReceipt {
  const ApplicationReceipt({
    required this.applicationId,
    required this.reference,
    required this.uploadToken,
    required this.uploadExpiresAt,
  });
  final String applicationId;
  final String reference;
  final String uploadToken;
  final DateTime uploadExpiresAt;

  factory ApplicationReceipt.fromJson(Map<String, dynamic> json) =>
      ApplicationReceipt(
        applicationId: json['application_id'] as String,
        reference: json['reference'] as String,
        uploadToken: json['upload_token'] as String,
        uploadExpiresAt: DateTime.parse(json['upload_expires_at'] as String),
      );
}

enum WorkerApplicationStage {
  submitted,
  underReview,
  changesRequested,
  approved,
  rejected,
}

class ApplicationStatus {
  const ApplicationStatus({
    required this.reference,
    required this.stage,
    required this.documentsReceived,
  });
  final String reference;
  final WorkerApplicationStage stage;
  final int documentsReceived;
  bool get documentsComplete =>
      documentsReceived >= ApplicationDocumentType.values.length;

  factory ApplicationStatus.fromJson(Map<String, dynamic> json) {
    final stage = switch (json['status']) {
      'submitted' => WorkerApplicationStage.submitted,
      'under_review' => WorkerApplicationStage.underReview,
      'changes_requested' => WorkerApplicationStage.changesRequested,
      'approved' => WorkerApplicationStage.approved,
      'rejected' => WorkerApplicationStage.rejected,
      _ => throw const WorkerApplicationFailure(
        ApplicationFailureCode.unavailable,
      ),
    };
    return ApplicationStatus(
      reference: json['reference'] as String,
      stage: stage,
      documentsReceived: (json['documents_received'] as num?)?.toInt() ?? 0,
    );
  }
}
