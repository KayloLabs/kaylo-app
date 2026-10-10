import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/worker_application.dart';

abstract interface class ApplicationDocumentPicker {
  Future<ApplicationDocument?> pick(ApplicationDocumentType type);
}

final applicationDocumentPickerProvider = Provider<ApplicationDocumentPicker>(
  (ref) => const PlatformApplicationDocumentPicker(),
);

class PlatformApplicationDocumentPicker implements ApplicationDocumentPicker {
  const PlatformApplicationDocumentPicker();

  @override
  Future<ApplicationDocument?> pick(ApplicationDocumentType type) async {
    final imageOnly =
        type == ApplicationDocumentType.photo ||
        type == ApplicationDocumentType.selfie;
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', if (!imageOnly) 'pdf'],
    );
    if (file == null) return null;
    final knownSize = await file.length();
    if (knownSize != null && knownSize > ApplicationDocument.maxBytes) {
      throw const WorkerApplicationFailure(
        ApplicationFailureCode.invalidDocument,
      );
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (builder.length + chunk.length > ApplicationDocument.maxBytes) {
        throw const WorkerApplicationFailure(
          ApplicationFailureCode.invalidDocument,
        );
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    final document = ApplicationDocument(name: file.name, bytes: bytes);
    if (!document.isValid || (imageOnly && document.extension == 'pdf')) {
      throw const WorkerApplicationFailure(
        ApplicationFailureCode.invalidDocument,
      );
    }
    return document;
  }
}
