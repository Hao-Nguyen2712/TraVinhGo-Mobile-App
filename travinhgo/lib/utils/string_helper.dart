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

  static String capitalizeFirstHtmlTextContent(String input) {
    if (!input.contains('<')) {
      // Plain text → viết hoa chữ đầu tiên
      return input.trimLeft().isNotEmpty
          ? input.trimLeft()[0].toUpperCase() + input.trimLeft().substring(1)
          : input;
    }

    // HTML content → viết hoa chữ đầu tiên giữa các thẻ
    final regex = RegExp(r'(?<=>)([^<])'); // ký tự đầu tiên sau '>'
    return input.replaceFirstMapped(regex, (match) {
      final char = match.group(1)!;
      return char.toUpperCase();
    });
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

  /// Định dạng ngày giờ: dd-MM-yyyy hh:mm (12 giờ)
  static String formatDateTime(String? dateTimeString) {
    try {
      if (dateTimeString == null) return "N/A";
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd-MM-yyyy hh:mm').format(dateTime);
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

  static String removeDiacritics(String str) {
    const withDiacritics =
        'áàảãạăắằẳẵặâấầẩẫậđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';

    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str;
  }
}
