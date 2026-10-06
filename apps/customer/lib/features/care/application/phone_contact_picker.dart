import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PhoneContactPicker {
  static const _channel = MethodChannel('kaylo/phone_contacts');
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<Map<String, String>?> pick() async {
    final contact = await _channel.invokeMapMethod<String, String>('pick');
    return contact;
  }
}
