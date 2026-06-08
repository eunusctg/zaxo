import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/data/services/r2_storage_service.dart';
import 'package:zaxo/di/injection_container.dart';
import 'package:zaxo/presentation/blocs/status/status_bloc.dart';
import 'package:zaxo/presentation/blocs/status/status_event.dart';
import 'package:zaxo/presentation/blocs/status/status_state.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final _textController = TextEditingController();
  int _selectedColorIndex = 0;
  bool _isPosting = false;
  File? _selectedImage;
  final _r2Service = sl<R2StorageService>();
  final _imagePicker = ImagePicker();

  final List<List<Color>> _bgColors = [
    [AppColors.primary, AppColors.primaryDark],
    [AppColors.secondary, const Color(0xFF059669)],
    [AppColors.tertiary, const Color(0xFFBE185D)],
    [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
    [const Color(0xFFF59E0B), const Color(0xFFD97706)],
    [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
  ];

  bool get _canPost {
    if (_isPosting) return false;
    if (_selectedImage != null) return true;
    return _textController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Status',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _canPost ? _postStatus : null,
            child: _isPosting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    'Post',
                    style: TextStyle(
                      color: _canPost ? AppColors.primary : AppColors.outline,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: BlocListener<StatusBloc, StatusState>(
        listener: (context, state) {
          if (state is StatusError && _isPosting) {
            setState(() => _isPosting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Preview
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: _selectedImage != null
                    ? null
                    : BoxDecoration(
                        gradient: LinearGradient(
                          colors: _bgColors[_selectedColorIndex],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                child: Stack(
                  children: [
                    // Image or text background
                    if (_selectedImage != null)
                      SizedBox.expand(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),

                    // Text input overlay
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: TextField(
                          controller: _textController,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _selectedImage != null ? 18 : 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Outfit',
                            shadows: _selectedImage != null
                                ? [
                                    Shadow(
                                      blurRadius: 8,
                                      color: Colors.black.withValues(alpha: 0.7),
                                    ),
                                  ]
                                : null,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: _selectedImage != null
                                ? 'Add a caption...'
                                : 'Type a status...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons row
                  Row(
                    children: [
                      // Photo picker
                      _ActionButton(
                        icon: Icons.photo_library,
                        label: 'Photo',
                        onTap: _pickImage,
                      ),
                      const SizedBox(width: 16),
                      // Camera
                      _ActionButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onTap: _pickFromCamera,
                      ),
                      const SizedBox(width: 16),
                      // Clear image
                      if (_selectedImage != null)
                        _ActionButton(
                          icon: Icons.close,
                          label: 'Remove',
                          onTap: () => setState(() => _selectedImage = null),
                        ),
                    ],
                  ),

                  if (_selectedImage == null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Background Color',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_bgColors.length, (index) {
                        final isSelected = index == _selectedColorIndex;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedColorIndex = index),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _bgColors[index],
                              ),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _postStatus() async {
    setState(() => _isPosting = true);

    try {
      if (_selectedImage != null) {
        // Upload image to R2 first
        final path = _r2Service.generatePath('statuses/images', '.jpg');
        final imageUrl = await _r2Service.uploadImage(_selectedImage!, path);

        if (mounted) {
          context.read<StatusBloc>().add(
                StatusCreated(
                  type: StatusType.image,
                  content: _textController.text.trim(),
                  mediaUrl: imageUrl,
                ),
              );
        }
      } else {
        // Text status
        final bgColorHex = _colorToHex(_bgColors[_selectedColorIndex][0]);
        if (mounted) {
          context.read<StatusBloc>().add(
                StatusCreated(
                  type: StatusType.text,
                  content: _textController.text.trim(),
                  bgColor: bgColorHex,
                ),
              );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status posted!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _colorToHex(Color color) {
    return '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}

/// Small action button for the bottom bar.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
