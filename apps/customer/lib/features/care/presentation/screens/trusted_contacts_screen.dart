import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../application/care_calls.dart';

class TrustedContactsScreen extends ConsumerStatefulWidget {
  const TrustedContactsScreen({super.key});
  @override
  ConsumerState<TrustedContactsScreen> createState() =>
      _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends ConsumerState<TrustedContactsScreen> {
  String? _code;
  String? _error;
  bool _inviteAccepted = false;
  bool _busy = false;
  final _invite = TextEditingController();
  @override
  void dispose() {
    _invite.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _inviteAccepted = false;
    });
    try {
      if (useMockData) {
        throw StateError('Sign into the live app to connect trusted contacts.');
      }
      await action();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PostgrestException
              ? e.message
              : e is StateError
              ? e.message.toString()
              : 'Could not connect. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connections = ref.watch(careConnectionsProvider);
    final pid = ref.watch(currentUserIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted contacts'),
        actions: [
          IconButton(
            tooltip: 'Refresh connections',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(careConnectionsProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Bring your circle into Kaylo',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Invite up to five family members or doctors who use Kaylo. When they accept your code, they can receive your SOS alerts and join the same voice call.',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final code =
                        await ref
                                .read(supabaseClientProvider)
                                .rpc('care_invite_code')
                            as String;
                    if (mounted) setState(() => _code = code);
                  }),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Get my invite code'),
          ),
          if (_code != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SelectableText(
                      _code!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _code!));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite code copied')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy code'),
                    ),
                    const Text(
                      'Valid for seven days. Share only with people you trust.',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 28),
          Text(
            'Accept someone’s invitation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _invite,
            maxLength: 32,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Invite code'),
          ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    await ref
                        .read(supabaseClientProvider)
                        .rpc(
                          'accept_care_invite',
                          params: {'p_code': _invite.text.trim()},
                        );
                    if (!context.mounted) return;
                    FocusScope.of(context).unfocus();
                    _invite.clear();
                    ref.invalidate(careConnectionsProvider);
                    setState(() => _inviteAccepted = true);
                  }),
            child: const Text('Accept invitation'),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_inviteAccepted)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Invitation accepted. You are now connected and can receive their SOS alerts.',
                    ),
                  ),
                ],
              ),
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 24),
          Text(
            'Your connections',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          connections.when(
            data: (rows) => Column(
              children: [
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No connections yet'),
                  ),
                for (final row in rows)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.shield_outlined),
                      title: Text(
                        (row['owner_id'] == pid
                                ? row['contact_name']
                                : row['owner_name'])
                            as String,
                      ),
                      subtitle: Text(
                        row['owner_id'] == pid
                            ? 'Receives your SOS alerts'
                            : 'You receive their SOS alerts',
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove connection',
                        icon: const Icon(Icons.close),
                        onPressed: _busy
                            ? null
                            : () async {
                                final remove = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remove connection?'),
                                    content: const Text(
                                      'This connection will no longer receive SOS call invitations.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (remove == true) {
                                  await _run(() async {
                                    await ref
                                        .read(supabaseClientProvider)
                                        .from('care_connections')
                                        .delete()
                                        .eq('id', row['id']);
                                    ref.invalidate(careConnectionsProvider);
                                  });
                                }
                              },
                      ),
                    ),
                  ),
              ],
            ),
            error: (_, _) => TextButton(
              onPressed: () => ref.invalidate(careConnectionsProvider),
              child: const Text('Could not load contacts. Retry'),
            ),
            loading: () => const LinearProgressIndicator(),
          ),
        ],
      ),
    );
  }
}
