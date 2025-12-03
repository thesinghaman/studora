import '../utils/validator.dart';
import '../utils/exceptions.dart';
import 'auth_dtos.dart';

class DeleteUnverifiedUserRequest extends RequestDto {
  final String userIdToDelete;
  final String jwt;

  DeleteUnverifiedUserRequest({
    required this.userIdToDelete,
    required this.jwt,
  });

  factory DeleteUnverifiedUserRequest.fromMap(Map<String, dynamic> map) {
    final userIdToDelete = map['userIdToDelete'];
    final jwt = map['jwt'];

    final userIdError = Validator.validateRequired(userIdToDelete, 'User ID to delete');
    if (userIdError != null) throw ValidationError(userIdError);

    final jwtError = Validator.validateRequired(jwt, 'JWT');
    if (jwtError != null) throw ValidationError(jwtError);

    return DeleteUnverifiedUserRequest(
      userIdToDelete: userIdToDelete,
      jwt: jwt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'userIdToDelete': userIdToDelete,
        'jwt': jwt,
      };

  @override
  void validate() {}
}

class DeleteUserAccountRequest extends RequestDto {
  final String userId;
  final String password;

  DeleteUserAccountRequest({
    required this.userId,
    required this.password,
  });

  factory DeleteUserAccountRequest.fromMap(Map<String, dynamic> map) {
    final userId = map['userId'];
    final password = map['password'];

    final userIdError = Validator.validateRequired(userId, 'User ID');
    if (userIdError != null) throw ValidationError(userIdError);

    final passwordError = Validator.validateRequired(password, 'Password');
    if (passwordError != null) throw ValidationError(passwordError);

    return DeleteUserAccountRequest(
      userId: userId,
      password: password,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'password': password,
      };

  @override
  void validate() {}
}

class GetUserProfileRequest extends RequestDto {
  final String targetUserId;

  GetUserProfileRequest({required this.targetUserId});

  factory GetUserProfileRequest.fromMap(Map<String, dynamic> map) {
    final targetUserId = map['targetUserId'];
    final error = Validator.validateRequired(targetUserId, 'Target User ID');
    if (error != null) throw ValidationError(error);

    return GetUserProfileRequest(targetUserId: targetUserId);
  }

  @override
  Map<String, dynamic> toJson() => {'targetUserId': targetUserId};

  @override
  void validate() {}
}
