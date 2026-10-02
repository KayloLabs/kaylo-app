import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../../auth/application/session_controller.dart';
import '../../../care/presentation/screens/prescriptions_screen.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy || _confirmation.text != 'DELETE') return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final userId = ref.read(currentUserIdProvider);
      if (useMockData) {
        throw StateError('Account deletion requires a signed-in live account.');
      }
      final response = await ref
          .read(supabaseClientProvider)
          .functions
          .invoke('delete-account', body: {'confirmation': 'DELETE'});
      if (response.data is! Map || response.data['deleted'] != true) {
        throw StateError('Deletion was not confirmed. Please retry.');
      }
      // Clear private local records before invalidating the session.
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          userId != null) {
        await prescriptionChannel.invokeMethod('clear', {'userId': userId});
      }
      await ref.read(sessionControllerProvider.notifier).signOut();
      if (mounted) context.go('/');
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map && details['error'] is Map
          ? details['error']['message']
          : null;
      if (mounted) {
        setState(
          () => _error =
              message?.toString() ??
              'Could not delete the account. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is StateError
              ? e.message.toString()
              : 'Could not delete the account. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.person_remove_outlined, size: 56, color: Colors.red),
          const SizedBox(height: 24),
          Text(
            'Permanently delete your Kaylo account?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'This removes your sign-in, profile, bookings, messages, care records and prescriptions stored on this device. It cannot be undone. Complete or cancel active bookings first. For unresolved payments, contact kayloapp@gmail.com.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Payment processors may retain transaction records. Documents you previously shared are not removed from other people’s devices.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _confirmation,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Type DELETE to confirm',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy || _confirmation.text != 'DELETE' ? null : _delete,
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text(_busy ? 'Deleting…' : 'Delete my account'),
          ),
        ],
      ),
    ),
  );
}
