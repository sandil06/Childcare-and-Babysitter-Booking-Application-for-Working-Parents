import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/parent_provider.dart';
import '../widgets/sitter_card.dart';

class BabysitterListScreen extends StatelessWidget {
  const BabysitterListScreen({super.key});

  @override
  Widget build(BuildContext context) => const _BabysitterListView();
}

class _BabysitterListView extends StatefulWidget {
  const _BabysitterListView();

  @override
  State<_BabysitterListView> createState() => _BabysitterListViewState();
}

class _BabysitterListViewState extends State<_BabysitterListView> {
  final _provider = ParentProvider.instance;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _provider.addListener(_refresh);
    if (_provider.babysitters.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _provider.searchBabysitters();
      });
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      _provider.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _provider.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _openProfile(dynamic sitter) async {
    await _provider.selectBabysitter(sitter);
    if (mounted) Navigator.pushNamed(context, AppRoutes.babysitterProfile);
  }

  @override
  Widget build(BuildContext context) {
    final sitters = _provider.babysitters;
    final isInitialLoad = _provider.isInitialLoading && sitters.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          _provider.search.isEmpty ? 'Babysitters' : 'Search results',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Filters',
            icon: Badge(
              isLabelVisible: _provider.hasFilters,
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.parentFilters);
              await _provider.searchBabysitters();
            },
          ),
        ],
      ),
      body: isInitialLoad
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : _provider.errorMessage != null && sitters.isEmpty
          ? _buildError()
          : RefreshIndicator(
              color: AppColors.teal,
              onRefresh: () => _provider.searchBabysitters(isRefresh: true),
              child: sitters.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(AppSizes.pagePadding),
                      itemCount: sitters.length + (_provider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == sitters.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.teal,
                                ),
                              ),
                            ),
                          );
                        }
                        final sitter = sitters[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SitterCard(
                            sitter: sitter,
                            onTap: () => _openProfile(sitter),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmpty() => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded, color: AppColors.muted, size: 42),
                SizedBox(height: 12),
                Text(
                  'No babysitters found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Try a different name or clear some filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildError() => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, color: AppColors.coral, size: 42),
                const SizedBox(height: 12),
                Text(_provider.errorMessage ?? 'An error occurred', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _provider.searchBabysitters(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
