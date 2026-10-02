import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

enum DocumentUploadStatus { notUploaded, uploading, uploaded, verified, rejected }

class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.status = DocumentUploadStatus.notUploaded,
    this.fileName,
    this.uploadProgress = 0.0,
    required this.onUpload,
    this.onRemove,
  });

  final String title;
  final String description;
  final IconData icon;
  final DocumentUploadStatus status;
  final String? fileName;
  final double uploadProgress;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color statusBg;
    Color statusFg;
    String statusText;

    switch (status) {
      case DocumentUploadStatus.verified:
        borderColor = AppColors.teal;
        statusBg = AppColors.mint;
        statusFg = AppColors.teal;
        statusText = 'Verified';
        break;
      case DocumentUploadStatus.uploaded:
        borderColor = AppColors.teal.withValues(alpha: 0.5);
        statusBg = AppColors.mint;
        statusFg = AppColors.teal;
        statusText = 'Uploaded';
        break;
      case DocumentUploadStatus.uploading:
        borderColor = AppColors.teal;
        statusBg = AppColors.sand;
        statusFg = AppColors.ink;
        statusText = 'Uploading...';
        break;
      case DocumentUploadStatus.rejected:
        borderColor = AppColors.coral;
        statusBg = const Color(0xFFFDE8E8);
        statusFg = AppColors.coral;
        statusText = 'Rejected';
        break;
      case DocumentUploadStatus.notUploaded:
        borderColor = AppColors.sand;
        statusBg = const Color(0xFFF2F4F7);
        statusFg = AppColors.muted;
        statusText = 'Required';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.teal, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusFg,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (fileName != null && fileName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sand),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded,
                      size: 16, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fileName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onRemove != null)
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.muted),
                    ),
                ],
              ),
            ),
          ],

          if (status == DocumentUploadStatus.uploading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: uploadProgress > 0 ? uploadProgress : null,
                minHeight: 4,
                backgroundColor: AppColors.sand,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.teal),
              ),
            ),
          ],

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  status == DocumentUploadStatus.uploading ? null : onUpload,
              icon: Icon(
                status == DocumentUploadStatus.uploaded ||
                        status == DocumentUploadStatus.verified
                    ? Icons.refresh_rounded
                    : Icons.cloud_upload_outlined,
                size: 18,
              ),
              label: Text(
                status == DocumentUploadStatus.uploaded ||
                        status == DocumentUploadStatus.verified
                    ? 'Replace Document'
                    : 'Upload Document',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.sand, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
