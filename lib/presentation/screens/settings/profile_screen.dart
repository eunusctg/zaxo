import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController(text: 'John Doe');
  final _aboutController = TextEditingController(text: 'Hey there! I am using Zaxo 💜');
  final _phoneController = TextEditingController(text: '+1 234 567 8900');
  bool _isEditingName = false;
  bool _isEditingAbout = false;

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    super.dispose();
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
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingXl),
        child: Column(
          children: [
            // Profile avatar
            Center(
              child: Stack(
                children: [
                  const ProfileAvatar(name: 'John Doe', size: AvatarSize.xl),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Name
            _buildEditableField(
              label: 'Name',
              controller: _nameController,
              isEditing: _isEditingName,
              onEdit: () => setState(() => _isEditingName = true),
              onSave: () => setState(() => _isEditingName = false),
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 20),

            // About
            _buildEditableField(
              label: 'About',
              controller: _aboutController,
              isEditing: _isEditingAbout,
              onEdit: () => setState(() => _isEditingAbout = true),
              onSave: () => setState(() => _isEditingAbout = false),
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
                    Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Phone',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    _phoneController.text,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
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
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (isEditing)
              TextButton(
                onPressed: onSave,
                child: Text('Save', style: TextStyle(color: AppColors.secondary, fontSize: 13)),
              )
            else
              TextButton(
                onPressed: onEdit,
                child: Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 13)),
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
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
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
