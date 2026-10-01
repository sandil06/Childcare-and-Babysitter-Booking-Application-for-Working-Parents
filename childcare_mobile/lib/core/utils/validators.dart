class Validators {
  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
}
