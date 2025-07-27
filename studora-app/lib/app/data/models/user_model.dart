import 'dart:convert';
import 'package:studora/app/services/logger_service.dart';
class UserModel {
  final String userId;
  final String userName;
  final String email;
  final String? collegeId;
  final String? rollNumber;
  final String? hostel;
  final String? userAvatarUrl;
  final String? userAvatarFileId;
  final DateTime dateJoined;
  final String? fcmToken;
  final List<String>? wishlist;
  final List<String>? blockedUsers;
  final List<Map<String, dynamic>>? reportedContent;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? currencySymbol;
  final bool showLastSeen;
  final bool showReadReceipts;
  UserModel({
    required this.userId,
    required this.userName,
    required this.email,
    this.collegeId,
    this.rollNumber,
    this.hostel,
    this.userAvatarUrl,
    this.userAvatarFileId,
    required this.dateJoined,
    this.fcmToken,
    this.wishlist,
    this.blockedUsers,
    this.reportedContent,
    this.isOnline = false,
    this.lastSeen,
    this.currencySymbol,
    this.showLastSeen = true,
    this.showReadReceipts = true,
  });
  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    List<Map<String, dynamic>>? parsedReportedContent;
    if (json['reportedContent'] is String &&
        (json['reportedContent'] as String).isNotEmpty) {
      try {
        List<dynamic> decodedList = jsonDecode(
          json['reportedContent'] as String,
        );
        parsedReportedContent = List<Map<String, dynamic>>.from(
          decodedList.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      } catch (e) {
        LoggerService.logError("UserModel", "fromJson", e);
        parsedReportedContent = null;
      }
    } else if (json['reportedContent'] is List) {
      try {
        parsedReportedContent = List<Map<String, dynamic>>.from(
          (json['reportedContent'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
      } catch (e) {
        LoggerService.logError("UserModel", "fromJson", e);
        parsedReportedContent = null;
      }
    }
    return UserModel(
      userId: documentId,
      userName: json['userName'] as String? ?? 'Unknown User',
      email: json['email'] as String? ?? 'no-email@example.com',
      collegeId: json['collegeId'] as String?,
      rollNumber: json['rollNumber'] as String?,
      hostel: json['hostel'] as String?,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      userAvatarFileId: json['userAvatarFileId'] as String?,
      dateJoined: json['dateJoined'] != null
          ? DateTime.tryParse(json['dateJoined'] as String? ?? '') ??
                DateTime.now()
          : DateTime.now(),
      fcmToken: json['fcmToken'] as String?,
      wishlist: json['wishlist'] != null
          ? List<String>.from(json['wishlist'])
          : null,
      blockedUsers: json['blockedUsers'] != null
          ? List<String>.from(json['blockedUsers'])
          : null,
      reportedContent: parsedReportedContent,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String? ?? '')
          : null,
      currencySymbol: json['currencySymbol'] as String?,
      showLastSeen: json['showLastSeen'] ?? true,
      showReadReceipts: json['showReadReceipts'] ?? true,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'collegeId': collegeId,
      'rollNumber': rollNumber,
      'hostel': hostel,
      'userAvatarUrl': userAvatarUrl,
      'userAvatarFileId': userAvatarFileId,
      'dateJoined': dateJoined.toIso8601String(),
      'fcmToken': fcmToken,
      'wishlist': wishlist,
      'blockedUsers': blockedUsers,
      'reportedContent': reportedContent != null && reportedContent!.isNotEmpty
          ? jsonEncode(reportedContent)
          : null,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'currencySymbol': currencySymbol,
      'showLastSeen': showLastSeen,
      'showReadReceipts': showReadReceipts,
    };
  }
  String getInitials() {
    if (userName.isEmpty) return "?";
    List<String> nameParts = userName.split(" ");
    if (nameParts.length > 1 &&
        nameParts[0].isNotEmpty &&
        nameParts[1].isNotEmpty) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return "?";
  }
  UserModel copyWith({
    String? userId,
    String? userName,
    String? email,
    String? collegeId,
    String? rollNumber,
    String? hostel,
    String? userAvatarUrl,
    String? userAvatarFileId,
    DateTime? dateJoined,
    String? fcmToken,
    List<String>? wishlist,
    List<String>? blockedUsers,
    List<Map<String, dynamic>>? reportedContent,
    bool? isOnline,
    DateTime? lastSeen,
    bool? showLastSeen,
    bool? showReadReceipts,
    String? currencySymbol,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      collegeId: collegeId ?? this.collegeId,
      rollNumber: rollNumber ?? this.rollNumber,
      hostel: hostel ?? this.hostel,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      userAvatarFileId: userAvatarFileId ?? this.userAvatarFileId,
      dateJoined: dateJoined ?? this.dateJoined,
      fcmToken: fcmToken ?? this.fcmToken,
      wishlist: wishlist ?? this.wishlist,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      reportedContent: reportedContent ?? this.reportedContent,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'userName': userName,
      'rollNumber': rollNumber,
      'hostel': hostel,
      'userAvatarUrl': userAvatarUrl,
      'userAvatarFileId': userAvatarFileId,
    };
  }
}
