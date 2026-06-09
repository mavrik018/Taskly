import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SearchFilter {
  all,
  today,
  thisWeek,
  highPriority,
}

class SearchFilterNotifier extends Notifier<SearchFilter> {
  @override
  SearchFilter build() => SearchFilter.all;

  void set(SearchFilter filter) => state = filter;
}

final activeSearchFilterProvider =
    NotifierProvider<SearchFilterNotifier, SearchFilter>(
  SearchFilterNotifier.new,
);
