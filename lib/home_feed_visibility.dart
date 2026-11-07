/// Filters only confirmed unavailable sources and exact duplicate references.
/// Distinct businesses with identical names must remain separate.
List<Map<String, dynamic>> visibleHomeFeed({
  required List<Map<String, dynamic>> items,
  required Set<String> unavailable,
  required Map<String, Map<String, dynamic>> profiles,
  required String? Function(Map<String, dynamic>) primaryPath,
  required String? Function(Map<String, dynamic>) originalPath,
}) {
  final seen = <String>{};
  return items.where((item) {
    if (item['homeHidden'] == true ||
        item['isDeleted'] == true ||
        item['status'] == 'deleted')
      return false;
    final primary = primaryPath(item);
    final original = originalPath(item);
    if ((primary != null && unavailable.contains(primary)) ||
        (original != null && unavailable.contains(original))) {
      return false;
    }
    final record = primary == null ? null : profiles[primary];
    final linkedOriginal = record == null ? null : originalPath(record);
    if (linkedOriginal != null && unavailable.contains(linkedOriginal)) {
      return false;
    }
    final key =
        linkedOriginal ?? original ?? primary ?? item['feedId']?.toString();
    return key == null || seen.add(key);
  }).toList();
}
