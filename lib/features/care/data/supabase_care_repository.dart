import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/app_failure.dart';
import '../../../core/network/supabase_providers.dart';
import '../domain/care_models.dart';
import '../domain/care_repository.dart';

/// Care data against `senior_profiles`, `medicine_reminders`,
/// `medicine_reminder_logs`, `emergency_contacts` and `sos_alerts`
/// (the last three from migration 0003). A customer gets one senior
/// profile, created on first use.
class SupabaseCareRepository implements CareRepository {
  final SupabaseClient _client;

  SupabaseCareRepository(this._client);

  Future<String> _seniorIdFor(String personId) async {
    final customer = await _client
        .from('customers')
        .select('customer_id')
        .eq('person_id', personId)
        .maybeSingle();
    if (customer == null) {
      throw ServerFailure('No customer profile for this account',
          code: 'no-customer');
    }
    final customerId = customer['customer_id'] as String;

    final existing = await _client
        .from('senior_profiles')
        .select('senior_id')
        .eq('customer_id', customerId)
        .limit(1)
        .maybeSingle();
    if (existing != null) return existing['senior_id'] as String;

    final person = await _client
        .from('persons')
        .select('full_name')
        .eq('person_id', personId)
        .single();
    final created = await _client
        .from('senior_profiles')
        .insert({'customer_id': customerId, 'name': person['full_name']})
        .select('senior_id')
        .single();
    return created['senior_id'] as String;
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<MedicineReminder>> getReminders(String userId) async {
    try {
      final seniorId = await _seniorIdFor(userId);
      final rows = await _client
          .from('medicine_reminders')
          .select(
              'reminder_id, medicine, dosage, remind_time, medicine_reminder_logs(taken_on)')
          .eq('senior_id', seniorId)
          .order('remind_time');
      final today = _today();
      return [
        for (final row in rows)
          MedicineReminder(
            id: row['reminder_id'] as String,
            name: row['medicine'] as String,
            dosage: (row['dosage'] as String?) ?? '',
            hour: int.parse((row['remind_time'] as String).substring(0, 2)),
            minute: int.parse((row['remind_time'] as String).substring(3, 5)),
            isTakenToday: (row['medicine_reminder_logs'] as List? ?? const [])
                .any((log) => log['taken_on'] == today),
          ),
      ];
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<MedicineReminder> addReminder(
    String userId, {
    required String name,
    required String dosage,
    required int hour,
    required int minute,
  }) async {
    try {
      final seniorId = await _seniorIdFor(userId);
      final row = await _client
          .from('medicine_reminders')
          .insert({
            'senior_id': seniorId,
            'medicine': name,
            'dosage': dosage,
            'frequency': 'daily',
            'remind_time':
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00',
          })
          .select('reminder_id')
          .single();
      return MedicineReminder(
        id: row['reminder_id'] as String,
        name: name,
        dosage: dosage,
        hour: hour,
        minute: minute,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> setReminderTaken(String reminderId, bool taken) async {
    try {
      if (taken) {
        await _client.from('medicine_reminder_logs').upsert(
          {'reminder_id': reminderId, 'taken_on': _today()},
          onConflict: 'reminder_id,taken_on',
        );
      } else {
        await _client
            .from('medicine_reminder_logs')
            .delete()
            .eq('reminder_id', reminderId)
            .eq('taken_on', _today());
      }
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<EmergencyContact>> getContacts(String userId) async {
    try {
      final seniorId = await _seniorIdFor(userId);
      final rows = await _client
          .from('emergency_contacts')
          .select()
          .eq('senior_id', seniorId)
          .order('is_primary', ascending: false)
          .order('created_at');
      return rows.map(_contactFromRow).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<EmergencyContact> addContact(
    String userId, {
    required String name,
    required String relation,
    required String phone,
  }) async {
    try {
      final seniorId = await _seniorIdFor(userId);
      final count = await _client
          .from('emergency_contacts')
          .count()
          .eq('senior_id', seniorId);
      final row = await _client
          .from('emergency_contacts')
          .insert({
            'senior_id': seniorId,
            'name': name,
            'relation': relation,
            'phone': phone,
            'is_primary': count == 0,
          })
          .select()
          .single();
      return _contactFromRow(row);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> setPrimaryContact(String userId, String contactId) async {
    try {
      final seniorId = await _seniorIdFor(userId);
      await _client
          .from('emergency_contacts')
          .update({'is_primary': false}).eq('senior_id', seniorId);
      await _client
          .from('emergency_contacts')
          .update({'is_primary': true}).eq('contact_id', contactId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> removeContact(String contactId) async {
    try {
      await _client.from('emergency_contacts').delete().eq('contact_id', contactId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<SosAlert>> getSosHistory(String userId) async {
    try {
      final seniorId = await _seniorIdFor(userId);
      final rows = await _client
          .from('sos_alerts')
          .select()
          .eq('senior_id', seniorId)
          .order('triggered_at', ascending: false);
      return rows.map(_alertFromRow).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<SosAlert> triggerSos(String userId, {String? location}) async {
    try {
      final seniorId = await _seniorIdFor(userId);
      final contacts = await getContacts(userId);
      final primary = contacts.where((c) => c.isPrimary).firstOrNull ??
          contacts.firstOrNull;
      final row = await _client
          .from('sos_alerts')
          .insert({
            'senior_id': seniorId,
            'status': 'open',
            'location': location,
            'notified_count': contacts.length,
          })
          .select()
          .single();
      return SosAlert(
        id: row['sos_id'] as String,
        triggeredAt: DateTime.parse(row['triggered_at'] as String).toLocal(),
        status: SosStatus.open,
        notifiedContacts: contacts.length,
        primaryContactName: primary?.name,
        location: location,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  EmergencyContact _contactFromRow(Map<String, dynamic> row) {
    return EmergencyContact(
      id: row['contact_id'] as String,
      name: row['name'] as String,
      relation: (row['relation'] as String?) ?? '',
      phone: row['phone'] as String,
      isPrimary: (row['is_primary'] as bool?) ?? false,
    );
  }

  SosAlert _alertFromRow(Map<String, dynamic> row) {
    return SosAlert(
      id: row['sos_id'] as String,
      triggeredAt: DateTime.parse(row['triggered_at'] as String).toLocal(),
      status: switch (row['status'] as String?) {
        'acknowledged' => SosStatus.acknowledged,
        'resolved' => SosStatus.resolved,
        _ => SosStatus.open,
      },
      notifiedContacts: (row['notified_count'] as int?) ?? 0,
      location: row['location'] as String?,
    );
  }
}
