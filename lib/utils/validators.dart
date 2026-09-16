// ==========================================================
// FORM VALIDATORS — Issue 18
// Reusable validation functions for all forms in the app.
// Use these inside TextFormField(validator: ...)
// ==========================================================
class Validators {
  // Full name — required, min 3 letters
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Naam likhna zaroori hai';
    }
    if (value.trim().length < 3) {
      return 'Naam kam se kam 3 letters ka ho';
    }
    return null;
  }

  // Email — required + basic email pattern check
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email likhna zaroori hai';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Sahi email daalein (example@mail.com)';
    }
    return null;
  }

  // Password — required, min 6 chars
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password likhna zaroori hai';
    }
    if (value.length < 6) {
      return 'Password kam se kam 6 characters ka ho';
    }
    return null;
  }

  // Phone — required, 10-13 digits, optional leading +
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number zaroori hai';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,13}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Sahi phone number daalein';
    }
    return null;
  }

  // City — required, min 2 letters
  static String? city(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City likhna zaroori hai';
    }
    return null;
  }

  // Generic required-field check (for any other text field)
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName zaroori hai';
    }
    return null;
  }

  // Min length check
  static String? minLength(String? value, int min, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName zaroori hai';
    }
    if (value.trim().length < min) {
      return '$fieldName kam se kam $min characters ka hona chahiye';
    }
    return null;
  }
}
