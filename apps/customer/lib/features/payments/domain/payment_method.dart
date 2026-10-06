import 'package:flutter/foundation.dart';

enum PaymentMethodType {
  upi,
  card;

  bool get isUpi => this == PaymentMethodType.upi;
  bool get isCard => this == PaymentMethodType.card;
}

@immutable
class SavedPaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String label;
  final String detail;
  final bool isDefault;

  const SavedPaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.detail,
    this.isDefault = false,
  });

  SavedPaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? label,
    String? detail,
    bool? isDefault,
  }) {
    return SavedPaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      detail: detail ?? this.detail,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'detail': detail,
        'isDefault': isDefault,
      };

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'] as String,
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentMethodType.upi,
      ),
      label: json['label'] as String,
      detail: json['detail'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedPaymentMethod &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          label == other.label &&
          detail == other.detail &&
          isDefault == other.isDefault;

  @override
  int get hashCode => Object.hash(id, type, label, detail, isDefault);
}
