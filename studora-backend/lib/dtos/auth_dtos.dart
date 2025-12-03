import '../utils/validator.dart';
import '../utils/exceptions.dart';

abstract class RequestDto {
  Map<String, dynamic> toJson();
  void validate();
}

class InitiatePasswordResetRequest extends RequestDto {
  final String email;

  InitiatePasswordResetRequest({required this.email});

  factory InitiatePasswordResetRequest.fromMap(Map<String, dynamic> map) {
    final email = map['email'];
    final error = Validator.validateEmail(email);
    if (error != null) {
      throw ValidationError(error);
    }
    return InitiatePasswordResetRequest(email: email);
  }

  @override
  Map<String, dynamic> toJson() => {'email': email};

  @override
  void validate() {
    // Validation is done in factory
  }
}

class CompletePasswordResetRequest extends RequestDto {
  final String userId;
  final String secret;
  final String newPassword;

  CompletePasswordResetRequest({
    required this.userId,
    required this.secret,
    required this.newPassword,
  });

  factory CompletePasswordResetRequest.fromMap(Map<String, dynamic> map) {
    final userId = map['userId'];
    final secret = map['secret'];
    final newPassword = map['newPassword'];

    final userIdError = Validator.validateRequired(userId, 'User ID');
    if (userIdError != null) throw ValidationError(userIdError);

    final secretError = Validator.validateRequired(secret, 'Secret');
    if (secretError != null) throw ValidationError(secretError);

    final passwordError = Validator.validatePassword(newPassword);
    if (passwordError != null) throw ValidationError(passwordError);

    return CompletePasswordResetRequest(
      userId: userId,
      secret: secret,
      newPassword: newPassword,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'secret': secret,
        'newPassword': newPassword,
      };

  @override
  void validate() {}
}
