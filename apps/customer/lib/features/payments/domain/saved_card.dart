/// A card as the customer typed it, and how it reads once saved. The brand
/// follows the first digit the way the networks assign them (4 Visa,
/// 5 Mastercard, 6 RuPay). A saved row keeps only the brand, the holder and
/// the last four digits, never the full number.
enum CardBrand {
  visa('Visa Card'),
  mastercard('Mastercard'),
  rupay('RuPay Card'),
  other('Debit / Credit Card');

  final String label;
  const CardBrand(this.label);

  static CardBrand of(String digits) =>
      switch (digits.isEmpty ? '' : digits[0]) {
        '4' => visa,
        '5' => mastercard,
        '6' => rupay,
        _ => other,
      };
}

class SavedCard {
  final String digits;
  final String holder;
  final String expiry;

  SavedCard({required String number, String holder = '', String expiry = ''})
    : digits = number.replaceAll(RegExp(r'\s+'), ''),
      holder = holder.trim(),
      expiry = expiry.trim();

  bool get hasValidLength => digits.length >= 15 && digits.length <= 19;
  CardBrand get brand => CardBrand.of(digits);
  String get last4 =>
      digits.length >= 4 ? digits.substring(digits.length - 4) : digits;

  /// "Visa Card • Anjali Menon", or just the brand without a holder.
  String get label => holder.isEmpty ? brand.label : '${brand.label} • $holder';

  /// "•••• 4242  (12/27)"
  String get detail => '•••• $last4${expiry.isNotEmpty ? '  ($expiry)' : ''}';
}
