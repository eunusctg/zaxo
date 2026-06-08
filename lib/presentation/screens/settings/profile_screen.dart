import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/data/services/firebase_database_service.dart';
import 'package:zaxo/data/services/r2_storage_service.dart';
import 'package:zaxo/di/injection_container.dart';
import 'package:zaxo/presentation/blocs/auth/auth_bloc.dart';
import 'package:zaxo/presentation/blocs/auth/auth_state.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  bool _isEditingName = false;
  bool _isEditingAbout = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  final _dbService = sl<FirebaseDatabaseService>();
  final _r2Service = sl<R2StorageService>();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      _nameController.text = state.user.name;
      _aboutController.text = state.user.about ?? 'Hey there! I am using Zaxo 💜';
      _avatarUrl = state.user.avatarUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await _dbService.updateUser(uid, {
        'name': _nameController.text.trim(),
      });

      // Also update Firebase Auth display name
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        setState(() {
          _isEditingName = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveAbout() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await _dbService.updateUser(uid, {
        'about': _aboutController.text.trim(),
      });

      if (mounted) {
        setState(() {
          _isEditingAbout = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('About updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _changeAvatar() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _isUploadingAvatar = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final file = File(picked.path);
      final path = _r2Service.generatePath('images/avatars', '.jpg');
      final imageUrl = await _r2Service.uploadImage(file, path);

      // Update in Firebase Database
      await _dbService.updateUser(uid, {'avatarUrl': imageUrl});

      // Update Firebase Auth photo URL
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(imageUrl);

      if (mounted) {
        setState(() {
          _avatarUrl = imageUrl;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: _isUploadingAvatar
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.camera_alt_outlined,
                    color: AppColors.textSecondary),
            onPressed: _isUploadingAvatar ? null : _changeAvatar,
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;

          // Sync controllers with user data on state changes
          if (user != null && !_isEditingName) {
            _nameController.text = user.name;
          }
          if (user != null && !_isEditingAbout) {
            _aboutController.text =
                user.about ?? 'Hey there! I am using Zaxo 💜';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingXl),
            child: Column(
              children: [
                // Profile avatar
                Center(
                  child: GestureDetector(
                    onTap: _isUploadingAvatar ? null : _changeAvatar,
                    child: Stack(
                      children: [
                        _isUploadingAvatar
                            ? const SizedBox(
                                width: 96,
                                height: 96,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : ProfileAvatar(
                                name: user?.name ?? 'Me',
                                imageUrl: _avatarUrl ?? user?.avatarUrl,
                                size: AvatarSize.xl,
                              ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.surface, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Name
                _buildEditableField(
                  label: 'Name',
                  controller: _nameController,
                  isEditing: _isEditingName,
                  onEdit: () => setState(() => _isEditingName = true),
                  onSave: _saveName,
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 20),

                // About
                _buildEditableField(
                  label: 'About',
                  controller: _aboutController,
                  isEditing: _isEditingAbout,
                  onEdit: () => setState(() => _isEditingAbout = true),
                  onSave: _saveAbout,
                  icon: Icons.info_outline,
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // Phone (read-only)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Phone',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        user?.phone ?? 'Not set',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Email (read-only)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email_outlined,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Email',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        user?.email ?? 'Not set',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_isSaving && isEditing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isEditing)
              TextButton(
                onPressed: _isSaving ? null : onSave,
                child: Text('Save',
                    style:
                        TextStyle(color: AppColors.secondary, fontSize: 13)),
              )
            else
              TextButton(
                onPressed: onEdit,
                child: Text('Edit',
                    style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: isEditing
              ? TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  maxLines: maxLines,
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                )
              : Text(
                  controller.text,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }
}
