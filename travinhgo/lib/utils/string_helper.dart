class StringHelper {
  /// Viết hoa chữ cái đầu mỗi từ
  static String toTitleCase(String input) {
    if (input.trim().isEmpty) return '';

    return input
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  /// Xoá khoảng trắng dư thừa
  static String removeExtraSpaces(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Viết thường toàn bộ chuỗi và trim
  static String toLowerTrim(String input) {
    return input.trim().toLowerCase();
  }

  /// Chuẩn hoá tên: xoá khoảng trắng dư và viết hoa chữ cái đầu
  static String? normalizeName(String? input) {
    if (input == null) return null;
    return toTitleCase(removeExtraSpaces(input));
  }
}
