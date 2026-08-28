import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Matches website's DOCUMENT_TYPES in components/ProfilePage/ProfilePage.tsx
const documentTypes = [
  'Medical Degree (MBBS/MD/MS)',
  'Medical Registration Certificate',
  'Aadhaar / Government ID',
  'Specialization Certificate',
  'Hospital Affiliation Letter',
];

const _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
const _maxSizeBytes = 5 * 1024 * 1024; // 5 MB — matches website's limit exactly

class UploadedDocument {
  final String id;
  final String type;
  final DateTime uploadedAt;
  const UploadedDocument({required this.id, required this.type, required this.uploadedAt});
}

class DocumentUploadCard extends StatefulWidget {
  final List<UploadedDocument> uploadedDocuments;
  final Future<void> Function(String documentType, Uint8List bytes, String fileName, String mimeType) onUpload;
  final Future<void> Function(String documentId) onDelete;

  const DocumentUploadCard({
    super.key,
    required this.uploadedDocuments,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  State<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  String? _selectedType;
  PlatformFile? _selectedFile;
  String? _error;
  bool _uploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.size > _maxSizeBytes) {
      setState(() => _error = 'File size must be under 5 MB');
      return;
    }
    setState(() {
      _selectedFile = file;
      _error = null;
    });
  }

  Future<void> _upload() async {
    if (_selectedType == null || _selectedFile == null) {
      setState(() => _error = 'Please select a document type and file');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final ext = (_selectedFile!.extension ?? '').toLowerCase();
      final mimeType = switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'pdf' => 'application/pdf',
        _ => 'application/octet-stream',
      };
      await widget.onUpload(_selectedType!, _selectedFile!.bytes!, _selectedFile!.name, mimeType);
      setState(() {
        _selectedType = null;
        _selectedFile = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadedTypes = widget.uploadedDocuments.map((d) => d.type).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Already uploaded documents ---
        if (widget.uploadedDocuments.isNotEmpty) ...[
          ...widget.uploadedDocuments.map((doc) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.tintTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description_rounded, size: 18, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                      const SizedBox(height: 2),
                      Text(
                        'Uploaded ${_formatDate(doc.uploadedAt)}',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                  onPressed: () => widget.onDelete(doc.id),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
        ],

        // --- Upload new document ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload a document',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                isExpanded: true,
                decoration: const InputDecoration(hintText: 'Select document type'),
                items: documentTypes.map((type) {
                  final alreadyUploaded = uploadedTypes.contains(type);
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      alreadyUploaded ? '$type ✓' : type,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedType = v),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                        color: _selectedFile != null ? AppColors.success : AppColors.textMuted,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedFile?.name ?? 'Tap to choose a file (JPG, PNG, WebP, PDF · max 5MB)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _selectedFile != null ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 11.5)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _uploading ? null : _upload,
                  child: _uploading
                      ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Upload Document'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}