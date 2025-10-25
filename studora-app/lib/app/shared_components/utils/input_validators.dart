class InputValidators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    if (value.length < 3) {
      return 'Full name must be at least 3 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
      return 'Please enter a valid name';
    }
    return null;
  }

  static String? validateEmailPrefix(
    String? value, {
    bool isCollegeSelected = false,
  }) {
    if (!isCollegeSelected) {
      return 'Please select your college first';
    }
    if (value == null || value.isEmpty) {
      return 'Email prefix cannot be empty';
    }
    if (value.contains('@')) {
      return 'Enter only the part before @';
    }

    if (!RegExp(r"^[a-zA-Z0-9_.-]+$").hasMatch(value)) {
      return 'Invalid characters in email prefix';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  static String? validateSelection(dynamic value, String selectionName) {
    if (value == null) {
      return 'Please select $selectionName';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}
