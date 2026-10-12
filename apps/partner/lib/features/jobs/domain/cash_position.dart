import 'package:flutter/foundation.dart';

/// What a worker holds for Kaylo after cash jobs: the cash they collected and
/// the commission they owe. The backend keeps the ledger; the mock mirrors it.
@immutable
class CashPosition {
  final double cashInHand;
  final double dueToKaylo;
  final double dueLimit;
  final double commissionRate;

  const CashPosition({
    required this.cashInHand,
    required this.dueToKaylo,
    required this.dueLimit,
    required this.commissionRate,
  });

  /// Kaylo's standing terms until the backend reports otherwise.
  static const none = CashPosition(
    cashInHand: 0,
    dueToKaylo: 0,
    dueLimit: 2000,
    commissionRate: 0.15,
  );

  /// Cash requests cannot be accepted once the due reaches the limit.
  bool get canAcceptCash => dueToKaylo < dueLimit;

  factory CashPosition.fromJson(Map<String, dynamic> json) {
    double read(String key, double fallback) {
      final value = json[key];
      final parsed = switch (value) {
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
      if (parsed == null || !parsed.isFinite || parsed < 0) {
        if (value == null) return fallback;
        throw FormatException('Invalid cash position value for $key');
      }
      return parsed;
    }

    return CashPosition(
      cashInHand: read('cash_in_hand', 0),
      dueToKaylo: read('commission_due', 0),
      dueLimit: read('limit', none.dueLimit),
      commissionRate: read('rate', none.commissionRate),
    );
  }

  Map<String, dynamic> toJson() => {
    'cash_in_hand': cashInHand,
    'commission_due': dueToKaylo,
    'limit': dueLimit,
    'rate': commissionRate,
  };

  CashPosition copyWith({double? cashInHand, double? dueToKaylo}) =>
      CashPosition(
        cashInHand: cashInHand ?? this.cashInHand,
        dueToKaylo: dueToKaylo ?? this.dueToKaylo,
        dueLimit: dueLimit,
        commissionRate: commissionRate,
      );

  @override
  bool operator ==(Object other) =>
      other is CashPosition &&
      other.cashInHand == cashInHand &&
      other.dueToKaylo == dueToKaylo &&
      other.dueLimit == dueLimit &&
      other.commissionRate == commissionRate;

  @override
  int get hashCode =>
      Object.hash(cashInHand, dueToKaylo, dueLimit, commissionRate);
}
