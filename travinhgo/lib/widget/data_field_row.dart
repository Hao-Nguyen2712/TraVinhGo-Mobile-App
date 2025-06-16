import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DataFieldRow extends StatelessWidget {
  final String title;
  final String? value;

  const DataFieldRow({super.key, required this.title, this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 225),
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
                  style: const TextStyle(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.grey.withOpacity(0.1),
          thickness: 0.4,
          height: 10,
        ),
      ],
    );
  }
}
