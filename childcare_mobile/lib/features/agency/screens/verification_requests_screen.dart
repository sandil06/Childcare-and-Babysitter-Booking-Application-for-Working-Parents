import 'dart:async';
import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/verification_request_model.dart';
import '../providers/agency_provider.dart';
import '../widgets/verification_card.dart';

class VerificationRequestsScreen extends StatefulWidget {
  const VerificationRequestsScreen({super.key});

  @override
  State<VerificationRequestsScreen> createState() =>
      _VerificationRequestsScreenState();
}

class _VerificationRequestsScreenState extends State<VerificationRequestsScreen> {
  final AgencyProvider _provider = AgencyProvider.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  final List<Map<String, String>> _statusTabs = const [
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Under Review', 'value': 'under_review'},
    {'label': 'Verified', 'value': 'verified'},
    {'label': 'Rejected', 'value': 'rejected'},
    {'label': 'All', 'value': 'all'},
  ];

  @override
  void initState() {
    super.initState();
    _provider.loadVerificationRequests();

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _provider.loadVerificationRequests(
        search: _searchController.text.trim(),
      );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_provider.isLoadingMore &&
        _provider.verificationsHasMore) {
      // Lazy load next page
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openDetails(VerificationRequestModel request) {
    _provider.selectVerification(request);
    Navigator.pushNamed(
      context,
      AppRoutes.agencySitterVerification,
      arguments: request,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, _) {
        final list = _provider.verificationRequests;
        final isLoading = _provider.isInitialLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.ink),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Verification Requests',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.teal),
                onPressed: () => _provider.loadVerificationRequests(refresh: true),
                tooltip: 'Refresh Queue',
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search caregiver by name or email...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _provider.loadVerificationRequests();
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius),
                          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Status Tabs
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statusTabs.length,
                        separatorBuilder: (_, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final tab = _statusTabs[index];
                          final isSelected =
                              _provider.verificationFilter == tab['value'];

                          return ChoiceChip(
                            label: Text(tab['label']!),
                            selected: isSelected,
                            onSelected: (_) =>
                                _provider.setVerificationFilter(tab['value']!),
                            selectedColor: AppColors.teal,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12.5,
                            ),
                            elevation: 0,
                            pressElevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isSelected ? AppColors.teal : const Color(0xFFCBD5E1),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Results Count Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFF1F5F9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${list.length} Applications found',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Text(
                      'Sorted by newest',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Request List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                    : RefreshIndicator(
                        color: AppColors.teal,
                        onRefresh: () =>
                            _provider.loadVerificationRequests(refresh: true),
                        child: list.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final req = list[index];
                                  return VerificationCard(
                                    request: req,
                                    onTap: () => _openDetails(req),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 32,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Verification Requests Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'There are no caregiver applications matching the selected status or search filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
