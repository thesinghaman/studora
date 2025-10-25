import 'package:hive/hive.dart';

part 'enums.g.dart';

enum VerificationType { emailSignup, passwordChange }

enum ItemCondition { aNew, likeNew, excellent, good, fair, notApplicable }

enum LostFoundType { lost, found }

enum ReportType { user, item, lostFoundItem }

enum ReportStatus { pending, reviewed, resolved, dismissed, withdrawn }

@HiveType(typeId: 1)
enum MessageStatus {
  @HiveField(0)
  sending,
  @HiveField(1)
  sent,
  @HiveField(2)
  delivered,
  @HiveField(3)
  read,
  @HiveField(4)
  failed,
}

@HiveType(typeId: 2)
enum MessageType {
  @HiveField(0)
  text,
  @HiveField(1)
  image,
}

enum SortOption {
  dateDesc('Newest First', 'date_desc'),
  dateAsc('Oldest First', 'date_asc'),
  priceDesc('Price: High to Low', 'price_desc'),
  priceAsc('Price: Low to High', 'price_asc');

  const SortOption(this.label, this.value);
  final String label;
  final String value;
}
