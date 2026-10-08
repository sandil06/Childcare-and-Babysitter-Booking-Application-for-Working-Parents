import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/local_storage.dart';

class ProfileImageService {
  ProfileImageService._();
  static final ProfileImageService instance = ProfileImageService._();

  final ImagePicker _picker = ImagePicker();

  /// Resolves relative paths like `/uploads/...` to a full URL against backend host
  static String resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final rootHost = ApiClient.defaultBaseUrl.replaceAll('/api/v1', '');
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$rootHost$cleanPath';
  }

  /// Convenience method to show options and upload
  Future<String?> showImagePickerOptions(
    BuildContext context, {
    String role = 'parent',
  }) {
    return pickAndUploadImage(context: context, role: role);
  }

  /// Prompts user to select image from Camera, Gallery, or Curated Avatar, then uploads to backend
  Future<String?> pickAndUploadImage({
    required BuildContext context,
    required String role,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.teal),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.teal),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.face_retouching_natural_rounded, color: AppColors.teal),
                ),
                title: const Text('Choose an Illustrated Avatar', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, 'preset'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return null;

    if (choice == 'preset') {
      if (!context.mounted) return null;
      return await _showPresetAvatarDialog(context, role);
    }

    try {
      final ImageSource source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Validate file size (< 5MB)
      final length = await pickedFile.length();
      if (length > 5 * 1024 * 1024) {
        throw const ApiException('Selected image exceeds the maximum 5MB size limit.');
      }

      // Validate extension
      final name = pickedFile.name.toLowerCase();
      if (!name.endsWith('.jpg') && !name.endsWith('.jpeg') && !name.endsWith('.png') && !name.endsWith('.webp')) {
        throw const ApiException('Only JPG, PNG, and WEBP image formats are supported.');
      }

      return await uploadImageFile(pickedFile);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to process image: ${e.toString()}');
    }
  }

  /// Uploads an XFile directly to the backend
  Future<String> uploadImageFile(XFile file) async {
    final token = await LocalStorage.instance.read('auth_token') ?? ApiClient.authToken;
    final uri = Uri.parse('${ApiClient.defaultBaseUrl}/auth/avatar');

    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.toString().isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: file.name));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final data = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
      final avatarUrl = (data is Map ? (data['avatar'] ?? data['profileImage'] ?? data['url']) : null)?.toString();
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await LocalStorage.instance.write('user_avatar', avatarUrl);
        return avatarUrl;
      }
      throw const ApiException('Invalid server response while uploading avatar');
    }

    String serverMsg = 'Upload failed with status ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        serverMsg = decoded['message'].toString();
      }
    } catch (_) {}
    throw ApiException(serverMsg, statusCode: response.statusCode);
  }

  /// Sets a curated avatar URL directly
  Future<String?> _showPresetAvatarDialog(BuildContext context, String role) async {
    final List<String> presetAvatars = [
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=400&q=80',
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Avatar',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: presetAvatars.length,
            itemBuilder: (ctx, idx) {
              final url = presetAvatars[idx];
              return InkWell(
                onTap: () => Navigator.pop(ctx, url),
                borderRadius: BorderRadius.circular(100),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(url),
                  backgroundColor: AppColors.mint,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
        ],
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      try {
        final client = ApiClient();
        final res = await client.post('auth/avatar', body: {'imageUrl': selected});
        final data = res is Map && res['data'] != null ? res['data'] : res;
        final avatarUrl = (data is Map ? (data['avatar'] ?? data['profileImage'] ?? data['url']) : null)?.toString() ?? selected;
        await LocalStorage.instance.write('user_avatar', avatarUrl);
        return avatarUrl;
      } catch (_) {
        await LocalStorage.instance.write('user_avatar', selected);
        return selected;
      }
    }
    return null;
  }
}
