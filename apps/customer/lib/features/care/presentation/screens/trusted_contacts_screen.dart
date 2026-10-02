import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../application/care_calls.dart';
import '../../../../l10n/generated/app_localizations.dart';

class TrustedContactsScreen extends ConsumerStatefulWidget {
  const TrustedContactsScreen({super.key});
  @override
  ConsumerState<TrustedContactsScreen> createState() =>
      _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends ConsumerState<TrustedContactsScreen> {
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
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
        throw StateError(_l10n.signInLiveForContacts);
      }
      await action();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PostgrestException
              ? e.message
              : e is StateError
              ? e.message.toString()
              : _l10n.couldNotConnectRetry,
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
        title: Text(_l10n.trustedContacts),
        actions: [
          IconButton(
            tooltip: _l10n.refreshConnections,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(careConnectionsProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _l10n.trustedCircleTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(_l10n.trustedCircleBody),
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
            label: Text(_l10n.getInviteCode),
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
                            SnackBar(content: Text(_l10n.inviteCodeCopied)),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(_l10n.copyCode),
                    ),
                    Text(_l10n.inviteCodeValidity),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 28),
          Text(
            _l10n.acceptInviteTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _invite,
            maxLength: 32,
            autocorrect: false,
            decoration: InputDecoration(labelText: _l10n.inviteCode),
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
            child: Text(_l10n.acceptInvitation),
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
                  Expanded(child: Text(_l10n.invitationAccepted)),
                ],
              ),
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 24),
          Text(
            _l10n.yourConnections,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          connections.when(
            data: (rows) => Column(
              children: [
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_l10n.noConnectionsYet),
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
                            ? _l10n.receivesYourSos
                            : _l10n.youReceiveTheirSos,
                      ),
                      trailing: IconButton(
                        tooltip: _l10n.removeConnection,
                        icon: const Icon(Icons.close),
                        onPressed: _busy
                            ? null
                            : () async {
                                final remove = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(_l10n.removeConnectionTitle),
                                    content: Text(_l10n.removeConnectionBody),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(_l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(_l10n.removeContact),
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
              child: Text(_l10n.contactsLoadFailedRetry),
            ),
            loading: () => const LinearProgressIndicator(),
          ),
        ],
      ),
    );
  }
}
