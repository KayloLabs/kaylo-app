import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_user.dart';
import '../../../core/config/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FamilyRepository {
  Future<List<AppUser>> getMyParents();
  Future<void> addParent(String phone);
  Future<void> removeParent(String parentId);
}

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  if (useMockData) return MockFamilyRepository();
  return SupabaseFamilyRepository();
});

class MockFamilyRepository implements FamilyRepository {
  final List<AppUser> _parents = [
    AppUser(id: 'p1', firstName: 'Amma', lastName: '', phone: '+91 98470 00001'),
    AppUser(id: 'p2', firstName: 'Appa', lastName: '', phone: '+91 98470 00002'),
  ];

  @override
  Future<List<AppUser>> getMyParents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _parents;
  }

  @override
  Future<void> addParent(String phone) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _parents.add(AppUser(id: 'p3', firstName: 'New', lastName: 'Parent', phone: phone));
  }

  @override
  Future<void> removeParent(String parentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _parents.removeWhere((p) => p.id == parentId);
  }
}

class SupabaseFamilyRepository implements FamilyRepository {
  final _client = Supabase.instance.client;

  @override
  Future<List<AppUser>> getMyParents() async {
    final response = await _client.from('families').select('parent:parent_id(id, first_name, last_name, phone, profile_image_url)');
    return (response as List).map((row) {
      final parent = row['parent'];
      return AppUser(
        id: parent['id'] as String,
        firstName: parent['first_name'] as String,
        lastName: parent['last_name'] as String? ?? '',
        phone: parent['phone'] as String,
        profileImageUrl: parent['profile_image_url'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> addParent(String phone) async {
    // Look up person by phone, then link them
    final person = await _client.from('persons').select('id').eq('phone', phone).maybeSingle();
    if (person == null) throw Exception('No Kaylo user found with this phone number');
    
    await _client.from('families').insert({
      'parent_id': person['id'],
      'member_id': _client.auth.currentUser!.id,
    });
  }

  @override
  Future<void> removeParent(String parentId) async {
    await _client.from('families').delete().match({
      'parent_id': parentId,
      'member_id': _client.auth.currentUser!.id,
    });
  }
}
