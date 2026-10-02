import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import '../../../auth/application/current_user_provider.dart';

const prescriptionChannel = MethodChannel('kaylo/prescriptions');

class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key});
  @override
  ConsumerState<PrescriptionsScreen> createState() =>
      _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen> {
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
        setState(
          () => _error = 'Could not load prescriptions. Please try again.',
        );
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
        KayloSnackbar.showError(
          context,
          e.message ?? 'Could not complete that action.',
        );
      }
    } catch (_) {
      if (mounted) {
        KayloSnackbar.showError(
          context,
          'Could not save the prescription. Please try again.',
        );
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
      appBar: AppBar(title: const Text('Prescriptions')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your health records, together',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan a prescription or type a previous record. PDFs are saved privately on this device.',
            ),
            const SizedBox(height: 20),
            if (!_supported)
              const Text(
                'Prescription scanning and PDFs are currently available in the Android app.',
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _add(true),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: const Text('Scan / photos'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _add(false),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Type record'),
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
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search prescriptions',
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
                          ? 'No prescriptions yet'
                          : 'No matching prescriptions',
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
      KayloSnackbar.showError(context, 'Add a title and prescription text.');
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
        KayloSnackbar.showError(
          context,
          e.message ?? 'Could not complete that action.',
        );
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
          widget.existing ? 'Prescription record' : 'Review prescription',
        ),
        actions: [
          if (widget.existing)
            IconButton(
              tooltip: 'Delete prescription',
              onPressed: _busy
                  ? null
                  : () async {
                      final remove = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete prescription?'),
                          content: const Text(
                            'The PDF and text will be removed from this device.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
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
            const Text(
              'Review the extracted text against the original. Handwriting may be incomplete or incorrect; confirm medicine names and doses with your doctor.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _action('open'),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('View original PDF'),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _title,
            maxLength: 160,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            minLines: 10,
            maxLines: 25,
            maxLength: 100000,
            decoration: InputDecoration(
              labelText: _scanned
                  ? 'Extracted text / notes'
                  : 'Prescription details',
              alignLabelWithHint: true,
            ),
          ),
          if (_scanned)
            const Text(
              'Editing this text keeps the original scanned PDF unchanged.',
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : () => _action('save'),
            icon: const Icon(Icons.save_outlined),
            label: Text(_busy ? 'Saving…' : 'Save prescription'),
          ),
          if (widget.existing) ...[
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _action('open'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open saved PDF'),
            ),
            TextButton.icon(
              onPressed: _busy ? null : () => _action('share'),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share saved PDF'),
            ),
          ],
        ],
      ),
    ),
  );
}
