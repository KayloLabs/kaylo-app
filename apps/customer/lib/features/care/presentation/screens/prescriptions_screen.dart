import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

const prescriptionChannel = MethodChannel('kaylo/prescriptions');

class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key});
  @override
  ConsumerState<PrescriptionsScreen> createState() =>
      _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen> {
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> _documents = [];
  bool _busy = false;
  String? _error;
  String _query = '';
  String get _userId => ref.read(currentUserIdProvider) ?? '';
  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<T?> _invoke<T>(
    String method, [
    Map<String, dynamic> data = const {},
  ]) =>
      prescriptionChannel.invokeMethod<T>(method, {'userId': _userId, ...data});
  Future<void> _load() async {
    if (!_supported) return;
    try {
      final rows = await _invoke<List<dynamic>>('list') ?? [];
      if (mounted) {
        setState(() {
          _documents = rows
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = _l10n.prescriptionsLoadFailed);
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on PlatformException catch (e) {
      if (mounted) {
        KayloSnackbar.showError(context, e.message ?? _l10n.actionFailed);
      }
    } catch (_) {
      if (mounted) {
        KayloSnackbar.showError(context, _l10n.prescriptionSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(bool scan) => _run(() async {
    Map<String, dynamic> document = {
      'id': const Uuid().v4(),
      'text': '',
      'scanned': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    if (scan) {
      final result = await _invoke<Map>('scan');
      if (result == null) return;
      document = Map<String, dynamic>.from(result);
    }
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            _PrescriptionEditor(userId: _userId, document: document),
      ),
    );
    if (saved != true) await _invoke('delete', {'id': document['id']});
    await _load();
  });
  @override
  Widget build(BuildContext context) {
    final filtered = _documents
        .where(
          (d) => '${d['title']} ${d['text']}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(_l10n.prescriptions)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _l10n.prescriptionsHeadline,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_l10n.prescriptionsIntro),
            const SizedBox(height: 20),
            if (!_supported)
              Text(_l10n.prescriptionsAndroidOnly)
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _add(true),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(_l10n.scanOrPhotos),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _add(false),
                      icon: const Icon(Icons.edit_note),
                      label: Text(_l10n.typeRecord),
                    ),
                  ),
                ],
              ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: _l10n.searchPrescriptions,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              TextButton(onPressed: _load, child: Text(_error!)),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.description_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      _query.isEmpty
                          ? _l10n.noPrescriptionsYet
                          : _l10n.noMatchingPrescriptions,
                    ),
                  ],
                ),
              ),
            for (final document in filtered)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(document['title'] as String),
                  subtitle: Text(
                    '${DateTime.fromMillisecondsSinceEpoch(document['createdAt'] as int).toLocal().toString().split(' ').first} • ${document['scanned'] == true ? 'Scanned PDF' : 'Typed record'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy
                      ? null
                      : () => _run(() async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _PrescriptionEditor(
                                userId: _userId,
                                document: document,
                                existing: true,
                              ),
                            ),
                          );
                          await _load();
                        }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionEditor extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> document;
  final bool existing;
  const _PrescriptionEditor({
    required this.userId,
    required this.document,
    this.existing = false,
  });
  @override
  State<_PrescriptionEditor> createState() => _PrescriptionEditorState();
}

class _PrescriptionEditorState extends State<_PrescriptionEditor> {
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  late final _title = TextEditingController(
    text: widget.document['title'] as String? ?? 'Prescription',
  );
  late final _text = TextEditingController(
    text: widget.document['text'] as String? ?? '',
  );
  bool _busy = false;
  bool get _scanned => widget.document['scanned'] == true;
  Future<void> _action(String method) async {
    if (_busy) return;
    if (method == 'save' &&
        (_title.text.trim().isEmpty ||
            (!_scanned && _text.text.trim().isEmpty))) {
      KayloSnackbar.showError(context, _l10n.prescriptionNeedsTitleText);
      return;
    }
    setState(() => _busy = true);
    try {
      await prescriptionChannel.invokeMethod(method, {
        ...widget.document,
        'userId': widget.userId,
        'title': _title.text.trim(),
        'text': _text.text.trim(),
      });
      if (mounted && (method == 'save' || method == 'delete')) {
        Navigator.pop(context, true);
      }
    } on PlatformException catch (e) {
      if (mounted) {
        KayloSnackbar.showError(context, e.message ?? _l10n.actionFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing ? _l10n.prescriptionRecord : _l10n.reviewPrescription,
        ),
        actions: [
          if (widget.existing)
            IconButton(
              tooltip: _l10n.deletePrescription,
              onPressed: _busy
                  ? null
                  : () async {
                      final remove = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(_l10n.deletePrescriptionTitle),
                          content: Text(_l10n.deletePrescriptionBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(_l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(_l10n.delete),
                            ),
                          ],
                        ),
                      );
                      if (remove == true) await _action('delete');
                    },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_scanned) ...[
            Text(_l10n.prescriptionReviewHint),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _action('open'),
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(_l10n.viewOriginalPdf),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _title,
            maxLength: 160,
            decoration: InputDecoration(labelText: _l10n.titleLabel),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            minLines: 10,
            maxLines: 25,
            maxLength: 100000,
            decoration: InputDecoration(
              labelText: _scanned
                  ? _l10n.extractedTextNotes
                  : _l10n.prescriptionDetails,
              alignLabelWithHint: true,
            ),
          ),
          if (_scanned) Text(_l10n.prescriptionEditHint),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : () => _action('save'),
            icon: const Icon(Icons.save_outlined),
            label: Text(_busy ? _l10n.saving : _l10n.savePrescription),
          ),
          if (widget.existing) ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _action('open'),
              icon: const Icon(Icons.open_in_new),
              label: Text(_l10n.openSavedPdf),
            ),
            TextButton.icon(
              onPressed: _busy ? null : () => _action('share'),
              icon: const Icon(Icons.share_outlined),
              label: Text(_l10n.shareSavedPdf),
            ),
          ],
        ],
      ),
    ),
  );
}
