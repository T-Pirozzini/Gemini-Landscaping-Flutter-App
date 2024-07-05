class SiteReport {
  final String id;
  final String siteName;
  final int totalCombinedDuration;
  final String date;
  final bool filed;
  final List<String> employees;

  SiteReport({
    required this.id,
    required this.siteName,
    required this.totalCombinedDuration,
    required this.date,
    this.filed = false, // Add this field if needed in your provider
    required this.employees,
  });
}
