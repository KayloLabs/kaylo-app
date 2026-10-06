import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/payment_method.dart';
import '../domain/payment_methods_repository.dart';

class MockPaymentMethodsRepository implements PaymentMethodsRepository {
  final SharedPreferences? _prefs;
  final _controller = StreamController<List<SavedPaymentMethod>>.broadcast();

  static const _storageKey = 'kaylo_saved_payment_methods';

  static const List<SavedPaymentMethod> _defaultSeed = [
    SavedPaymentMethod(
      id: 'pm-seed-upi',
      type: PaymentMethodType.upi,
      label: 'Google Pay UPI',
      detail: 'anjali@okhdfcbank',
      isDefault: true,
    ),
    SavedPaymentMethod(
      id: 'pm-seed-card',
      type: PaymentMethodType.card,
      label: 'HDFC Bank Debit Card',
      detail: '•••• 4242',
      isDefault: false,
    ),
  ];

  List<SavedPaymentMethod>? _cache;

  MockPaymentMethodsRepository([this._prefs]);

  Future<List<SavedPaymentMethod>> _ensureLoaded() async {
    if (_cache != null) return _cache!;
    final raw = _prefs?.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = List<SavedPaymentMethod>.from(_defaultSeed);
      await _persist();
    } else {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _cache = decoded
            .map((e) => SavedPaymentMethod.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cache = List<SavedPaymentMethod>.from(_defaultSeed);
      }
    }
    return _cache!;
  }

  Future<void> _persist() async {
    if (_cache == null) return;
    final encoded = jsonEncode(_cache!.map((m) => m.toJson()).toList());
    await _prefs?.setString(_storageKey, encoded);
    _controller.add(List.unmodifiable(_cache!));
  }

  @override
  Future<List<SavedPaymentMethod>> getPaymentMethods() async {
    final list = await _ensureLoaded();
    return List.unmodifiable(list);
  }

  @override
  Stream<List<SavedPaymentMethod>> watchPaymentMethods() async* {
    final initial = await _ensureLoaded();
    yield List.unmodifiable(initial);
    yield* _controller.stream;
  }

  @override
  Future<SavedPaymentMethod> addPaymentMethod({
    required PaymentMethodType type,
    required String label,
    required String detail,
    bool isDefault = false,
  }) async {
    final list = await _ensureLoaded();
    final shouldBeDefault = isDefault || list.isEmpty;

    final updated = <SavedPaymentMethod>[];
    for (final item in list) {
      updated.add(shouldBeDefault ? item.copyWith(isDefault: false) : item);
    }

    final newMethod = SavedPaymentMethod(
      id: 'pm-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      label: label,
      detail: detail,
      isDefault: shouldBeDefault,
    );
    updated.add(newMethod);
    _cache = updated;
    await _persist();
    return newMethod;
  }

  @override
  Future<void> removePaymentMethod(String id) async {
    final list = await _ensureLoaded();
    final updated = list.where((m) => m.id != id).toList();
    if (updated.isNotEmpty && !updated.any((m) => m.isDefault)) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }
    _cache = updated;
    await _persist();
  }

  @override
  Future<void> setDefaultPaymentMethod(String id) async {
    final list = await _ensureLoaded();
    final updated = list.map((m) {
      return m.copyWith(isDefault: m.id == id);
    }).toList();
    _cache = updated;
    await _persist();
  }

  void dispose() {
    _controller.close();
  }
}
