import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DataFieldRow extends StatelessWidget {
  final String title;
  final String? value;

  const DataFieldRow({super.key, required this.title, this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 15.sp,
                  color: isDarkMode ? Colors.white : Colors.black),
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 60.w),
              child: GestureDetector(
                onTap: () {
                  if (value != null && value!.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(title),
                        content: Text(value!),
                      ),
                    );
                  }
                },
                child: Text(
                  value ?? 'N/A',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: isDarkMode
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
