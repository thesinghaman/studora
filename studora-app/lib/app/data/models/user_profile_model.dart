class UserProfileModel {
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String email;
  final String? rollNumber;
  final String? hostel;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? dateJoined;
  final bool isBlocked;
  final bool showReadReceipts;
  UserProfileModel({
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.email,
    this.rollNumber,
    this.hostel,
    required this.isOnline,
    this.lastSeen,
    this.dateJoined,
    required this.isBlocked,
    this.showReadReceipts = true,
  });
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'],
      userName: json['userName'],
      userAvatarUrl: json['userAvatarUrl'],
      email: json['email'],
      rollNumber: json['rollNumber'] == 'private' ? null : json['rollNumber'],
      hostel: json['hostel'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'])
          : null,
      dateJoined: json['dateJoined'] != null
          ? DateTime.tryParse(json['dateJoined'])
          : null,
      isBlocked: json['isBlocked'] ?? true,
      showReadReceipts: json['showReadReceipts'] ?? true,
    );
  }

  String getInitials() {
    if (userName.isEmpty) return "?";
    List<String> nameParts = userName.split(" ");
    if (nameParts.length > 1 &&
        nameParts.first.isNotEmpty &&
        nameParts.last.isNotEmpty) {
      return nameParts.first[0].toUpperCase() + nameParts.last[0].toUpperCase();
    } else if (nameParts.isNotEmpty && nameParts.first.isNotEmpty) {
      return nameParts.first[0].toUpperCase();
    }
    return "?";
  }
}
