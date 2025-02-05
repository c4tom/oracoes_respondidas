class BackupStats {
  final int totalPrayers;
  final int answeredPrayers;
  final int totalTags;
  final String timestamp;

  BackupStats({
    required this.totalPrayers,
    required this.answeredPrayers,
    required this.totalTags,
    required this.timestamp,
  });

  String get answeredPercentage {
    if (totalPrayers == 0) return '0%';
    return '${((answeredPrayers / totalPrayers) * 100).toStringAsFixed(1)}%';
  }
}
