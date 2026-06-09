import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/search_provider.dart';
import '../controllers/filter_provider.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import '../../../tasks/presentation/widgets/task_list_view.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/confetti_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to changes and update provider immediately (it will debounce internally)
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).set(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterPill(SearchFilter filter, String label) {
    final activeFilter = ref.watch(activeSearchFilterProvider);
    final isSelected = activeFilter == filter;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          HapticFeedback.lightImpact();
          ref.read(activeSearchFilterProvider.notifier).set(filter);
        },
        selectedColor: AppColors.primary.withOpacity(0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected
              ? AppColors.primary
              : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderCircular,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // In back button handler
            ref.read(searchQueryProvider.notifier).set('');
            ref.read(activeSearchFilterProvider.notifier).set(SearchFilter.all);
            SearchFilter.all;
            context.pop();
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: theme.textTheme.titleMedium,
          decoration: const InputDecoration(
            hintText: 'Search tasks...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                HapticFeedback.lightImpact();
                _searchController.clear();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter pills row
          Container(
            height: 48.h,
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _buildFilterPill(SearchFilter.all, 'All'),
                _buildFilterPill(SearchFilter.today, 'Today'),
                _buildFilterPill(SearchFilter.thisWeek, 'This Week'),
                _buildFilterPill(SearchFilter.highPriority, 'High Priority'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Results list
          Expanded(
            child: searchResultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return _buildSearchEmptyState(theme);
                }

                return TaskListView(
                  tasks: tasks,
                  onToggle: (task) async {
                    final wasCompleted = task.isCompleted;
                    await ref
                        .read(tasksControllerProvider.notifier)
                        .toggleCompletion(task);
                    if (!wasCompleted && context.mounted) {
                      await ConfettiService.notifyTaskCompleted(context);
                    }
                  },
                  onDelete: (task) {
                    ref
                        .read(tasksControllerProvider.notifier)
                        .deleteTask(task.id);
                  },
                  onTap: (task) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => FractionallySizedBox(
                        heightFactor: 0.85,
                        child: TaskDetailScreen(task: task),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 72.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.15),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            SizedBox(height: AppSpacing.md),
            Text(
              'No Results Found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'No tasks matched your search or filters. Try adjusting your query or selecting another filter pill.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
