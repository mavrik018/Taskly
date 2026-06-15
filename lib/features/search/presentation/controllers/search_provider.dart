import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import 'filter_provider.dart';

// Provider holding the immediate raw text input
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// Provider providing the debounced query string (150ms delay)
class DebouncedSearchQueryNotifier extends Notifier<String> {
  @override
  String build() {
    final rawQuery = ref.watch(searchQueryProvider);

    final timer = Timer(const Duration(milliseconds: 150), () {
      state = rawQuery;
    });

    ref.onDispose(timer.cancel);

    return rawQuery;
  }
}

final debouncedSearchQueryProvider =
    NotifierProvider.autoDispose<DebouncedSearchQueryNotifier, String>(
  DebouncedSearchQueryNotifier.new,
);

// Combines tasks stream, debounced search query, and active filter pill
final searchResultsProvider =
    Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final query = ref.watch(debouncedSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(activeSearchFilterProvider);

  return tasksAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (tasks) {
      final filteredList = tasks.where((task) {
        // 1. Text Search Filter
        if (query.isNotEmpty) {
          final titleMatch = task.title.toLowerCase().contains(query);
          final descMatch =
              task.description?.toLowerCase().contains(query) ?? false;
          if (!titleMatch && !descMatch) return false;
        }

        // 2. Pill Category Filter
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart
            .add(const Duration(days: 1))
            .subtract(const Duration(microseconds: 1));

        switch (filter) {
          case SearchFilter.all:
            return true;
          case SearchFilter.today:
            if (task.dueDate == null) return false;
            final date = task.dueDate!;
            return date.isAfter(
                    todayStart.subtract(const Duration(microseconds: 1))) &&
                date.isBefore(todayEnd.add(const Duration(microseconds: 1)));
          case SearchFilter.thisWeek:
            if (task.dueDate == null) return false;
            final date = task.dueDate!;
            final weekEnd = todayStart.add(const Duration(days: 7));
            return date.isAfter(
                    todayStart.subtract(const Duration(microseconds: 1))) &&
                date.isBefore(weekEnd);
          case SearchFilter.highPriority:
            return task.priority == 1;
          case SearchFilter.completed:
            return task.isCompleted;
        }
      }).toList();

      return AsyncValue.data(filteredList);
    },
  );
});
