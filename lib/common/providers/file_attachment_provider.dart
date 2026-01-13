import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

/// State encapsulating the list of selected files and potential errors.
class FileAttachmentState {
  final List<File> files;
  final String? errorMessage;
  final bool isPicking;

  const FileAttachmentState({
    this.files = const [],
    this.errorMessage,
    this.isPicking = false,
  });

  FileAttachmentState copyWith({
    List<File>? files,
    String? errorMessage,
    bool? isPicking,
  }) {
    return FileAttachmentState(
      files: files ?? this.files,
      errorMessage: errorMessage,
      isPicking: isPicking ?? this.isPicking,
    );
  }
}

mixin FileAttachmentMixin on StateNotifier<FileAttachmentState> {
  List<String> get allowedExtensions;

  Future<void> pickFiles() async {
    if (state.isPicking) return;
    state = state.copyWith(isPicking: true, errorMessage: null);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result != null) {
        final newFiles = result.paths.map((path) => File(path!)).toList();
        final currentFiles = [...state.files];
        final duplicates = <String>[];

        for (final newFile in newFiles) {
          final newName = newFile.path.split(Platform.pathSeparator).last;
          if (currentFiles.any(
            (f) => f.path.split(Platform.pathSeparator).last == newName,
          )) {
            duplicates.add(newName);
          } else {
            currentFiles.add(newFile);
          }
        }

        if (duplicates.isNotEmpty) {
          state = state.copyWith(
            files: currentFiles,
            errorMessage:
                'Aşağıdaki dosyalar zaten ekli: ${duplicates.join(", ")}',
            isPicking: false,
          );
        } else {
          state = state.copyWith(files: currentFiles, isPicking: false);
        }
      } else {
        state = state.copyWith(isPicking: false);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Dosya seçimi başarısız: $e',
        isPicking: false,
      );
    }
  }

  void removeFile(int index) {
    if (index >= 0 && index < state.files.length) {
      final updated = [...state.files];
      updated.removeAt(index);
      state = state.copyWith(files: updated);
    }
  }

  void clearHelper() {
    state = FileAttachmentState(
      files: state.files,
      errorMessage: null,
      isPicking: state.isPicking,
    );
  }
}

class GenericFileAttachmentNotifier extends StateNotifier<FileAttachmentState>
    with FileAttachmentMixin {
  final List<String> _allowedExtensions;

  GenericFileAttachmentNotifier(this._allowedExtensions)
    : super(const FileAttachmentState());

  @override
  List<String> get allowedExtensions => _allowedExtensions;
}

final fileAttachmentProvider = StateNotifierProvider.family
    .autoDispose<
      GenericFileAttachmentNotifier,
      FileAttachmentState,
      List<String>
    >(
      (ref, allowedExtensions) =>
          GenericFileAttachmentNotifier(allowedExtensions),
    );
