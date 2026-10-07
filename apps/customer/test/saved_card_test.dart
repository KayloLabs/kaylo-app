import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/payments/domain/saved_card.dart';

void main() {
  test('brand follows the first digit and the number is masked', () {
    final visa = SavedCard(
      number: '4242 4242 4242 4242',
      holder: ' Anjali Menon ',
      expiry: '12/27',
    );
    expect(visa.brand, CardBrand.visa);
    expect(visa.label, 'Visa Card • Anjali Menon');
    expect(visa.detail, '•••• 4242  (12/27)');
    expect(visa.hasValidLength, isTrue);

    expect(SavedCard(number: '5555555555554444').brand, CardBrand.mastercard);
    expect(SavedCard(number: '6073849700004947').brand, CardBrand.rupay);
    expect(SavedCard(number: '3782822463100051').label, 'Debit / Credit Card');
    expect(SavedCard(number: '4242').hasValidLength, isFalse);
    expect(SavedCard(number: '4242').detail, '•••• 4242');
  });
}
