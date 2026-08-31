import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/home/application/home_providers.dart';

void main() {
  test('voice search catalog includes non-popular services', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final catalog = await container.read(fullCatalogProvider.future);
    final names = catalog.map((s) => s.name).toList();

    // The regression that motivated this: matching used the popular
    // subset only, so care services could never be found by voice.
    expect(names, contains('Caregiver Visit'));
    expect(names, contains('Medicine Delivery'));
    expect(names, contains('House Cleaning'));
    expect(names, contains('Plumbing'));
    expect(names.toSet().length, names.length, reason: 'no duplicates');
  });
}
