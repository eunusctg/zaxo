import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zaxo/core/constants/app_colors.dart';
import 'package:zaxo/core/constants/app_dimensions.dart';
import 'package:zaxo/data/services/firebase_database_service.dart';
import 'package:zaxo/di/injection_container.dart';
import 'package:zaxo/presentation/blocs/chat/chat_bloc.dart';
import 'package:zaxo/presentation/blocs/chat/chat_event.dart';
import 'package:zaxo/presentation/widgets/profile_avatar.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchController = TextEditingController();
  final _dbService = sl<FirebaseDatabaseService>();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allContacts = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllContacts();
  }

  Future<void> _loadAllContacts() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load all users as contacts (in a real app, this would be contacts from phone book)
      final users = await _dbService.searchUsers('');
      // Filter out current user
      final contacts = users
          .where((u) => u['id'] != currentUserId)
          .toList();

      if (mounted) {
        setState(() {
          _allContacts = contacts;
          _searchResults = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load contacts: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _onSearchChanged(String query) async {
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    try {
      if (query.trim().isEmpty) {
        setState(() {
          _searchResults = _allContacts;
          _isSearching = false;
        });
        return;
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final results = await _dbService.searchUsers(query.trim());
      // Filter out current user
      final filtered =
          results.where((u) => u['id'] != currentUserId).toList();

      if (mounted) {
        setState(() {
          _searchResults = filtered;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openOrCreateChat(Map<String, dynamic> contact) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final contactId = contact['id'] as String;
      // Dispatch ChatCreated event via ChatBloc
      context.read<ChatBloc>().add(ChatCreated(
            participantIds: [currentUserId, contactId],
            isGroup: false,
          ));

      // Navigate to chat
      if (mounted) {
        context.go('/chat/$contactId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        title: const Text('Select Contact',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              children: [
                // New group
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.group,
                        color: AppColors.primary, size: 20),
                  ),
                  title: const Text('New group',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
                  onTap: () {},
                ),

                // New community
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.public,
                        color: AppColors.secondary, size: 20),
                  ),
                  title: const Text('New community',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
                  onTap: () {},
                ),

                Divider(color: AppColors.outline.withValues(alpha: 0.2)),

                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                if (!_isSearching && _searchQuery.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Contacts on Zaxo',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                if (!_isSearching && _searchQuery.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      _searchResults.isEmpty
                          ? 'No results found'
                          : '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                // Contact list
                ..._searchResults.map((contact) {
                  final name = contact['name'] as String? ?? 'Unknown';
                  final about = contact['about'] as String? ?? '';
                  final isOnline = contact['isOnline'] as bool? ?? false;
                  final avatarUrl = contact['avatarUrl'] as String?;
                  return ListTile(
                    leading: ProfileAvatar(
                      name: name,
                      imageUrl: avatarUrl,
                      size: AvatarSize.md,
                      isOnline: isOnline,
                      showOnlineIndicator: isOnline,
                    ),
                    title: Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15)),
                    subtitle: about.isNotEmpty
                        ? Text(about,
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13))
                        : null,
                    onTap: () => _openOrCreateChat(contact),
                  );
                }),

                // Empty state when no contacts and not searching
                if (!_isSearching &&
                    _allContacts.isEmpty &&
                    _searchQuery.isEmpty)
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No contacts yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Search for users to start chatting',
                            style: TextStyle(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
