import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class FilePhotoUploadWidget<T> extends StatelessWidget {
  final String title;
  final String buttonText;
  final IconData buttonIcon;
  final List<T> files;
  final String Function(T file) fileNameBuilder;
  final void Function(int index) onRemoveFile;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onPickFile;
  final String? helperText;
  final Color? titleColor;
  final bool showFileList;

  const FilePhotoUploadWidget({
    super.key,
    required this.title,
    required this.buttonText,
    required this.files,
    required this.fileNameBuilder,
    required this.onRemoveFile,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onPickFile,
    this.buttonIcon = Icons.add_photo_alternate_outlined,
    this.helperText,
    this.titleColor,
    this.showFileList = true,
  });

  Future<void> _showFilePickerOptions(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryDark,
                    size: 34,
                  ),
                  title: const Text(
                    'Kamera',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPickCamera();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primaryDark,
                    size: 34,
                  ),
                  title: const Text(
                    'Galeri',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPickGallery();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: AppColors.primaryDark,
                    size: 34,
                  ),
                  title: const Text(
                    'Dosya Yükle',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPickFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAllowedFilesInfo(BuildContext context) async {
    final allowedText =
        helperText ?? '(pdf, jpg, jpeg, png, doc, docx, xls, xlsx)';
    final cleanedText = allowedText.replaceAll('(', '').replaceAll(')', '');
    final allowedTypes = cleanedText
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Center(
                  child: Icon(
                    Icons.info_outline,
                    size: 40,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Eklenebilecek Dosya Türleri',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                if (allowedTypes.isNotEmpty)
                  Text(
                    allowedTypes.join(', '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryDark,
                    ),
                  )
                else
                  const Text(
                    'Desteklenen dosya türleri bulunamadı.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryDark,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                      2,
                  color: titleColor ?? AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => _showAllowedFilesInfo(context),
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showFilePickerOptions(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textOnPrimary,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
              elevation: 0,
            ),
            icon: Icon(buttonIcon, size: 34, color: AppColors.primaryDark),
            label: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: const TextStyle(color: AppColors.primaryDark, fontSize: 16),
          ),
        ],
        if (showFileList && files.isNotEmpty) ...[
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      color: AppColors.primaryDark,
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fileNameBuilder(file),
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.primaryDark,
                        size: 30,
                      ),
                      onPressed: () => onRemoveFile(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
