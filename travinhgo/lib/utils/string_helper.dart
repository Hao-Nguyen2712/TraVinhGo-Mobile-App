import 'package:intl/intl.dart';

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

  /// Viết in hoa toàn bộ chuỗi
  static String toUpperCase(String input) {
    return input.toUpperCase();
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

  static String formatDate(String? dateString) {
    try {
      if (dateString == null) return "N/A";
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return "N/A";
    }
  }

  /// Định dạng tiền VND
  static String formatCurrency(String? amount) {
    try {
      if (amount == null) return "Contact";
      final number = int.tryParse(amount);
      if (number == null) return "Contact";
      final formatter = NumberFormat('#,###', 'vi_VN');
      return formatter.format(number);
    } catch (e) {
      return "Liên hệ";
    }
  }
}
