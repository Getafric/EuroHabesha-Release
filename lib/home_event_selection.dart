/// Select upcoming events first. If none exist, show published older/undated
/// events under a different heading; never relabel an old event as upcoming.
class HomeEventSelection<T> {
  const HomeEventSelection(this.items, this.upcoming);
  final List<T> items;
  final bool upcoming;
}

HomeEventSelection<T> selectHomeEvents<T>(
  List<T> items,
  DateTime? Function(T) dateOf, {
  DateTime? now,
  int limit = 4,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final future = items.where((item) {
    final d = dateOf(item)?.toLocal();
    return d != null && !DateTime(d.year, d.month, d.day).isBefore(today);
  }).toList()..sort((a, b) => dateOf(a)!.compareTo(dateOf(b)!));
  if (future.isNotEmpty)
    return HomeEventSelection(future.take(limit).toList(), true);
  final all = [...items]
    ..sort((a, b) {
      final first = dateOf(a), second = dateOf(b);
      if (first == null) return second == null ? 0 : 1;
      if (second == null) return -1;
      return second.compareTo(first);
    });
  return HomeEventSelection(all.take(limit).toList(), false);
}
