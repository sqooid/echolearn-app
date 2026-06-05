class FilterState {
  final String sort;
  final bool reshuffle;
  final String filter;
  final String query;
  final List<int>? shuffledIds;

  const FilterState({
    this.sort = 'newest',
    this.reshuffle = false,
    this.filter = 'active',
    this.query = '',
    this.shuffledIds,
  });

  FilterState copyWith({
    String? sort,
    bool? reshuffle,
    String? filter,
    String? query,
    List<int>? shuffledIds,
  }) {
    return FilterState(
      sort: sort ?? this.sort,
      reshuffle: reshuffle ?? this.reshuffle,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      shuffledIds: shuffledIds ?? this.shuffledIds,
    );
  }
}
