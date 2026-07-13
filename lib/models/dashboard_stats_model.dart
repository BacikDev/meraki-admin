class DashboardStats {
  final int totalPatterns;
  final int totalCategories;
  final int totalUsers;
  final int totalFavorites;
  final int patternsThisMonth;

  const DashboardStats({
    this.totalPatterns = 0,
    this.totalCategories = 0,
    this.totalUsers = 0,
    this.totalFavorites = 0,
    this.patternsThisMonth = 0,
  });

  DashboardStats copyWith({
    int? totalPatterns,
    int? totalCategories,
    int? totalUsers,
    int? totalFavorites,
    int? patternsThisMonth,
  }) {
    return DashboardStats(
      totalPatterns: totalPatterns ?? this.totalPatterns,
      totalCategories: totalCategories ?? this.totalCategories,
      totalUsers: totalUsers ?? this.totalUsers,
      totalFavorites: totalFavorites ?? this.totalFavorites,
      patternsThisMonth:
          patternsThisMonth ?? this.patternsThisMonth,
    );
  }
}

class DashboardCategoryUsage {
  final int categoryId;
  final String categoryName;
  final int patternsCount;

  const DashboardCategoryUsage({
    required this.categoryId,
    required this.categoryName,
    required this.patternsCount,
  });
}

class DashboardMonthlyPoint {
  final DateTime month;
  final int patternsCount;

  const DashboardMonthlyPoint({
    required this.month,
    required this.patternsCount,
  });
}