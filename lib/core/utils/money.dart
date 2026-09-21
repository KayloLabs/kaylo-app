/// Rupee amounts with Indian digit grouping ("₹1,00,000"), dropping the
/// paise when the amount is whole. Kept independent of intl locale data
/// so it renders identically in every supported language.
String formatRupees(double amount) {
  return '${amount < 0 ? '-' : ''}₹${formatIndianNumber(amount.abs())}';
}

/// The digits only ("1,00,000" or "1,250.50"), for widgets that draw
/// their own currency symbol.
String formatIndianNumber(double amount) {
  final whole = amount.truncateToDouble() == amount;
  final fixed = amount.abs().toStringAsFixed(whole ? 0 : 2);
  final parts = fixed.split('.');
  final digits = parts[0];

  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final lastThree = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    grouped = '${groups.join(',')},$lastThree';
  }

  final fraction = parts.length > 1 ? '.${parts[1]}' : '';
  return '$grouped$fraction';
}
