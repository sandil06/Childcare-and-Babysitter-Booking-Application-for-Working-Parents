class Helpers {
  static String initials(String name) => name
      .trim()
      .split(' ')
      .map((part) => part[0])
      .take(2)
      .join()
      .toUpperCase();
}
