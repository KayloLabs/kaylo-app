import 'package:kaylo_core/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where the person behind a sign-in is kept. Firebase (or Supabase
/// Auth) knows who signed in; this knows their Kaylo profile.
abstract class ProfileStore {
  Future<AppUser?> findByAuthId(String authUserId);

  /// Creates the person (and the customer row that bookings need) for a
  /// first sign-in; [draft.id] is ignored, the stored id comes back.
  Future<AppUser> create(AppUser draft, {required String authUserId});

  /// Saves name and photo changes; [user.id] is the person id.
  Future<AppUser> update(AppUser user);
}

/// What a sign-in provider tells us about the account.
class SignInIdentity {
  final String authUserId;
  final String? displayName;
  final String? email;
  final String? phone;
  final String? photoUrl;

  const SignInIdentity({
    required this.authUserId,
    this.displayName,
    this.email,
    this.phone,
    this.photoUrl,
  });
}

/// Name given to a profile when the sign-in carried none (a bare phone
/// number); replaced as soon as a provider or the customer supplies one.
const String placeholderName = 'Kaylo User';

/// Turns a sign-in into a profile: creates the row on first sign-in and
/// lets a later, richer sign-in (Google after phone) fill in the name
/// and photo the row is missing. Never overwrites a name the customer
/// chose themselves.
class ProfileSync {
  final ProfileStore store;

  const ProfileSync(this.store);

  Future<AppUser> resolve(SignInIdentity identity, {String? preferredName}) async {
    final providedName = _firstNonEmpty([preferredName, identity.displayName]);
    final existing = await store.findByAuthId(identity.authUserId);

    if (existing == null) {
      return store.create(
        AppUser.fromFullName(
          id: '',
          fullName: providedName ?? placeholderName,
          phone: identity.phone ?? '',
          email: identity.email,
          profileImageUrl: identity.photoUrl,
        ),
        authUserId: identity.authUserId,
      );
    }

    var updated = existing;
    final nameIsPlaceholder =
        existing.fullName.isEmpty || existing.fullName == placeholderName;
    if (nameIsPlaceholder && providedName != null) {
      final (first, last) = AppUser.splitName(providedName);
      updated = updated.copyWith(firstName: first, lastName: last);
    }
    if ((existing.profileImageUrl ?? '').isEmpty && identity.photoUrl != null) {
      updated = updated.copyWith(profileImageUrl: identity.photoUrl);
    }
    if ((existing.email ?? '').isEmpty && identity.email != null) {
      updated = updated.copyWith(email: identity.email);
    }
    if (existing.phone.isEmpty && (identity.phone ?? '').isNotEmpty) {
      updated = updated.copyWith(phone: identity.phone);
    }
    return updated == existing ? existing : store.update(updated);
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return null;
  }
}

/// persons + customers in Supabase. Column names follow
/// supabase/migrations/0001_initial_schema.sql.
class SupabaseProfileStore implements ProfileStore {
  final SupabaseClient _db;

  const SupabaseProfileStore(this._db);

  static const _columns =
      'person_id, full_name, phone_number, email, profile_photo';

  @override
  Future<AppUser?> findByAuthId(String authUserId) async {
    final row = await _db
        .from('persons')
        .select(_columns)
        .eq('auth_user_id', authUserId)
        .maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<AppUser> create(AppUser draft, {required String authUserId}) async {
    final row = await _db
        .from('persons')
        .insert({
          'auth_user_id': authUserId,
          'full_name': draft.fullName.isEmpty ? placeholderName : draft.fullName,
          'phone_number': draft.phone.isEmpty ? null : draft.phone,
          'email': draft.email,
          'profile_photo': draft.profileImageUrl,
        })
        .select(_columns)
        .single();
    final user = _fromRow(row);
    await _db.from('customers').insert({'person_id': user.id});
    return user;
  }

  @override
  Future<AppUser> update(AppUser user) async {
    final row = await _db
        .from('persons')
        .update({
          'full_name': user.fullName,
          'profile_photo': user.profileImageUrl,
          'email': user.email,
          'phone_number': user.phone.isEmpty ? null : user.phone,
        })
        .eq('person_id', user.id)
        .select(_columns)
        .single();
    return _fromRow(row);
  }

  AppUser _fromRow(Map<String, dynamic> row) => AppUser.fromFullName(
        id: row['person_id'] as String,
        fullName: (row['full_name'] as String?) ?? '',
        phone: (row['phone_number'] as String?) ?? '',
        email: row['email'] as String?,
        profileImageUrl: row['profile_photo'] as String?,
      );
}

/// Keeps profiles in a map; for tests and for the mock repository.
class InMemoryProfileStore implements ProfileStore {
  final Map<String, AppUser> _byAuthId = {};
  int _nextId = 1;

  @override
  Future<AppUser?> findByAuthId(String authUserId) async => _byAuthId[authUserId];

  @override
  Future<AppUser> create(AppUser draft, {required String authUserId}) async {
    final user = draft.copyWith(id: 'person-${_nextId++}');
    _byAuthId[authUserId] = user;
    return user;
  }

  @override
  Future<AppUser> update(AppUser user) async {
    final key = _byAuthId.entries.firstWhere((e) => e.value.id == user.id).key;
    _byAuthId[key] = user;
    return user;
  }
}
